# 📋 Complete Environment Variables Reference - Chattingo

## 🎯 Overview

This document lists **ALL** environment variables used across the entire Chattingo application stack. The variables are organized by component and category for easy reference.

## 📊 Summary Statistics

- **Total Variables**: 200+
- **Backend Variables**: 80+
- **Frontend Variables**: 25+
- **Database Variables**: 20+
- **Infrastructure Variables**: 75+

## 🔍 Variable Categories

### 🛢️ **Database & Persistence (25 variables)**
```bash
# Core Database
SPRING_DATASOURCE_URL, SPRING_DATASOURCE_USERNAME, SPRING_DATASOURCE_PASSWORD
SPRING_DATASOURCE_DRIVER_CLASS_NAME, MYSQL_DATABASE, MYSQL_USER, MYSQL_PASSWORD
MYSQL_ROOT_PASSWORD, MYSQL_CHARSET, MYSQL_COLLATION

# JPA Configuration
SPRING_JPA_HIBERNATE_DDL_AUTO, SPRING_JPA_SHOW_SQL
SPRING_JPA_PROPERTIES_HIBERNATE_DIALECT

# MySQL Performance
MAX_CONNECTIONS, INNODB_BUFFER_POOL_SIZE, INNODB_LOG_FILE_SIZE
INNODB_FLUSH_LOG_AT_TRX_COMMIT, INNODB_FLUSH_METHOD, QUERY_CACHE_TYPE
QUERY_CACHE_SIZE, SLOW_QUERY_LOG, LONG_QUERY_TIME, BIND_ADDRESS, SKIP_NAME_RESOLVE
```

### 🔐 **Security & Authentication (15 variables)**
```bash
# JWT Configuration
JWT_SECRET, JWT_EXPIRATION

# CORS Configuration
CORS_ALLOWED_ORIGINS, CORS_ALLOWED_METHODS, CORS_ALLOWED_HEADERS, CORS_ALLOW_CREDENTIALS

# Session Security
SESSION_TIMEOUT, SESSION_COOKIE_SECURE, SESSION_COOKIE_HTTP_ONLY

# Security Headers
SECURITY_FRAME_OPTIONS, SECURITY_XSS_PROTECTION, SECURITY_CONTENT_TYPE_OPTIONS
SECURITY_REFERRER_POLICY, SECURITY_CONTENT_SECURITY_POLICY
```

### ⚙️ **Spring Boot Application (30 variables)**
```bash
# Core Application
SPRING_APPLICATION_NAME, SERVER_PORT, SERVER_SERVLET_CONTEXT_PATH
SPRING_PROFILES_ACTIVE, INFO_APP_NAME, INFO_APP_DESCRIPTION, INFO_APP_VERSION

# Timezone & Localization
SPRING_JACKSON_TIME_ZONE, USER_TIMEZONE, DEFAULT_TIMEZONE, DEFAULT_LOCALE
DATE_FORMAT, TIME_FORMAT

# Performance & Threading
SPRING_TASK_EXECUTION_POOL_CORE_SIZE, SPRING_TASK_EXECUTION_POOL_MAX_SIZE
SPRING_TASK_EXECUTION_POOL_QUEUE_CAPACITY, SPRING_TASK_SCHEDULING_POOL_SIZE

# JVM Configuration
JAVA_OPTS

# Actuator/Monitoring
MANAGEMENT_ENDPOINTS_WEB_EXPOSURE_INCLUDE, MANAGEMENT_ENDPOINT_HEALTH_SHOW_DETAILS
MANAGEMENT_ENDPOINT_HEALTH_PROBES_ENABLED, MANAGEMENT_HEALTH_LIVENESSSTATE_ENABLED
MANAGEMENT_HEALTH_READINESSSTATE_ENABLED, MANAGEMENT_METRICS_EXPORT_PROMETHEUS_ENABLED
```

### 📝 **Logging & Monitoring (20 variables)**
```bash
# Logging Configuration
LOG_PATH, LOGGING_CONFIG, LOGGING_LEVEL_COM_CHATTINGO
LOGGING_LEVEL_ORG_SPRINGFRAMEWORK_SECURITY, LOGGING_LEVEL_ORG_HIBERNATE
LOGGING_LEVEL_ORG_SPRINGFRAMEWORK_WEB_SOCKET

# Log Rotation
LOG_ROTATION_ENABLED, LOG_ROTATION_MAX_AGE_DAYS, LOG_ROTATION_MAX_SIZE_MB
```

