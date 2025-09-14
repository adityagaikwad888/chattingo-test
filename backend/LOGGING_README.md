# Chattingo Backend - Production Logging System

## Overview

This repository contains a comprehensive, production-level logging system for the Chattingo chat application. The logging infrastructure is designed for scalability, observability, and DevOps best practices.

## 🏗️ Architecture

### Logging Components

1. **Structured JSON Logging** - All logs are in JSON format for easy parsing
2. **Categorized Log Storage** - Logs are separated by category (auth, chat, error, etc.)
3. **Log Rotation & Archival** - Automatic rotation and S3 upload
4. **Real-time Monitoring** - ELK stack integration for real-time log analysis
5. **Health Monitoring** - Spring Boot Actuator for application health

### Log Categories

```
logs/
├── app/          # General application logs
├── auth/         # Authentication and security logs  
├── chat/         # Chat and messaging logs
├── error/        # Error and exception logs
├── system/       # System and infrastructure logs
└── websocket/    # WebSocket connection logs
```

## 🚀 Quick Start

### Prerequisites

- Docker & Docker Compose
- Java 17+
- Maven 3.6+
- (Optional) AWS credentials for S3 log upload

### Deployment

1. **Clone and setup:**
   ```bash
   cd backend
   ./scripts/setup-logs.sh  # Create log directory structure
   ```

2. **Configure environment:**
   ```bash
   cp .env.example .env
   # Edit .env with your configuration
   ```

3. **Deploy with logging infrastructure:**
   ```bash
   ./deploy.sh
   ```

This will start:
- Chattingo Backend API (port 8080)
- MySQL Database (port 3306)
- Elasticsearch (port 9200)
- Kibana (port 5601)
- Log Processor (background service)

## 📊 Monitoring & Observability

### Access Points

| Service | URL | Purpose |
|---------|-----|---------|
| Backend API | http://localhost:8080 | Main application |
| Health Check | http://localhost:8080/actuator/health | Application health |
| Info | http://localhost:8080/actuator/info | Application info |
| Kibana | http://localhost:5601 | Log visualization |

### Default Credentials

- **Kibana:** No authentication (development mode)

## 🔧 Configuration

### Environment Variables

#### Database Configuration
```bash
SPRING_DATASOURCE_URL=jdbc:mysql://localhost:3306/chattingo_db
SPRING_DATASOURCE_USERNAME=root
SPRING_DATASOURCE_PASSWORD=chattingo123
```

#### JWT Configuration
```bash
JWT_SECRET=your-256-bit-secret-key
```

#### AWS S3 Configuration (Optional)
```bash
AWS_ACCESS_KEY_ID=your_access_key
AWS_SECRET_ACCESS_KEY=your_secret_key
AWS_REGION=us-east-1
S3_BUCKET=chattingo-logs
```

#### Logging Configuration
```bash
LOG_ROTATION_ENABLED=true
LOG_ROTATION_MAX_AGE_DAYS=7
LOG_ROTATION_MAX_SIZE_MB=100
```

### Log Levels

- **Production:** WARN level for system components, INFO for application
- **Development:** DEBUG level for detailed troubleshooting
- **Test:** ERROR level to minimize noise

## 📝 Log Format

All logs follow a structured JSON format:

```json
{
  "timestamp": "2025-01-08T10:30:00.123Z",
  "level": "INFO",
  "thread": "http-nio-8080-exec-1",
  "correlationId": "abc123-def456-ghi789",
  "logger": "com.chattingo.Controller.AuthController",
  "message": "User authentication successful",
  "service": "chattingo-backend",
  "category": "authentication",
  "userId": 12345,
  "chatId": 67890,
  "event": "USER_LOGIN",
  "clientIp": "192.168.1.100",
  "userAgent": "Mozilla/5.0...",
  "processingTime": 150
}
```

## 🔍 Key Features

### 1. Correlation ID Tracking
Every request gets a unique correlation ID for tracing across services:
```java
String correlationId = LoggingUtil.generateCorrelationId();
LoggingUtil.setCorrelationId(correlationId);
```

### 2. Contextual Logging
Automatic context injection for user, chat, and message IDs:
```java
LoggingUtil.setUserContext(userId);
LoggingUtil.setChatContext(chatId);
LoggingUtil.setMessageContext(messageId);
```

### 3. Security Event Logging
Comprehensive security event tracking:
```java
LoggingUtil.logSecurityEvent(logger, "FAILED_LOGIN", clientIP, 
    "Multiple failed login attempts", "HIGH");
```

### 4. Performance Monitoring
Automatic API performance tracking:
```java
LoggingUtil.logApiEvent(logger, "POST", "/api/auth/login", 
    200, 150, clientIP, userAgent);
```

### 5. Business Metrics
Custom business metrics logging:
```java
LoggingUtil.logMetrics(logger, "messages_sent", 1, 
    Map.of("chatType", "group", "userCount", 5));
```

## 🛡️ Security & Compliance

### Security Features

1. **Sensitive Data Masking:** JWT tokens, passwords automatically masked
2. **Access Control:** Separate security logs for audit trails
3. **Rate Limiting Logs:** Track and alert on suspicious activity
4. **IP Tracking:** All requests logged with client IP addresses

### Compliance

- **GDPR:** User data anonymization in logs
- **SOX:** Immutable audit trails
- **PCI-DSS:** Secure transaction logging
- **HIPAA:** PHI data protection (if applicable)

