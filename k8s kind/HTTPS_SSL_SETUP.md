# 🔐 HTTPS/SSL Setup Guide for Chattingo Kubernetes

## 🎯 Overview

This document provides a complete guide for setting up **HTTPS/SSL certificates** and **AWS S3 log archival** in your Chattingo Kubernetes deployment. The system uses **cert-manager** with **self-signed certificates** for development and can be easily upgraded to **Let's Encrypt** for production.

## 🔑 SSL Certificate Infrastructure

### Components Added

| Component | File | Purpose |
|-----------|------|---------|
| **cert-manager** | `25-cert-manager.yaml` | Certificate lifecycle management |
| **SSL Certificates** | `26-ssl-certificates.yaml` | Self-signed CA and service certificates |
| **HTTPS Ingress** | `27-https-ingress.yaml` | Kibana & logging dashboards with SSL |

### Certificate Hierarchy

```
Chattingo Root CA (Self-signed, 1 year)
├── chattingo.local (*.chattingo.local) - Main application
├── kibana.chattingo.local - Logging dashboard  
├── grafana.chattingo.local - Monitoring dashboard
├── prometheus.chattingo.local - Metrics dashboard
└── elasticsearch.chattingo.local - Internal service
```

## ☁️ AWS S3 Configuration

### Your S3 Settings (Applied)

```yaml
# S3 Configuration (Mumbai Region)
AWS_REGION: "ap-south-1"
S3_BUCKET: "chattingo-logs-secure-2025"

# IAM User: chattingo-s3-logs
AWS_ACCESS_KEY_ID: "YOUR_AWS_ACCESS_KEY_ID"
AWS_SECRET_ACCESS_KEY: "YOUR_AWS_SECRET_ACCESS_KEY"
```

### S3 Bucket Structure

```
chattingo-logs-secure-2025/
└── chattingo-logs/
    └── 2025/
        └── 09/
            └── 10/
                └── archive/
                    ├── app_application_20250910_120000.log.gz
                    ├── auth_auth_20250910_120000.log.gz
                    ├── chat_chat_20250910_120000.log.gz
                    ├── error_error_20250910_120000.log.gz
                    ├── system_system_20250910_120000.log.gz
                    └── websocket_websocket_20250910_120000.log.gz
```

## 🚀 Deployment Instructions

### 1. Prerequisites

```bash
# Ensure Kind cluster is running
kind create cluster --config=00-kind-config.yaml

# Add hostnames to /etc/hosts for local testing
sudo tee -a /etc/hosts << EOF
127.0.0.1 chattingo.local
127.0.0.1 www.chattingo.local
127.0.0.1 kibana.chattingo.local
127.0.0.1 grafana.chattingo.local
127.0.0.1 prometheus.chattingo.local
127.0.0.1 logs.chattingo.local
127.0.0.1 monitoring.chattingo.local
EOF
```

### 2. Deploy Complete Infrastructure

```bash
# Deploy all components including HTTPS
kubectl apply -k .

# Wait for cert-manager to be ready
kubectl wait --for=condition=ready pod -l app=cert-manager -n cert-manager --timeout=300s

# Wait for all SSL certificates to be issued
kubectl wait --for=condition=ready certificate --all --timeout=300s

# Check certificate status
kubectl get certificates -A
```

### 3. Verify SSL Certificates

```bash
# Check certificate issuance
kubectl describe certificate chattingo-tls -n chattingo
kubectl describe certificate kibana-tls -n chattingo

# Check certificate secrets
kubectl get secret chattingo-tls-secret -n chattingo
kubectl get secret kibana-tls-secret -n chattingo

# Test certificate validation job
kubectl logs job/validate-tls-certificates -n chattingo
```

### 4. Verify S3 Integration

```bash
# Check S3 uploader deployment
kubectl get deployment s3-uploader -n chattingo

# Check S3 credentials secret
kubectl get secret s3-uploader-credentials -n chattingo

# View S3 uploader logs
kubectl logs deployment/s3-uploader -n chattingo

# Test S3 connectivity (manual trigger)
kubectl create job --from=cronjob/s3-upload-batch s3-test-$(date +%s) -n chattingo
```

## 🌐 HTTPS Access Points

### Secure URLs (HTTPS)

| Service | HTTPS URL | Credentials | Purpose |
|---------|-----------|-------------|---------|
| **Main App** | https://chattingo.local | - | Frontend & API |
| **Kibana** | https://kibana.chattingo.local | admin / kibana123 | Log analysis |
| **Grafana** | https://grafana.chattingo.local | admin / monitor123 | Monitoring |
| **Prometheus** | https://prometheus.chattingo.local | admin / monitor123 | Metrics |

### Port Forwarding (Alternative)

```bash
# Kibana (if ingress issues)
kubectl port-forward -n chattingo svc/kibana 5601:5601
# Access: https://localhost:5601

# Grafana (if ingress issues)  
kubectl port-forward -n chattingo-monitoring svc/grafana-service 3000:3000
# Access: https://localhost:3000
```

## 🔧 Configuration Details

### SSL Certificate Configuration

```yaml
# Main application certificate
commonName: "chattingo.local"
dnsNames:
  - chattingo.local
  - www.chattingo.local
  - api.chattingo.local
  - "*.chattingo.local"
duration: 2160h  # 90 days
renewBefore: 720h  # 30 days before expiry
```

### S3 Upload Configuration

```yaml
# Upload settings
file_patterns: ["*.gz"]  # Only compressed archives
upload_directories: ["archive/"]  # From archive folder only
cleanup:
  max_age_days: 30  # Keep local files 30 days
  delete_after_upload: true  # Clean up after S3 upload
  verify_upload: true  # Verify successful upload
```

