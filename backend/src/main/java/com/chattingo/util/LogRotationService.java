package com.chattingo.util;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;


import java.io.File;
import java.io.IOException;
import java.nio.file.*;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.stream.Stream;
import java.util.zip.GZIPOutputStream;
import java.io.FileOutputStream;
import java.io.FileInputStream;

/**
 * Service for rotating and managing log files locally
 * Container-friendly approach: no S3 dependencies (S3 upload handled by host service)
 * Designed for Kubernetes deployment where S3 upload runs on host
 */
@Component
public class LogRotationService {

    private static final Logger logger = LoggerFactory.getLogger(LogRotationService.class);

    @Value("${log.rotation.enabled:true}")
    private boolean rotationEnabled;

    @Value("${log.rotation.max-age-days:7}")
    private int maxAgeDays;

    @Value("${log.rotation.max-size-mb:100}")
    private int maxSizeMb;

    @Value("${log.path:./logs}")
    private String logPath;

    /**
     * Scheduled log rotation - runs every hour
     */
    @Scheduled(fixedRate = 3600000) // 1 hour
    public void rotateAndUploadLogs() {
        if (!rotationEnabled) {
            logger.debug("Log rotation is disabled");
            return;
        }

        logger.info("Starting log rotation and upload process");

        try {
            // Process each log category
            String[] categories = {"app", "auth", "chat", "error", "system", "websocket"};
            
            for (String category : categories) {
                processLogCategory(category);
            }

            logger.info("Log rotation and upload process completed successfully");

        } catch (Exception e) {
            logger.error("Error during log rotation and upload: {}", e.getMessage(), e);
        }
    }

    private void processLogCategory(String category) {
        try {
            Path categoryPath = Paths.get(logPath, category);
            if (!Files.exists(categoryPath)) {
                logger.debug("Log category directory does not exist: {}", categoryPath);
                return;
            }

            try (Stream<Path> files = Files.list(categoryPath)) {
                files.filter(Files::isRegularFile)
                     .filter(file -> file.toString().endsWith(".log"))
                     .forEach(file -> processLogFile(file, category));
            }

        } catch (IOException e) {
            logger.error("Error processing log category {}: {}", category, e.getMessage(), e);
        }
    }

    private void processLogFile(Path logFile, String category) {
        try {
            File file = logFile.toFile();
            
            // Check if file needs rotation based on size or age
            if (shouldRotateFile(file)) {
                rotateLogFile(logFile, category);
            }

        } catch (Exception e) {
            logger.error("Error processing log file {}: {}", logFile, e.getMessage(), e);
        }
    }

    private boolean shouldRotateFile(File file) {
        // Check file size
        long fileSizeMb = file.length() / (1024 * 1024);
        if (fileSizeMb > maxSizeMb) {
            logger.debug("File {} exceeds size limit: {}MB > {}MB", 
                file.getName(), fileSizeMb, maxSizeMb);
            return true;
        }

        // Check file age
        long fileAgeMs = System.currentTimeMillis() - file.lastModified();
        long maxAgeMs = maxAgeDays * 24 * 60 * 60 * 1000L;
        if (fileAgeMs > maxAgeMs) {
            logger.debug("File {} exceeds age limit: {} days", 
                file.getName(), fileAgeMs / (24 * 60 * 60 * 1000L));
            return true;
        }

        return false;
    }

    private void rotateLogFile(Path logFile, String category) {
        try {
            // Create timestamped filename
            String timestamp = LocalDateTime.now().format(DateTimeFormatter.ofPattern("yyyy-MM-dd_HH-mm-ss"));
            String rotatedFileName = logFile.getFileName().toString().replace(".log", "_" + timestamp + ".log");
            Path rotatedFile = logFile.getParent().resolve(rotatedFileName);

            // Move current log file
            Files.move(logFile, rotatedFile);
            logger.info("Log file rotated: {} -> {}", logFile.getFileName(), rotatedFileName);

            // Compress the rotated file (keep for host-based S3 upload service)
            Path compressedFile = compressLogFile(rotatedFile);
            logger.info("Log file compressed for host S3 upload service: {}", compressedFile);
            
            // Log the rotation event
            LoggingUtil.logMetrics(logger, "log_rotation_success", 1, 
                java.util.Map.of("category", category, "file", rotatedFileName));

        } catch (Exception e) {
            logger.error("Error rotating log file {}: {}", logFile, e.getMessage(), e);
            
            // Log the rotation failure
            LoggingUtil.logMetrics(logger, "log_rotation_failure", 1, 
                java.util.Map.of("category", category, "file", logFile.getFileName().toString(), 
                              "error", e.getMessage()));
        }
    }

    private Path compressLogFile(Path logFile) throws IOException {
        Path compressedFile = Paths.get(logFile.toString() + ".gz");
        
        try (FileInputStream fis = new FileInputStream(logFile.toFile());
             FileOutputStream fos = new FileOutputStream(compressedFile.toFile());
             GZIPOutputStream gos = new GZIPOutputStream(fos)) {
            
            byte[] buffer = new byte[8192];
            int length;
            while ((length = fis.read(buffer)) > 0) {
                gos.write(buffer, 0, length);
            }
        }

        // Delete original file after compression
        Files.deleteIfExists(logFile);
        
        logger.debug("Log file compressed: {} -> {}", logFile.getFileName(), compressedFile.getFileName());
        return compressedFile;
    }



    /**
     * Manual cleanup of old log files
     * Simplified approach: delete old files directly without S3 transfer
     */
    @Scheduled(fixedRate = 86400000) // 24 hours
    public void cleanupOldLogs() {
        logger.info("Starting cleanup of old log files (simple deletion approach)");

        try {
            Path logsPath = Paths.get(logPath);
            if (!Files.exists(logsPath)) {
                return;
            }

            long cutoffTime = System.currentTimeMillis() - (maxAgeDays * 24 * 60 * 60 * 1000L);
            int deletedCount = 0;

            try (Stream<Path> paths = Files.walk(logsPath)) {
                deletedCount = (int) paths
                    .filter(Files::isRegularFile)
                    .filter(file -> file.toString().endsWith(".log") || file.toString().endsWith(".log.gz"))
                    .filter(file -> file.toFile().lastModified() < cutoffTime)
                    .mapToInt(file -> {
                        deleteOldLogFile(file);
                        return 1;
                    })
                    .sum();
            }

            logger.info("Cleanup completed - deleted {} old log files", deletedCount);
            
            // Log cleanup metrics
            LoggingUtil.logMetrics(logger, "log_cleanup_completed", 1, 
                java.util.Map.of("deleted_files", String.valueOf(deletedCount)));

        } catch (Exception e) {
            logger.error("Error during log cleanup: {}", e.getMessage(), e);
        }
    }



    private void deleteOldLogFile(Path file) {
        try {
            Files.deleteIfExists(file);
            logger.debug("Deleted old log file: {}", file);
        } catch (IOException e) {
            logger.warn("Failed to delete old log file {}: {}", file, e.getMessage());
        }
    }
}
