# Environment Variables and Secrets Management

This document explains how to manage environment variables and Kubernetes secrets securely for the Chattingo application across different environments (development, staging, production) and cloud providers.

## 🔐 Security Best Practices

### ⚠️ CRITICAL SECURITY RULES

1. **NEVER commit actual secrets to version control**
2. **Always use strong, unique passwords and keys**
3. **Rotate secrets regularly (at least every 90 days)**
4. **Use cloud-native secret management services in production**
5. **Encrypt sensitive files at rest**
6. **Use least privilege access principles**

## 📁 File Structure

```
k8s kind/
├── env/
│   ├── .env.template      # Template with all variables
│   ├── .env.dev          # Development environment
│   ├── .env.staging      # Staging environment (create from template)
│   ├── .env.prod         # Production environment (create from template)
│   ├── .env              # Symlink to current environment
│   └── backups/          # Encrypted backups of secrets
├── manage-env.sh         # Environment management script
└── deploy-cloud.sh       # Cloud deployment script
```

## 🚀 Quick Start

### 1. Initialize Environment Files

```bash
# Initialize all environment files from template
./manage-env.sh init

# This creates:
# - env/.env.dev
# - env/.env.staging  
# - env/.env.prod
# - env/.env -> .env.dev (symlink)
```

### 2. Customize Environment Files

Edit each environment file with your actual values:

```bash
# Edit development environment
nano env/.env.dev

# Edit production environment
nano env/.env.prod
```

**Important:** Replace all `CHANGE_ME_*` values with secure secrets!

### 3. Validate Configuration

```bash
# Validate all environments
./manage-env.sh validate

# Validate specific environment
./manage-env.sh validate -e prod
```

### 4. Create Kubernetes Secrets

```bash
# Create secrets for development
./manage-env.sh create-secrets -e dev

# Create secrets for production
./manage-env.sh create-secrets -e prod -n chattingo
```

## 🔧 Environment Management Commands

### Initialize

```bash
./manage-env.sh init
```
Creates environment files from templates if they don't exist.

### Validate

```bash
# Validate all environments
./manage-env.sh validate

# Validate specific environment
./manage-env.sh validate -e prod
```
Checks for:
- Missing required variables
- Placeholder values that need to be changed
- JWT secret length (minimum 32 characters)
- Common security issues

### Create Secrets

```bash
# Create secrets with dry-run (preview only)
./manage-env.sh create-secrets -e prod --dry-run

# Create secrets for real
./manage-env.sh create-secrets -e prod -n chattingo

# Create monitoring secrets
./manage-env.sh create-secrets -e prod -n chattingo-monitoring
```

### Update Secrets

```bash
# Update existing secrets (will delete and recreate)
./manage-env.sh update-secrets -e prod -n chattingo --force
```

### Backup Secrets

```bash
# Backup current secrets (creates encrypted backup)
./manage-env.sh backup-secrets -e prod -n chattingo
```

### Encrypt/Decrypt Files

```bash
# Encrypt sensitive environment file
./manage-env.sh encrypt -f env/.env.prod

# Decrypt encrypted file
./manage-env.sh decrypt -f env/.env.prod.gpg
```

## 🌍 Environment-Specific Configuration

### Development Environment (.env.dev)

- Uses local/development-friendly settings
- Weaker passwords acceptable
- Debug logging enabled
- Source maps enabled for frontend
- Local domain names (chattingo.local)

### Staging Environment (.env.staging)

- Production-like configuration
- Stronger security than dev
- Limited debug information
- Real domain names
- SSL/TLS enabled

### Production Environment (.env.prod)

- Maximum security
- Strong passwords and keys
- Minimal logging
- SSL/TLS required
- Real domain names
- Cloud-native secret management

## ☁️ Cloud Deployment

### AWS

```bash
# Deploy to AWS EKS
./deploy-cloud.sh deploy -p aws -e prod -r us-west-2 -c chattingo-prod

# Environment variables for AWS:
export AWS_REGION=us-west-2
export AWS_ACCESS_KEY_ID=your-access-key
export AWS_SECRET_ACCESS_KEY=your-secret-key
```

### Google Cloud Platform

```bash
# Deploy to Google GKE
./deploy-cloud.sh deploy -p gcp -e prod -r us-central1 -z us-central1-a

# Environment variables for GCP:
export GOOGLE_CLOUD_PROJECT=your-project-id
export GOOGLE_APPLICATION_CREDENTIALS=path/to/service-account.json
```

### Azure

```bash
# Deploy to Azure AKS
./deploy-cloud.sh deploy -p azure -e prod -r eastus -c chattingo-prod

# Environment variables for Azure:
export AZURE_SUBSCRIPTION_ID=your-subscription-id
export AZURE_RESOURCE_GROUP=chattingo-rg
export AZURE_CLIENT_ID=your-client-id
export AZURE_CLIENT_SECRET=your-client-secret
```

### Local Kind

```bash
# Deploy to local Kind cluster
./deploy-cloud.sh deploy -p kind -e dev
```

## 🔑 Required Secrets

### Backend Secrets

| Variable | Description | Example |
|----------|-------------|---------|
| `JWT_SECRET` | JWT signing key (min 32 chars) | `super-secure-jwt-key-256bits` |
| `SPRING_DATASOURCE_USERNAME` | Database username | `chattingo_user` |
| `SPRING_DATASOURCE_PASSWORD` | Database password | `SecureDbPass123!` |

### Database Secrets