## 🛡️ Security Features

### HTTPS/SSL Security

- **TLS 1.2/1.3** protocols only
- **Strong cipher suites** (ECDHE-RSA-AES256)
- **HSTS headers** for browser security
- **Security headers** (XSS, CSRF, Content-Type protection)
- **CSP policies** for content security

### Authentication

```bash
# Kibana credentials
Username: admin
Password: kibana123

# Monitoring credentials  
Username: admin
Password: monitor123

# To change passwords:
htpasswd -nb newuser newpassword | base64
```

### S3 Security

- **IAM user** with minimal S3 permissions
- **Encrypted storage** with server-side encryption
- **Access key rotation** recommended every 90 days
- **VPC endpoint** (can be configured for enhanced security)

## 🔍 Troubleshooting

### Certificate Issues

```bash
# Check cert-manager logs
kubectl logs -n cert-manager deployment/cert-manager

# Check certificate status
kubectl describe certificate chattingo-tls -n chattingo

# Manually trigger certificate renewal
kubectl annotate certificate chattingo-tls -n chattingo cert-manager.io/force-renewal=true

# Check ClusterIssuer status
kubectl describe clusterissuer chattingo-ca-issuer
```

### S3 Upload Issues

```bash
# Check S3 uploader logs
kubectl logs deployment/s3-uploader -n chattingo

# Test AWS credentials
kubectl exec -it deployment/s3-uploader -n chattingo -- aws s3 ls s3://chattingo-logs-secure-2025/

# Check IAM permissions
aws iam get-user --user-name chattingo-s3-logs
aws iam list-attached-user-policies --user-name chattingo-s3-logs
```

### HTTPS Access Issues

```bash
# Check ingress status
kubectl get ingress -A

# Check nginx ingress controller
kubectl logs -n ingress-nginx deployment/ingress-nginx-controller

# Test certificate chain
openssl s_client -connect chattingo.local:443 -servername chattingo.local

# Check DNS resolution
nslookup chattingo.local
```

## 🔄 Maintenance Tasks

### Certificate Management

```bash
# Check certificate expiry dates
kubectl get certificates -A -o custom-columns=NAME:.metadata.name,NAMESPACE:.metadata.namespace,READY:.status.conditions[-1].status,EXPIRY:.status.notAfter

# Renew certificates manually
kubectl annotate certificate --all cert-manager.io/force-renewal=true

# Backup root CA certificate
kubectl get secret chattingo-root-ca-secret -n cert-manager -o yaml > chattingo-root-ca-backup.yaml
```

### S3 Management

```bash
# Check S3 usage and costs
aws s3api list-objects-v2 --bucket chattingo-logs-secure-2025 --query 'Contents[].{Key:Key,Size:Size,Modified:LastModified}' --output table

# Clean up old S3 objects (if needed)
aws s3 rm s3://chattingo-logs-secure-2025/chattingo-logs/2025/08/ --recursive

# Set up S3 lifecycle policies for automatic cleanup
aws s3api put-bucket-lifecycle-configuration --bucket chattingo-logs-secure-2025 --lifecycle-configuration file://s3-lifecycle-policy.json
```

## 🎛️ Monitoring & Alerts

### SSL Certificate Monitoring

```bash
# Check certificate validity in Grafana
certificate_expiry_days = (cert_expiry_timestamp - time()) / 86400

# Prometheus alerts for certificate expiry
- alert: CertificateExpiringSoon
  expr: cert_manager_certificate_expiry_timestamp - time() < 604800  # 7 days
  labels:
    severity: warning
  annotations:
    summary: "SSL certificate expiring soon"
```

### S3 Upload Monitoring

```bash
# Check S3 upload success rate
s3_upload_success_rate = rate(s3_upload_successful_total[5m]) / rate(s3_upload_attempts_total[5m]) * 100

# Monitor S3 costs (AWS CloudWatch)
aws cloudwatch get-metric-statistics --namespace AWS/S3 --metric-name BucketSizeBytes --dimensions Name=BucketName,Value=chattingo-logs-secure-2025
```

## 🚀 Production Readiness

### For Production Deployment

1. **Replace self-signed certificates** with Let's Encrypt:
```yaml
# Use Let's Encrypt instead of self-signed
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-prod
spec:
  acme:
    server: https://acme-v02.api.letsencrypt.org/directory
    email: admin@yourcompany.com
    privateKeySecretRef:
      name: letsencrypt-prod
    solvers:
    - http01:
        ingress:
          class: nginx
```

2. **Implement proper DNS**:
   - Use real domain names instead of `.local`
   - Configure proper DNS records
   - Use external DNS controller

3. **Enhanced S3 Security**:
   - Use IAM roles instead of access keys
   - Enable S3 bucket encryption
   - Set up VPC endpoints
   - Implement bucket policies

4. **Monitoring & Alerting**:
   - Set up proper monitoring dashboards
   - Configure alert notifications (Slack, email, PagerDuty)
   - Implement log retention policies

## 📚 Resources

- [cert-manager Documentation](https://cert-manager.io/docs/)
- [Kubernetes Ingress-NGINX Documentation](https://kubernetes.github.io/ingress-nginx/)
- [AWS S3 Security Best Practices](https://docs.aws.amazon.com/s3/latest/userguide/security-best-practices.html)
- [Let's Encrypt Integration](https://cert-manager.io/docs/configuration/acme/)

---

**Your infrastructure now supports:**
✅ **HTTPS/SSL** with automatic certificate management
✅ **AWS S3 log archival** with Mumbai region
✅ **Secure authentication** for all dashboards  
✅ **Production-ready** certificate infrastructure
✅ **Automated renewals** and monitoring
