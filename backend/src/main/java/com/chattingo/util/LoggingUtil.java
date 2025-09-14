package com.chattingo.util;

import com.fasterxml.jackson.databind.ObjectMapper;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.slf4j.MDC;
import org.springframework.stereotype.Component;

import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.HashMap;
import java.util.Map;
import java.util.UUID;

/**
 * Utility class for structured logging with correlation IDs and contextual information
 * Provides production-level logging capabilities for the Chattingo application
 */
@Component
public class LoggingUtil {
    
    private static final Logger log = LoggerFactory.getLogger(LoggingUtil.class);
    private static final ObjectMapper objectMapper = new ObjectMapper();
    private static final String CORRELATION_ID_KEY = "correlationId";
    private static final String USER_ID_KEY = "userId";
    private static final String SESSION_ID_KEY = "sessionId";
    private static final String REQUEST_ID_KEY = "requestId";
    private static final String CHAT_ID_KEY = "chatId";
    private static final String MESSAGE_ID_KEY = "messageId";
    
    /**
     * Generate a new correlation ID for request tracking
     */
    public static String generateCorrelationId() {
        return UUID.randomUUID().toString();
    }
    
    /**
     * Set correlation ID in MDC for request tracking
     */
    public static void setCorrelationId(String correlationId) {
        MDC.put(CORRELATION_ID_KEY, correlationId);
    }
    
    /**
     * Get current correlation ID from MDC
     */
    public static String getCorrelationId() {
        return MDC.get(CORRELATION_ID_KEY);
    }
    
    /**
     * Set user context in MDC
     */
    public static void setUserContext(Integer userId) {
        if (userId != null) {
            MDC.put(USER_ID_KEY, userId.toString());
        }
    }
    
    /**
     * Set session context in MDC
     */
    public static void setSessionContext(String sessionId) {
        if (sessionId != null) {
            MDC.put(SESSION_ID_KEY, sessionId);
        }
    }
    
    /**
     * Set request context in MDC
     */
    public static void setRequestContext(String requestId) {
        if (requestId != null) {
            MDC.put(REQUEST_ID_KEY, requestId);
        }
    }
    
    /**
     * Set chat context in MDC
     */
    public static void setChatContext(Integer chatId) {
        if (chatId != null) {
            MDC.put(CHAT_ID_KEY, chatId.toString());
        }
    }
    
    /**
     * Set message context in MDC
     */
    public static void setMessageContext(Integer messageId) {
        if (messageId != null) {
            MDC.put(MESSAGE_ID_KEY, messageId.toString());
        }
    }
    
    /**
     * Clear all MDC context
     */
    public static void clearContext() {
        MDC.clear();
    }
    
    /**
     * Clear specific MDC key
     */
    public static void clearContext(String key) {
        MDC.remove(key);
    }
    
    /**
     * Log authentication events
     */
    public static void logAuthEvent(Logger logger, String event, String email, boolean success, String details) {
        Map<String, Object> logData = new HashMap<>();
        logData.put("event", event);
        logData.put("email", email);
        logData.put("success", success);
        logData.put("timestamp", LocalDateTime.now().format(DateTimeFormatter.ISO_LOCAL_DATE_TIME));
        logData.put("details", details);
        
        if (success) {
            logger.info("AUTH_EVENT: {}", toJson(logData));
        } else {
            logger.warn("AUTH_FAILED: {}", toJson(logData));
        }
    }
    
    /**
     * Log chat events
     */
    public static void logChatEvent(Logger logger, String event, Integer chatId, Integer userId, String details) {
        Map<String, Object> logData = new HashMap<>();
        logData.put("event", event);
        logData.put("chatId", chatId);
        logData.put("userId", userId);
        logData.put("timestamp", LocalDateTime.now().format(DateTimeFormatter.ISO_LOCAL_DATE_TIME));
        logData.put("details", details);
        
        logger.info("CHAT_EVENT: {}", toJson(logData));
    }
    
    /**
     * Log message events
     */
    public static void logMessageEvent(Logger logger, String event, Integer messageId, Integer chatId, 
                                     Integer senderId, String messageType, String details) {
        Map<String, Object> logData = new HashMap<>();
        logData.put("event", event);
        logData.put("messageId", messageId);
        logData.put("chatId", chatId);
        logData.put("senderId", senderId);
        logData.put("messageType", messageType);
        logData.put("timestamp", LocalDateTime.now().format(DateTimeFormatter.ISO_LOCAL_DATE_TIME));
        logData.put("details", details);
        
        logger.info("MESSAGE_EVENT: {}", toJson(logData));
    }
    
    /**
     * Log WebSocket events
     */
    public static void logWebSocketEvent(Logger logger, String event, String sessionId, Integer userId, String details) {
        Map<String, Object> logData = new HashMap<>();
        logData.put("event", event);
        logData.put("sessionId", sessionId);
        logData.put("userId", userId);
        logData.put("timestamp", LocalDateTime.now().format(DateTimeFormatter.ISO_LOCAL_DATE_TIME));
        logData.put("details", details);
        
        logger.info("WEBSOCKET_EVENT: {}", toJson(logData));
    }
    
