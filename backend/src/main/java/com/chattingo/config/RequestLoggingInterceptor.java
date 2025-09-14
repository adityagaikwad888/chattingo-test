package com.chattingo.config;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Component;
import org.springframework.web.servlet.HandlerInterceptor;

import com.chattingo.util.LoggingUtil;

import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

/**
 * Interceptor for logging all HTTP requests and responses
 * Provides comprehensive API monitoring and performance tracking
 */
@Component
public class RequestLoggingInterceptor implements HandlerInterceptor {

    private static final Logger logger = LoggerFactory.getLogger(RequestLoggingInterceptor.class);
    private static final String START_TIME_ATTRIBUTE = "request_start_time";
    private static final String CORRELATION_ID_HEADER = "X-Correlation-ID";

    @Override
    public boolean preHandle(HttpServletRequest request, HttpServletResponse response, Object handler) throws Exception {
        // Record start time for performance monitoring
        long startTime = System.currentTimeMillis();
        request.setAttribute(START_TIME_ATTRIBUTE, startTime);

        // Generate or use existing correlation ID
        String correlationId = request.getHeader(CORRELATION_ID_HEADER);
        if (correlationId == null || correlationId.isEmpty()) {
            correlationId = LoggingUtil.generateCorrelationId();
        }
        LoggingUtil.setCorrelationId(correlationId);
        
        // Set correlation ID in response header
        response.setHeader(CORRELATION_ID_HEADER, correlationId);

        // Set request context
        String requestId = LoggingUtil.generateCorrelationId();
        LoggingUtil.setRequestContext(requestId);

        // Extract client information
        String clientIp = getClientIpAddress(request);
        String userAgent = request.getHeader("User-Agent");
        String method = request.getMethod();
        String uri = request.getRequestURI();
        String queryString = request.getQueryString();

        // Log request details
        logger.info("Incoming request - Method: {}, URI: {}, Query: {}, IP: {}, User-Agent: {}", 
            method, uri, queryString != null ? queryString : "", clientIp, userAgent);

        // Log headers for auth and debugging (exclude sensitive headers)
        if (logger.isDebugEnabled()) {
            String authHeader = request.getHeader("Authorization");
            if (authHeader != null) {
                logger.debug("Request has Authorization header: {}", 
                    authHeader.startsWith("Bearer ") ? "Bearer [REDACTED]" : "[REDACTED]");
            }
            
            String contentType = request.getHeader("Content-Type");
            if (contentType != null) {
                logger.debug("Request Content-Type: {}", contentType);
            }
        }

        return true;
    }

    @Override
    public void afterCompletion(HttpServletRequest request, HttpServletResponse response, 
                              Object handler, Exception ex) throws Exception {
        try {
            // Calculate processing time
            Long startTime = (Long) request.getAttribute(START_TIME_ATTRIBUTE);
            long processingTime = startTime != null ? System.currentTimeMillis() - startTime : 0;

            // Extract request information
            String method = request.getMethod();
            String uri = request.getRequestURI();
            int statusCode = response.getStatus();
            String clientIp = getClientIpAddress(request);
            String userAgent = request.getHeader("User-Agent");

            // Log the API event
            LoggingUtil.logApiEvent(logger, method, uri, statusCode, processingTime, clientIp, userAgent);

            // Log completion details
            if (statusCode >= 500) {
                logger.error("Request completed with server error - Method: {}, URI: {}, Status: {}, Time: {}ms", 
                    method, uri, statusCode, processingTime);
            } else if (statusCode >= 400) {
                logger.warn("Request completed with client error - Method: {}, URI: {}, Status: {}, Time: {}ms", 
                    method, uri, statusCode, processingTime);
            } else {
                logger.info("Request completed successfully - Method: {}, URI: {}, Status: {}, Time: {}ms", 
                    method, uri, statusCode, processingTime);
            }

            // Log performance metrics
            if (processingTime > 5000) { // More than 5 seconds
                LoggingUtil.logMetrics(logger, "slow_request", processingTime, 
                    java.util.Map.of("method", method, "uri", uri, "status", statusCode));
                logger.warn("Slow request detected - {}ms for {} {}", processingTime, method, uri);
            }

            // Log exception if present
            if (ex != null) {
                LoggingUtil.logError(logger, "REQUEST_EXCEPTION", ex, 
                    java.util.Map.of("method", method, "uri", uri, "clientIp", clientIp));
            }

        } finally {
            // Clean up MDC context
            LoggingUtil.clearContext();
        }
    }

    /**
     * Extract the real client IP address from the request
     */
    private String getClientIpAddress(HttpServletRequest request) {
        String xForwardedFor = request.getHeader("X-Forwarded-For");
        if (xForwardedFor != null && !xForwardedFor.isEmpty()) {
            // X-Forwarded-For can contain multiple IPs, the first one is the original client
            return xForwardedFor.split(",")[0].trim();
        }
        
        String xRealIp = request.getHeader("X-Real-IP");
        if (xRealIp != null && !xRealIp.isEmpty()) {
            return xRealIp;
        }
        
        String xForwarded = request.getHeader("X-Forwarded");
        if (xForwarded != null && !xForwarded.isEmpty()) {
            return xForwarded;
        }
        
        String forwarded = request.getHeader("Forwarded");
        if (forwarded != null && !forwarded.isEmpty()) {
            return forwarded;
        }
        
        return request.getRemoteAddr();
    }
}
