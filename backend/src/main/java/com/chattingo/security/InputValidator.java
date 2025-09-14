package com.chattingo.security;

import org.springframework.stereotype.Service;
import java.util.regex.Pattern;

@Service
public class InputValidator {
    
    // Email validation pattern
    private static final Pattern EMAIL_PATTERN = Pattern.compile(
        "^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$"
    );
    
    // Password requirements: min 8 chars, at least one letter, one number
    private static final Pattern PASSWORD_PATTERN = Pattern.compile(
        "^(?=.*[A-Za-z])(?=.*\\d)[A-Za-z\\d@$!%*#?&]{8,}$"
    );
    
    // XSS prevention patterns
    private static final Pattern[] XSS_PATTERNS = {
        Pattern.compile("<script[^>]*>.*?</script>", Pattern.CASE_INSENSITIVE),
        Pattern.compile("javascript:", Pattern.CASE_INSENSITIVE),
        Pattern.compile("vbscript:", Pattern.CASE_INSENSITIVE),
        Pattern.compile("onload", Pattern.CASE_INSENSITIVE),
        Pattern.compile("onerror", Pattern.CASE_INSENSITIVE),
        Pattern.compile("onclick", Pattern.CASE_INSENSITIVE),
        Pattern.compile("<iframe[^>]*>.*?</iframe>", Pattern.CASE_INSENSITIVE)
    };
    
    public boolean isValidEmail(String email) {
        if (email == null || email.trim().isEmpty()) {
            return false;
        }
        return EMAIL_PATTERN.matcher(email.trim()).matches();
    }
    
    public boolean isValidPassword(String password) {
        if (password == null) {
            return false;
        }
        return PASSWORD_PATTERN.matcher(password).matches();
    }
    
    public String sanitizeInput(String input) {
        if (input == null) {
            return null;
        }
        
        String sanitized = input.trim();
        
        // Remove potential XSS patterns
        for (Pattern pattern : XSS_PATTERNS) {
            sanitized = pattern.matcher(sanitized).replaceAll("");
        }
        
        // Escape HTML entities
        sanitized = sanitized.replace("&", "&amp;")
                           .replace("<", "&lt;")
                           .replace(">", "&gt;")
                           .replace("\"", "&quot;")
                           .replace("'", "&#x27;");
        
        return sanitized;
    }
    
    public boolean isValidMessageContent(String content) {
        if (content == null || content.trim().isEmpty()) {
            return false;
        }
        
        // Check length limits
        if (content.length() > 1000) {
            return false;
        }
        
        // Check for suspicious patterns
        for (Pattern pattern : XSS_PATTERNS) {
            if (pattern.matcher(content).find()) {
                return false;
            }
        }
        
        return true;
    }
    
    public boolean isValidUsername(String username) {
        if (username == null || username.trim().isEmpty()) {
            return false;
        }
        
        String trimmed = username.trim();
        
        // Username should be 3-30 characters, alphanumeric with underscores
        return trimmed.matches("^[a-zA-Z0-9_]{3,30}$");
    }
}