## 📦 Production Deployment

### Docker Production Build

```dockerfile
# Multi-stage production build
FROM openjdk:17-jre-slim
COPY target/*.jar app.jar
VOLUME ["/var/log/chattingo"]
EXPOSE 8080
ENTRYPOINT ["java", "-jar", "/app.jar"]
```

### Kubernetes Deployment

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: chattingo-backend
spec:
  replicas: 3
  template:
    spec:
      containers:
      - name: backend
        image: chattingo/backend:latest
        volumeMounts:
        - name: logs
          mountPath: /var/log/chattingo
      volumes:
      - name: logs
        persistentVolumeClaim:
          claimName: chattingo-logs-pvc
```

## 🔄 Log Rotation & Management

### Automatic Log Rotation (Simplified Approach)

- **Time-based:** Hourly rotation check
- **Size-based:** Rotate when files exceed 50MB
- **Compression:** Automatic gzip compression
- **Retention:** Keep logs for 3 days locally (no S3 backup)
- **Cleanup:** Automatic deletion of old files

### Local Storage Only

Logs are managed locally with the following approach:
- Rotate logs based on size/age criteria
- Compress rotated logs with gzip
- Delete compressed logs after retention period
- No cloud storage or data transfer costs

### Configuration

```java
@Scheduled(fixedRate = 3600000) // Every hour
public void rotateAndUploadLogs() {
    // Automatic log rotation and local compression
}

@Scheduled(fixedRate = 86400000) // Daily cleanup
public void cleanupOldLogs() {
    // Delete old files beyond retention period
}
```

## 📈 Metrics & Alerting

### Custom Metrics

- **API Response Times:** P50, P95, P99 percentiles
- **Error Rates:** By endpoint and error type
- **User Activity:** Login rates, message counts
- **System Health:** JVM metrics, database connections

### Grafana Dashboards

1. **Application Overview:** Key metrics and health status
2. **API Performance:** Response times and error rates
3. **User Activity:** Registration, logins, messages
4. **System Resources:** CPU, memory, database metrics
5. **Security Dashboard:** Failed logins, suspicious activity

### Alerting Rules

```yaml
# Prometheus alerting rules
groups:
- name: chattingo
  rules:
  - alert: HighErrorRate
    expr: rate(http_requests_total{status=~"5.."}[5m]) > 0.1
  - alert: SlowResponse
    expr: histogram_quantile(0.95, http_request_duration_seconds) > 1
```

## 🧪 Testing the Logging System

### 1. Generate Test Logs
```bash
# Authentication logs
curl -X POST http://localhost:8080/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"password"}'

# Chat logs
curl -X POST http://localhost:8080/api/chats/single \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"userId":2}'
```

### 2. View Logs in Real-time
```bash
# Application logs
tail -f logs/app/application.log

# Authentication logs
tail -f logs/auth/auth.log

# All logs with JSON formatting
tail -f logs/*/*.log | jq '.'
```

### 3. Query Logs in Kibana
1. Open http://localhost:5601
2. Create index pattern: `chattingo-*`
3. Explore logs with filters and visualizations

## 🛠️ Development

### Running Locally

```bash
# Start only the database
docker-compose up -d mysql

# Run the application
mvn spring-boot:run

# View logs
tail -f logs/app/application.log
```

### Adding Custom Logging

```java
@RestController
public class MyController {
    private static final Logger logger = LoggerFactory.getLogger(MyController.class);
    
    @PostMapping("/my-endpoint")
    public ResponseEntity<?> myEndpoint() {
        String correlationId = LoggingUtil.generateCorrelationId();
        LoggingUtil.setCorrelationId(correlationId);
        
        try {
            // Your business logic here
            
            LoggingUtil.builder()
                .event("CUSTOM_EVENT")
                .userId(userId)
                .detail("key", "value")
                .info(logger);
                
            return ResponseEntity.ok(result);
        } catch (Exception e) {
            LoggingUtil.logError(logger, "MY_OPERATION", e, 
                Map.of("context", "additional info"));
            throw e;
        } finally {
            LoggingUtil.clearContext();
        }
    }
}
```

## 🐛 Troubleshooting

### Common Issues

1. **Logs not appearing in Kibana**
   - Check Elasticsearch is running: `curl http://localhost:9200/_health`
   - Verify Filebeat configuration: `docker logs chattingo-filebeat`

2. **High disk usage**
   - Check log rotation settings in `application.properties`
   - Verify S3 upload is working: `docker logs chattingo-log-processor`

3. **Performance issues**
   - Increase async queue sizes in `logback-spring.xml`
   - Adjust log levels to reduce verbosity

### Log Locations

```bash
# Application logs
./logs/app/application.log

# Docker container logs
docker logs chattingo-backend
docker logs chattingo-elasticsearch
docker logs chattingo-filebeat

# System logs
journalctl -u docker
```

## 📚 Additional Resources

- [Spring Boot Logging](https://docs.spring.io/spring-boot/docs/current/reference/html/features.html#features.logging)
- [Logback Configuration](http://logback.qos.ch/manual/configuration.html)
- [ELK Stack Documentation](https://www.elastic.co/guide/index.html)
- [Prometheus Monitoring](https://prometheus.io/docs/)
- [Grafana Dashboards](https://grafana.com/docs/)

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Add comprehensive logging to new features
4. Test the logging system
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

**Built with ❤️ for DevOps Excellence and Production Monitoring**