### 🌐 **Frontend/React (25 variables)**
```bash
# API Configuration
REACT_APP_API_URL, REACT_APP_API_BASE_URL, REACT_APP_WS_BASE_URL

# Application Info
REACT_APP_NAME, REACT_APP_VERSION, REACT_APP_ENVIRONMENT

# Feature Flags
REACT_APP_ENABLE_ANALYTICS, REACT_APP_ENABLE_NOTIFICATIONS, REACT_APP_ENABLE_DARK_MODE

# Build Configuration
GENERATE_SOURCEMAP, REACT_APP_BUILD_VERSION, REACT_APP_BUILD_DATE

# Development Tools
HOT_RELOAD_ENABLED, DEV_TOOLS_ENABLED, SOURCE_MAPS_ENABLED, WEBPACK_DEV_SERVER_PORT

# Optional Analytics
REACT_APP_GOOGLE_ANALYTICS_ID, REACT_APP_SENTRY_DSN
```

### ☁️ **Cloud & Infrastructure (35 variables)**
```bash
# AWS Configuration
AWS_REGION, AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY, S3_BUCKET
S3_UPLOAD_ENABLED, S3_CLEANUP_MAX_AGE_DAYS, S3_DELETE_AFTER_UPLOAD
S3_CHECK_INTERVAL_MINUTES, S3_LOG_LEVEL

# Google Cloud
GOOGLE_CLOUD_PROJECT, GOOGLE_APPLICATION_CREDENTIALS

# Azure Configuration
AZURE_SUBSCRIPTION_ID, AZURE_RESOURCE_GROUP, AZURE_LOCATION

# Domain Configuration
PRIMARY_DOMAIN, API_DOMAIN

# SSL/TLS
TLS_ENABLED, TLS_CERT_PATH, TLS_KEY_PATH, ACME_EMAIL, ACME_SERVER

# Load Balancer
LOAD_BALANCER_TYPE, LOAD_BALANCER_SCHEME
```

### 🐳 **Container & Kubernetes (25 variables)**
```bash
# Docker Registry
DOCKER_REGISTRY, DOCKER_USERNAME, DOCKER_PASSWORD

# Container Resources
CONTAINER_MEMORY_REQUEST, CONTAINER_MEMORY_LIMIT, CONTAINER_CPU_REQUEST
CONTAINER_CPU_LIMIT, CONTAINER_EPHEMERAL_STORAGE_REQUEST, CONTAINER_EPHEMERAL_STORAGE_LIMIT

# Pod Information
POD_NAME, POD_NAMESPACE, POD_IP, NODE_NAME, SERVICE_ACCOUNT_NAME, PRIORITY_CLASS_NAME

# Nginx Configuration
NGINX_WORKER_PROCESSES, NGINX_WORKER_CONNECTIONS, NGINX_KEEPALIVE_TIMEOUT
NGINX_CLIENT_MAX_BODY_SIZE, NGINX_PROXY_READ_TIMEOUT, NGINX_PROXY_CONNECT_TIMEOUT
NGINX_GZIP_ENABLED
```

### 🔄 **Caching & Performance (15 variables)**
```bash
# Redis Configuration
REDIS_ENABLED, REDIS_HOST, REDIS_PORT, REDIS_PASSWORD, REDIS_DATABASE
REDIS_TIMEOUT, REDIS_MAX_CONNECTIONS

# General Caching
CACHE_ENABLED, CACHE_TTL, CACHE_MAX_SIZE

# CDN Configuration
CDN_ENABLED, CDN_URL

# WebSocket Performance
WEBSOCKET_MESSAGE_SIZE_LIMIT, WEBSOCKET_CONNECTION_LIMIT, WEBSOCKET_IDLE_TIMEOUT
WEBSOCKET_HEARTBEAT_INTERVAL
```

### 📊 **Logging & Analytics (20 variables)**
```bash
# Elasticsearch
ELASTICSEARCH_ENABLED, ELASTICSEARCH_HOST, ELASTICSEARCH_PORT, ELASTICSEARCH_INDEX
ELASTICSEARCH_USERNAME, ELASTICSEARCH_PASSWORD

# Kibana
KIBANA_ENABLED, KIBANA_HOST, KIBANA_PORT

# Filebeat
FILEBEAT_ENABLED, FILEBEAT_CONFIG_PATH

# Backup Configuration
DB_BACKUP_ENABLED, DB_BACKUP_SCHEDULE, DB_BACKUP_RETENTION_DAYS, DB_BACKUP_STORAGE_PATH
LOG_BACKUP_ENABLED, LOG_BACKUP_SCHEDULE, LOG_BACKUP_RETENTION_DAYS, LOG_BACKUP_STORAGE_PATH
```

### 📧 **Notifications & Communication (15 variables)**
```bash
# Email Configuration
EMAIL_ENABLED, SMTP_HOST, SMTP_PORT, SMTP_USERNAME, SMTP_PASSWORD
SMTP_FROM_EMAIL, SMTP_FROM_NAME, SMTP_TLS_ENABLED, SMTP_AUTH_ENABLED

# External Notifications
SLACK_WEBHOOK_URL, DISCORD_WEBHOOK_URL

# Rate Limiting
RATE_LIMIT_REQUESTS_PER_MINUTE, RATE_LIMIT_BURST_SIZE
API_RATE_LIMIT, API_TIMEOUT
```