    /**
     * Log API request/response
     */
    public static void logApiEvent(Logger logger, String method, String uri, int statusCode, 
                                 long processingTime, String clientIp, String userAgent) {
        Map<String, Object> logData = new HashMap<>();
        logData.put("method", method);
        logData.put("uri", uri);
        logData.put("statusCode", statusCode);
        logData.put("processingTimeMs", processingTime);
        logData.put("clientIp", clientIp);
        logData.put("userAgent", userAgent);
        logData.put("timestamp", LocalDateTime.now().format(DateTimeFormatter.ISO_LOCAL_DATE_TIME));
        
        if (statusCode >= 400) {
            logger.warn("API_REQUEST: {}", toJson(logData));
        } else {
            logger.info("API_REQUEST: {}", toJson(logData));
        }
    }
    
    /**
     * Log security events
     */
    public static void logSecurityEvent(Logger logger, String event, String source, String details, String severity) {
        Map<String, Object> logData = new HashMap<>();
        logData.put("event", event);
        logData.put("source", source);
        logData.put("details", details);
        logData.put("severity", severity);
        logData.put("timestamp", LocalDateTime.now().format(DateTimeFormatter.ISO_LOCAL_DATE_TIME));
        
        switch (severity.toUpperCase()) {
            case "HIGH":
                logger.error("SECURITY_EVENT: {}", toJson(logData));
                break;
            case "MEDIUM":
                logger.warn("SECURITY_EVENT: {}", toJson(logData));
                break;
            default:
                logger.info("SECURITY_EVENT: {}", toJson(logData));
        }
    }
    
    /**
     * Log database events
     */
    public static void logDatabaseEvent(Logger logger, String operation, String entity, String details, long executionTime) {
        Map<String, Object> logData = new HashMap<>();
        logData.put("operation", operation);
        logData.put("entity", entity);
        logData.put("details", details);
        logData.put("executionTimeMs", executionTime);
        logData.put("timestamp", LocalDateTime.now().format(DateTimeFormatter.ISO_LOCAL_DATE_TIME));
        
        logger.debug("DB_EVENT: {}", toJson(logData));
    }
    
    /**
     * Log business metrics
     */
    public static void logMetrics(Logger logger, String metric, Object value, Map<String, Object> tags) {
        Map<String, Object> logData = new HashMap<>();
        logData.put("metric", metric);
        logData.put("value", value);
        logData.put("tags", tags);
        logData.put("timestamp", LocalDateTime.now().format(DateTimeFormatter.ISO_LOCAL_DATE_TIME));
        
        logger.info("METRIC: {}", toJson(logData));
    }
    
    /**
     * Log errors with stack trace
     */
    public static void logError(Logger logger, String operation, Exception e, Map<String, Object> context) {
        Map<String, Object> logData = new HashMap<>();
        logData.put("operation", operation);
        logData.put("errorType", e.getClass().getSimpleName());
        logData.put("errorMessage", e.getMessage());
        logData.put("context", context);
        logData.put("timestamp", LocalDateTime.now().format(DateTimeFormatter.ISO_LOCAL_DATE_TIME));
        
        logger.error("ERROR: {}", toJson(logData), e);
    }
    
    /**
     * Convert object to JSON string for logging
     */
    private static String toJson(Object obj) {
        try {
            return objectMapper.writeValueAsString(obj);
        } catch (Exception e) {
            log.warn("Failed to convert object to JSON: {}", e.getMessage());
            return obj.toString();
        }
    }
    
    /**
     * Create a structured log entry builder
     */
    public static LogEntryBuilder builder() {
        return new LogEntryBuilder();
    }
    
    /**
     * Builder class for creating structured log entries
     */
    public static class LogEntryBuilder {
        private final Map<String, Object> data = new HashMap<>();
        
        public LogEntryBuilder event(String event) {
            data.put("event", event);
            return this;
        }
        
        public LogEntryBuilder userId(Integer userId) {
            data.put("userId", userId);
            return this;
        }
        
        public LogEntryBuilder chatId(Integer chatId) {
            data.put("chatId", chatId);
            return this;
        }
        
        public LogEntryBuilder messageId(Integer messageId) {
            data.put("messageId", messageId);
            return this;
        }
        
        public LogEntryBuilder sessionId(String sessionId) {
            data.put("sessionId", sessionId);
            return this;
        }
        
        public LogEntryBuilder detail(String key, Object value) {
            data.put(key, value);
            return this;
        }
        
        public LogEntryBuilder details(Map<String, Object> details) {
            data.putAll(details);
            return this;
        }
        
        public void info(Logger logger) {
            data.put("timestamp", LocalDateTime.now().format(DateTimeFormatter.ISO_LOCAL_DATE_TIME));
            logger.info(toJson(data));
        }
        
        public void warn(Logger logger) {
            data.put("timestamp", LocalDateTime.now().format(DateTimeFormatter.ISO_LOCAL_DATE_TIME));
            logger.warn(toJson(data));
        }
        
        public void error(Logger logger) {
            data.put("timestamp", LocalDateTime.now().format(DateTimeFormatter.ISO_LOCAL_DATE_TIME));
            logger.error(toJson(data));
        }
        
        public void debug(Logger logger) {
            data.put("timestamp", LocalDateTime.now().format(DateTimeFormatter.ISO_LOCAL_DATE_TIME));
            logger.debug(toJson(data));
        }
    }
}
