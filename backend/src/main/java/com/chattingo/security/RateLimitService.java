package com.chattingo.security;

import org.springframework.stereotype.Service;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.atomic.AtomicInteger;
import java.time.LocalDateTime;
import java.time.temporal.ChronoUnit;

@Service
public class RateLimitService {
    
    private final ConcurrentHashMap<String, UserRateLimit> rateLimits = new ConcurrentHashMap<>();
    
    // Rate limits per minute
    private static final int NORMAL_ENDPOINT_LIMIT = 60;
    private static final int AUTH_ENDPOINT_LIMIT = 5;
    
    public boolean isAllowed(String clientId, boolean isAuthEndpoint) {
        String key = clientId + (isAuthEndpoint ? "_auth" : "_normal");
        int limit = isAuthEndpoint ? AUTH_ENDPOINT_LIMIT : NORMAL_ENDPOINT_LIMIT;
        
        UserRateLimit userLimit = rateLimits.computeIfAbsent(key, 
            k -> new UserRateLimit());
        
        return userLimit.isAllowed(limit);
    }
    
    public void resetLimits() {
        rateLimits.clear();
    }
    
    private static class UserRateLimit {
        private AtomicInteger requestCount = new AtomicInteger(0);
        private LocalDateTime windowStart = LocalDateTime.now();
        
        public synchronized boolean isAllowed(int limit) {
            LocalDateTime now = LocalDateTime.now();
            
            // Reset window if more than 1 minute has passed
            if (ChronoUnit.MINUTES.between(windowStart, now) >= 1) {
                requestCount.set(0);
                windowStart = now;
            }
            
            if (requestCount.get() < limit) {
                requestCount.incrementAndGet();
                return true;
            }
            
            return false;
        }
    }
}