### 🚀 **Feature Flags & Toggles (15 variables)**
```bash
# Application Features
FEATURE_USER_REGISTRATION, FEATURE_GROUP_CHAT, FEATURE_FILE_UPLOAD
FEATURE_VIDEO_CALL, FEATURE_SCREEN_SHARE, FEATURE_EMOJI_REACTIONS
FEATURE_MESSAGE_ENCRYPTION

# File Upload Features
MAX_FILE_SIZE, ALLOWED_FILE_TYPES, UPLOAD_DIRECTORY, UPLOAD_VIRUS_SCAN_ENABLED

# Maintenance & Health
MAINTENANCE_MODE, MAINTENANCE_MESSAGE, HEALTH_CHECK_ENABLED
HEALTH_CHECK_TIMEOUT, HEALTH_CHECK_INTERVAL, HEALTH_CHECK_RETRIES
```

### 🧪 **Development & Testing (15 variables)**
```bash
# Development Tools
DEBUG_MODE, VERBOSE_LOGGING, STACK_TRACE_ENABLED

# Testing Configuration
TEST_DATABASE_URL, TEST_PROFILE, JUNIT_PLATFORM_OUTPUT_CAPTURE_STDOUT
JUNIT_PLATFORM_OUTPUT_CAPTURE_STDERR

# API Configuration
API_VERSION, API_PAGINATION_DEFAULT_SIZE, API_PAGINATION_MAX_SIZE
```

## 🔧 **Usage by Component**

### **Backend (Spring Boot)**
- Database: 25 variables
- Security: 15 variables  
- Application: 30 variables
- Logging: 20 variables
- **Total: 90+ variables**

### **Frontend (React)**
- API Configuration: 5 variables
- Application: 8 variables
- Build: 5 variables
- Features: 7 variables
- **Total: 25 variables**

### **Infrastructure (K8s/Docker)**
- Container: 25 variables
- Cloud: 35 variables
- Monitoring: 20 variables
- Networking: 15 variables
- **Total: 95+ variables**

## 📁 **Environment File Organization**

### **.env.dev (Development)**
- Relaxed security settings
- Debug logging enabled
- Local domains
- Minimal external services
- **Focus**: Developer productivity

### **.env.staging (Staging)**
- Production-like configuration
- Real domains with staging prefix
- Moderate security
- Full logging enabled
- **Focus**: Pre-production testing

### **.env.prod (Production)**
- Maximum security
- Strong passwords required
- Real domains
- Optimized performance
- **Focus**: Production stability

## 🚨 **Critical Security Variables**

### **Must Change for Production:**
```bash
JWT_SECRET                          # 256-bit secret key
MYSQL_ROOT_PASSWORD                 # Strong database password
MYSQL_PASSWORD                      # Application DB password  
AWS_ACCESS_KEY_ID                  # AWS credentials
AWS_SECRET_ACCESS_KEY              # AWS secret key
SMTP_PASSWORD                      # Email server password
REDIS_PASSWORD                     # Redis cache password
ELASTICSEARCH_PASSWORD             # Elasticsearch password
```

## ✅ **Validation Checklist**

### **Required Variables (All Environments):**
- [x] SPRING_DATASOURCE_URL
- [x] SPRING_DATASOURCE_PASSWORD  
- [x] JWT_SECRET (minimum 32 characters)
- [x] MYSQL_ROOT_PASSWORD
- [x] CORS_ALLOWED_ORIGINS

### **Production-Specific Requirements:**
- [x] All passwords are strong (12+ characters)
- [x] Real domain names configured
- [x] SSL/TLS enabled
- [x] Monitoring credentials set
- [x] Backup configuration enabled
- [x] Cloud credentials configured (if applicable)

## 🔄 **Environment Variable Injection Methods**

### **1. Jenkins Secret Files (Recommended)**
- Complete `.env.*` files stored as Jenkins credentials
- Loaded dynamically based on environment parameter
- Maximum security and flexibility

### **2. Kubernetes ConfigMaps/Secrets**
- Non-sensitive variables in ConfigMaps
- Sensitive variables in Secrets
- K8s-native approach

### **3. Docker Build Arguments**
- Variables passed during Docker build
- Baked into container images
- Less flexible but simple

### **4. Runtime Environment Variables**
- Variables set at container startup
- Most flexible approach
- Requires orchestration

## 🎯 **Best Practices**

1. **🔐 Security First**: Never store secrets in Git
2. **🌍 Environment Parity**: Keep environments consistent
3. **📋 Documentation**: Document all variables and their purpose
4. **✅ Validation**: Validate all required variables at startup
5. **🔄 Rotation**: Regular rotation of passwords and keys
6. **📊 Monitoring**: Monitor configuration changes
7. **🧪 Testing**: Test with different environment configurations

This comprehensive list ensures your Chattingo application can be configured for any environment while maintaining security and flexibility! 🚀