| Variable | Description | Example |
|----------|-------------|---------|
| `MYSQL_ROOT_PASSWORD` | MySQL root password | `RootPass123!` |
| `MYSQL_USER` | Application database user | `chattingo_user` |
| `MYSQL_PASSWORD` | Application database password | `SecureDbPass123!` |

### Monitoring Secrets

| Variable | Description | Example |
|----------|-------------|---------|
| `GF_SECURITY_ADMIN_PASSWORD` | Grafana admin password | `GrafanaAdmin123!` |

## 🛡️ Cloud Secret Management

### AWS Secrets Manager

```bash
# Store secret in AWS Secrets Manager
aws secretsmanager create-secret \
    --name chattingo/prod/jwt-secret \
    --secret-string "your-super-secure-jwt-secret"

# Use in Kubernetes with External Secrets Operator
```

### Google Secret Manager

```bash
# Store secret in Google Secret Manager
gcloud secrets create jwt-secret --data-file=- <<< "your-super-secure-jwt-secret"

# Use in Kubernetes with Secret Manager CSI driver
```

### Azure Key Vault

```bash
# Store secret in Azure Key Vault
az keyvault secret set \
    --vault-name chattingo-keyvault \
    --name jwt-secret \
    --value "your-super-secure-jwt-secret"

# Use in Kubernetes with Secrets Store CSI driver
```

## 📋 Environment Variables Reference

### Backend Configuration

```bash
# Database
SPRING_DATASOURCE_URL=jdbc:mysql://mysql-service:3306/chattingo_db
SPRING_DATASOURCE_USERNAME=chattingo_user
SPRING_DATASOURCE_PASSWORD=SecurePassword123!
SPRING_DATASOURCE_DRIVER_CLASS_NAME=com.mysql.cj.jdbc.Driver

# Security
JWT_SECRET=your-256-bit-secret-key-here
JWT_EXPIRATION=86400000

# CORS
CORS_ALLOWED_ORIGINS=https://yourdomain.com,https://www.yourdomain.com
CORS_ALLOWED_METHODS=GET,POST,PUT,DELETE,OPTIONS
CORS_ALLOW_CREDENTIALS=true

# Server
SERVER_PORT=8080
SPRING_PROFILES_ACTIVE=production

# Logging
LOG_PATH=/var/log/chattingo
LOGGING_LEVEL_COM_CHATTINGO=INFO

# Performance
JAVA_OPTS=-Xmx2g -Xms1g -XX:+UseG1GC
```

### Frontend Configuration

```bash
# API Endpoints
REACT_APP_API_BASE_URL=https://api.yourdomain.com
REACT_APP_WS_BASE_URL=wss://api.yourdomain.com/ws

# Application
REACT_APP_NAME=Chattingo
REACT_APP_VERSION=1.0.0
REACT_APP_ENVIRONMENT=production

# Build
GENERATE_SOURCEMAP=false
```

### Domain Configuration

```bash
# Domains
PRIMARY_DOMAIN=yourdomain.com
API_DOMAIN=api.yourdomain.com
GRAFANA_DOMAIN=grafana.yourdomain.com
PROMETHEUS_DOMAIN=prometheus.yourdomain.com

# SSL/TLS
ACME_EMAIL=admin@yourdomain.com
ACME_SERVER=https://acme-v02.api.letsencrypt.org/directory
```

## 🔍 Troubleshooting

### Common Issues

1. **"CHANGE_ME" values not replaced**
   ```bash
   ./manage-env.sh validate -e prod
   # Fix: Replace all placeholder values in .env.prod
   ```

2. **JWT secret too short**
   ```bash
   # Error: JWT_SECRET must be at least 32 characters
   # Fix: Generate longer secret
   openssl rand -base64 32
   ```

3. **Secrets not found in Kubernetes**
   ```bash
   kubectl get secrets -n chattingo
   # Fix: Create secrets
   ./manage-env.sh create-secrets -e prod
   ```

4. **Permission denied on scripts**
   ```bash
   chmod +x manage-env.sh deploy-cloud.sh
   ```

### Debugging

```bash
# Check environment file syntax
bash -n env/.env.prod

# Test secret creation (dry-run)
./manage-env.sh create-secrets -e prod --dry-run

# View current secrets (base64 encoded)
kubectl get secret chattingo-backend-secrets -o yaml

# Decode secret value
kubectl get secret chattingo-backend-secrets -o jsonpath='{.data.JWT_SECRET}' | base64 -d
```

## 📚 Additional Resources

- [Kubernetes Secrets Documentation](https://kubernetes.io/docs/concepts/configuration/secret/)
- [12 Factor App - Config](https://12factor.net/config)
- [OWASP Secret Management Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/Secrets_Management_Cheat_Sheet.html)
- [AWS Secrets Manager](https://aws.amazon.com/secrets-manager/)
- [Google Secret Manager](https://cloud.google.com/secret-manager)
- [Azure Key Vault](https://azure.microsoft.com/services/key-vault/)

## 🆘 Emergency Procedures

### Secret Compromise

1. **Immediately rotate the compromised secret**
2. **Update all environment files**
3. **Update Kubernetes secrets**
4. **Restart affected pods**
5. **Review access logs**
6. **Update security procedures**

```bash
# Emergency secret rotation
./manage-env.sh backup-secrets -e prod
# Update .env.prod with new secrets
./manage-env.sh update-secrets -e prod --force
kubectl rollout restart deployment/chattingo-backend -n chattingo
```

---

**Remember:** Security is everyone's responsibility. When in doubt, choose the more secure option! 🔒
