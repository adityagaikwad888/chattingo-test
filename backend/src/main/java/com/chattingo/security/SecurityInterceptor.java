package com.chattingo.security;

import org.springframework.stereotype.Component;
import org.springframework.web.servlet.HandlerInterceptor;

import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

@Component
public class SecurityInterceptor implements HandlerInterceptor {
    
    @Override
    public boolean preHandle(HttpServletRequest request, HttpServletResponse response, Object handler) throws Exception {
        
        // Add basic security headers
        addSecurityHeaders(response);
        
        return true;
    }
    
    private void addSecurityHeaders(HttpServletResponse response) {
        // Prevent XSS attacks
        response.setHeader("X-XSS-Protection", "1; mode=block");
        
        // Prevent MIME type sniffing
        response.setHeader("X-Content-Type-Options", "nosniff");
        
        // Prevent clickjacking
        response.setHeader("X-Frame-Options", "DENY");
        
        // Remove server information
        response.setHeader("Server", "Chattingo");
    }
}
