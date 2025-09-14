package com.chattingo.Controller;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.authentication.BadCredentialsException;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.chattingo.Exception.UserException;
import com.chattingo.Model.User;
import com.chattingo.Payload.AuthResponse;
import com.chattingo.Payload.LoginRequest;
import com.chattingo.Repository.UserRepository;
import com.chattingo.config.CustomUserService;
import com.chattingo.config.TokenProvider;
import com.chattingo.security.InputValidator;
import com.chattingo.util.LoggingUtil;

import jakarta.servlet.http.HttpServletRequest;

@RestController
@RequestMapping("/auth")
public class AuthController {

    private static final Logger logger = LoggerFactory.getLogger(AuthController.class);

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private PasswordEncoder passwordEncoder;

    @Autowired
    private TokenProvider tokenProvider;

    @Autowired
    private CustomUserService customUserService;
    
    @Autowired
    private InputValidator inputValidator;

    @PostMapping("/signup")
    public ResponseEntity<AuthResponse> createUserHandler(@RequestBody User user, HttpServletRequest request) throws UserException {
        // Set correlation ID for request tracking
        String correlationId = LoggingUtil.generateCorrelationId();
        LoggingUtil.setCorrelationId(correlationId);
        
        String email = user.getEmail();
        String name = user.getName();
        String password = user.getPassword();
        String clientIp = getClientIpAddress(request);

        logger.info("User signup attempt - Email: {}, IP: {}", email, clientIp);
        
        try {
            // Enhanced input validation
            if (!inputValidator.isValidEmail(email)) {
                LoggingUtil.logAuthEvent(logger, "SIGNUP_FAILED", email, false, "Invalid email format");
                throw new UserException("Invalid email format");
            }
            
            if (!inputValidator.isValidPassword(password)) {
                LoggingUtil.logAuthEvent(logger, "SIGNUP_FAILED", email, false, "Password does not meet requirements");
                throw new UserException("Password must be at least 8 characters with letters and numbers");
            }
            
            if (!inputValidator.isValidUsername(name)) {
                LoggingUtil.logAuthEvent(logger, "SIGNUP_FAILED", email, false, "Invalid username format");
                throw new UserException("Username must be 3-30 characters, alphanumeric with underscores only");
            }
            
            // Sanitize inputs
            email = inputValidator.sanitizeInput(email);
            name = inputValidator.sanitizeInput(name);
            
            User isUser = this.userRepository.findByEmail(email);
            if (isUser != null) {
                LoggingUtil.logAuthEvent(logger, "SIGNUP_FAILED", email, false, "Email already exists");
                throw new UserException("Email is userd with another account");
            }
            
            User createdUser = new User();
            createdUser.setEmail(email);
            createdUser.setName(name);
            createdUser.setPassword(this.passwordEncoder.encode(password));

            userRepository.save(createdUser);
            LoggingUtil.setUserContext(createdUser.getId());

            logger.info("User created successfully - ID: {}, Email: {}", createdUser.getId(), email);

            Authentication authentication = this.authenticate(email, password);
            SecurityContextHolder.getContext().setAuthentication(authentication);

            String jwt = this.tokenProvider.generateToken(authentication);

            LoggingUtil.logAuthEvent(logger, "SIGNUP_SUCCESS", email, true, 
                "User registered and authenticated successfully");

            AuthResponse response = new AuthResponse(jwt, true);

            logger.info("Signup successful for user: {}", email);
            return new ResponseEntity<AuthResponse>(response, HttpStatus.ACCEPTED);
            
        } catch (Exception e) {
            LoggingUtil.logAuthEvent(logger, "SIGNUP_ERROR", email, false, e.getMessage());
            LoggingUtil.logError(logger, "USER_SIGNUP", e, 
                java.util.Map.of("email", email, "clientIp", clientIp));
            throw e;
        } finally {
            LoggingUtil.clearContext();
        }
    }

    @PostMapping("/signin")
    public ResponseEntity<AuthResponse> loginHandler(@RequestBody LoginRequest request, HttpServletRequest httpRequest) {
        // Set correlation ID for request tracking
        String correlationId = LoggingUtil.generateCorrelationId();
        LoggingUtil.setCorrelationId(correlationId);

        String email = request.getEmail();
        String password = request.getPassword();
        String clientIp = getClientIpAddress(httpRequest);

        logger.info("User signin attempt - Email: {}, IP: {}", email, clientIp);

        try {
            // Enhanced input validation
            if (!inputValidator.isValidEmail(email)) {
                LoggingUtil.logAuthEvent(logger, "SIGNIN_FAILED", email, false, "Invalid email format");
                throw new BadCredentialsException("Invalid email format");
            }
            
            // Sanitize inputs
            email = inputValidator.sanitizeInput(email);
            
            Authentication authentication = this.authenticate(email, password);
            SecurityContextHolder.getContext().setAuthentication(authentication);

            String jwt = this.tokenProvider.generateToken(authentication);

            // Get user details for context
            User user = this.userRepository.findByEmail(email);
            if (user != null) {
                LoggingUtil.setUserContext(user.getId());
            }

            LoggingUtil.logAuthEvent(logger, "SIGNIN_SUCCESS", email, true, 
                "User authenticated successfully");

            AuthResponse response = new AuthResponse(jwt, true);

            logger.info("Signin successful for user: {}", email);
            return new ResponseEntity<AuthResponse>(response, HttpStatus.ACCEPTED);
            
        } catch (BadCredentialsException e) {
            LoggingUtil.logAuthEvent(logger, "SIGNIN_FAILED", email, false, "Invalid credentials");
            LoggingUtil.logSecurityEvent(logger, "FAILED_LOGIN_ATTEMPT", clientIp, 
                "Failed login attempt for email: " + email, "MEDIUM");
            
            logger.warn("Failed signin attempt for user: {} from IP: {}", email, clientIp);
            throw e;
        } catch (Exception e) {
            LoggingUtil.logAuthEvent(logger, "SIGNIN_ERROR", email, false, e.getMessage());
            LoggingUtil.logError(logger, "USER_SIGNIN", e, 
                java.util.Map.of("email", email, "clientIp", clientIp));
            throw e;
        } finally {
            LoggingUtil.clearContext();
        }
    }

    public Authentication authenticate(String username, String password) {
        logger.debug("Authenticating user: {}", username);
        
        try {
            UserDetails userDetails = this.customUserService.loadUserByUsername(username);

            if (userDetails == null) {
                logger.warn("User not found: {}", username);
                throw new BadCredentialsException("Invalid username");
            }

            if (!passwordEncoder.matches(password, userDetails.getPassword())) {
                logger.warn("Password mismatch for user: {}", username);
                throw new BadCredentialsException("Invalid password or username");
            }

            logger.debug("Authentication successful for user: {}", username);
            return new UsernamePasswordAuthenticationToken(userDetails, null, userDetails.getAuthorities());
            
        } catch (Exception e) {
            logger.error("Authentication error for user: {} - {}", username, e.getMessage());
            throw e;
        }
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
