package com.chattingo.config;

import java.io.IOException;
import java.util.List;

import javax.crypto.SecretKey;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.security.authentication.BadCredentialsException;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.GrantedAuthority;
import org.springframework.security.core.authority.AuthorityUtils;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

import com.chattingo.util.LoggingUtil;

import io.jsonwebtoken.Claims;
import io.jsonwebtoken.ExpiredJwtException;
import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.MalformedJwtException;
import io.jsonwebtoken.UnsupportedJwtException;
import io.jsonwebtoken.security.Keys;
import io.jsonwebtoken.security.SecurityException;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

@Component
public class JwtValidator extends OncePerRequestFilter {

    private static final Logger logger = LoggerFactory.getLogger(JwtValidator.class);
    private final SecretKey key;

    public JwtValidator(@Value("${jwt.secret}") String jwtSecret) {
        this.key = Keys.hmacShaKeyFor(jwtSecret.getBytes());
    }

    @SuppressWarnings("null")
    @Override
    protected void doFilterInternal(HttpServletRequest request, HttpServletResponse response, FilterChain filterChain)
            throws ServletException, IOException {

        String jwt = request.getHeader("Authorization");
        String requestUri = request.getRequestURI();
        String clientIp = getClientIpAddress(request);

        if (jwt != null) {
            try {
                // Extract JWT token (remove "Bearer " prefix)
                jwt = jwt.substring(7);

                // Parse and validate JWT
                Claims claim = Jwts.parserBuilder().setSigningKey(key).build().parseClaimsJws(jwt).getBody();

                String username = String.valueOf(claim.get("email"));
                String authorities = String.valueOf(claim.get("authorities"));

                // Log successful JWT validation
                logger.debug("JWT validation successful for user: {} accessing: {}", username, requestUri);
                
                LoggingUtil.logSecurityEvent(logger, "JWT_VALIDATION_SUCCESS", clientIp,
                    "JWT validated successfully for user: " + username + " accessing: " + requestUri, "LOW");

                List<GrantedAuthority> auths = AuthorityUtils.commaSeparatedStringToAuthorityList(authorities);
                Authentication authentication = new UsernamePasswordAuthenticationToken(username, null, auths);
                SecurityContextHolder.getContext().setAuthentication(authentication);

                // Set user context for logging if we can extract user ID from claims
                Object userIdClaim = claim.get("userId");
                if (userIdClaim != null) {
                    try {
                        Integer userId = Integer.valueOf(userIdClaim.toString());
                        LoggingUtil.setUserContext(userId);
                    } catch (NumberFormatException e) {
                        logger.debug("Could not parse userId from JWT claims: {}", userIdClaim);
                    }
                }

            } catch (ExpiredJwtException e) {
                logger.warn("Expired JWT token for request: {} from IP: {}", requestUri, clientIp);
                LoggingUtil.logSecurityEvent(logger, "JWT_EXPIRED", clientIp,
                    "Expired JWT token used for: " + requestUri, "MEDIUM");
                throw new BadCredentialsException("JWT token has expired");
                
            } catch (MalformedJwtException e) {
                logger.warn("Malformed JWT token for request: {} from IP: {}", requestUri, clientIp);
                LoggingUtil.logSecurityEvent(logger, "JWT_MALFORMED", clientIp,
                    "Malformed JWT token used for: " + requestUri, "HIGH");
                throw new BadCredentialsException("Malformed JWT token");
                
            } catch (UnsupportedJwtException e) {
                logger.warn("Unsupported JWT token for request: {} from IP: {}", requestUri, clientIp);
                LoggingUtil.logSecurityEvent(logger, "JWT_UNSUPPORTED", clientIp,
                    "Unsupported JWT token used for: " + requestUri, "MEDIUM");
                throw new BadCredentialsException("Unsupported JWT token");
                
            } catch (SecurityException e) {
                logger.warn("Invalid JWT signature for request: {} from IP: {}", requestUri, clientIp);
                LoggingUtil.logSecurityEvent(logger, "JWT_INVALID_SIGNATURE", clientIp,
                    "Invalid JWT signature for: " + requestUri, "HIGH");
                throw new BadCredentialsException("Invalid JWT signature");
                
            } catch (IllegalArgumentException e) {
                logger.warn("Invalid JWT token for request: {} from IP: {}", requestUri, clientIp);
                LoggingUtil.logSecurityEvent(logger, "JWT_INVALID", clientIp,
                    "Invalid JWT token for: " + requestUri, "MEDIUM");
                throw new BadCredentialsException("Invalid JWT token");
                
            } catch (Exception e) {
                logger.error("Unexpected error during JWT validation for request: {} from IP: {} - {}", 
                    requestUri, clientIp, e.getMessage());
                LoggingUtil.logSecurityEvent(logger, "JWT_VALIDATION_ERROR", clientIp,
                    "Unexpected JWT validation error for: " + requestUri + " - " + e.getMessage(), "HIGH");
                LoggingUtil.logError(logger, "JWT_VALIDATION", e, 
                    java.util.Map.of("requestUri", requestUri, "clientIp", clientIp));
                throw new BadCredentialsException("Invalid token received");
            }
        } else {
            // Log requests without JWT (should be allowed for public endpoints)
            if (requestUri.startsWith("/api/")) {
                logger.debug("No JWT token provided for protected endpoint: {} from IP: {}", requestUri, clientIp);
            }
        }

        filterChain.doFilter(request, response);
    }

    private String getClientIpAddress(HttpServletRequest request) {
        String xForwardedFor = request.getHeader("X-Forwarded-For");
        if (xForwardedFor != null && !xForwardedFor.isEmpty()) {
            return xForwardedFor.split(",")[0].trim();
        }
        
        String xRealIp = request.getHeader("X-Real-IP");
        if (xRealIp != null && !xRealIp.isEmpty()) {
            return xRealIp;
        }
        
        return request.getRemoteAddr();
    }
}
