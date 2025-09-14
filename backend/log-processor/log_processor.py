#!/usr/bin/env python3

import os
import time
import gzip
import shutil
import logging
from datetime import datetime, timedelta
from pathlib import Path
import schedule

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

class LogProcessor:
    def __init__(self):
        self.log_path = os.getenv('LOG_PATH', '/var/log/chattingo')
        self.max_age_days = int(os.getenv('MAX_AGE_DAYS', '3'))
        self.max_size_mb = int(os.getenv('MAX_SIZE_MB', '50'))
        
        logger.info(f"LogProcessor initialized - Path: {self.log_path}, Max age: {self.max_age_days} days, Max size: {self.max_size_mb}MB")

    def should_rotate_file(self, file_path):
        """Check if file should be rotated based on size or age"""
        try:
            stat = file_path.stat()
            
            # Check file size
            size_mb = stat.st_size / (1024 * 1024)
            if size_mb > self.max_size_mb:
                logger.info(f"File {file_path.name} exceeds size limit: {size_mb:.2f}MB")
                return True
            
            # Check file age
            age_days = (time.time() - stat.st_mtime) / (24 * 3600)
            if age_days > self.max_age_days:
                logger.info(f"File {file_path.name} exceeds age limit: {age_days:.2f} days")
                return True
            
            return False
        except Exception as e:
            logger.error(f"Error checking file {file_path}: {e}")
            return False

    def compress_file(self, source_path):
        """Compress log file using gzip"""
        compressed_path = source_path.with_suffix(source_path.suffix + '.gz')
        
        try:
            with open(source_path, 'rb') as f_in:
                with gzip.open(compressed_path, 'wb') as f_out:
                    shutil.copyfileobj(f_in, f_out)
            
            # Remove original file
            source_path.unlink()
            logger.info(f"Compressed: {source_path.name} -> {compressed_path.name}")
            return compressed_path
        except Exception as e:
            logger.error(f"Error compressing {source_path}: {e}")
            return None



    def process_category(self, category):
        """Process log files for a specific category"""
        category_path = Path(self.log_path) / category
        
        if not category_path.exists():
            logger.debug(f"Category directory does not exist: {category_path}")
            return

        # Process .log files
        for log_file in category_path.glob('*.log'):
            if self.should_rotate_file(log_file):
                # Create timestamped filename
                timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
                rotated_name = f"{log_file.stem}_{timestamp}.log"
                rotated_path = category_path / rotated_name
                
                # Rename file
                log_file.rename(rotated_path)
                logger.info(f"Rotated: {log_file.name} -> {rotated_name}")
                
                # Compress file (keep locally, no S3 upload)
                compressed_path = self.compress_file(rotated_path)
                if compressed_path:
                    logger.info(f"Log compressed and stored locally: {compressed_path}")
                else:
                    logger.warning(f"Failed to compress rotated file: {rotated_path}")

    def cleanup_old_files(self):
        """Clean up old log files (aggressive cleanup since no S3 backup)"""
        logger.info(f"Starting cleanup of log files older than {self.max_age_days} days")
        cutoff_time = time.time() - (self.max_age_days * 24 * 3600)
        deleted_count = 0
        
        log_base_path = Path(self.log_path)
        if not log_base_path.exists():
            logger.warning(f"Log directory does not exist: {log_base_path}")
            return

        for file_path in log_base_path.rglob('*'):
            if file_path.is_file() and file_path.suffix in ['.log', '.gz']:
                try:
                    if file_path.stat().st_mtime < cutoff_time:
                        file_path.unlink()
                        deleted_count += 1
                        logger.info(f"Deleted old file: {file_path}")
                except Exception as e:
                    logger.warning(f"Failed to delete {file_path}: {e}")
        
        logger.info(f"Cleanup completed - deleted {deleted_count} old log files")

    def process_all_logs(self):
        """Process logs for all categories"""
        logger.info("Starting log processing cycle")
        
        categories = ['app', 'auth', 'chat', 'error', 'system', 'websocket']
        
        for category in categories:
            try:
                self.process_category(category)
            except Exception as e:
                logger.error(f"Error processing category {category}: {e}")
        
        logger.info("Log processing cycle completed")

def main():
    logger.info("Starting Chattingo Log Processor (Simplified - Local storage only)")
    
    processor = LogProcessor()
    
    # Schedule log processing every hour
    schedule.every().hour.do(processor.process_all_logs)
    
    # Schedule cleanup every day at 2 AM (more aggressive cleanup since no S3 backup)
    schedule.every().day.at("02:00").do(processor.cleanup_old_files)
    
    # Run initial processing
    processor.process_all_logs()
    
    logger.info("Log processor started successfully - no S3 uploads, local compression and cleanup only")
    
    # Keep the script running
    while True:
        schedule.run_pending()
        time.sleep(60)  # Check every minute

if __name__ == "__main__":
    main()
