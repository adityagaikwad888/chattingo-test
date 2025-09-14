# Chattingo Deployment Guide

This guide covers deploying Chattingo with the **separated S3 upload architecture** where:
- **Application runs in Kubernetes** (or Docker containers)
- **S3 upload service runs on host machine**

## 🏗️ Architecture Overview

```
┌─────────────────────────────────────────────────────────────────────┐
│                         HOST MACHINE                                │
│                                                                     │
│  ┌─────────────────────────┐    ┌─────────────────────────────────┐ │
│  │     Kubernetes/Docker   │    │       S3 Upload Service        │ │
│  │                         │    │                                 │ │
│  │  ┌─────────────────────┐│    │  ┌─────────────────────────────┐│ │
│  │  │   Chattingo Pods    ││────┼─▶│  /var/log/chattingo/*       ││ │
│  │  │   - Backend         ││    │  │  - app/                     ││ │
│  │  │   - Frontend        ││    │  │  - auth/                    ││ │
│  │  │   - MySQL           ││    │  │  - chat/                    ││ │
│  │  │   - Elasticsearch   ││    │  │  - error/                   ││ │
│  │  └─────────────────────┘│    │  │  - system/                  ││ │
│  └─────────────────────────┘    │  │  - websocket/               ││ │
│                                 │  └─────────────────────────────┘│ │
│                                 │              │                  │ │
│                                 │              ▼                  │ │
│                                 │  ┌─────────────────────────────┐│ │
│                                 │  │        AWS S3               ││ │
│                                 │  │    chattingo-logs/          ││ │
│                                 │  └─────────────────────────────┘│ │
│                                 └─────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────────┘
```

## 📋 Prerequisites

1. **Host Machine Requirements:**
   - Linux/Ubuntu (or any Docker-capable OS)
   - Docker & Kubernetes (kind, minikube, or full cluster)
   - Python 3.8+
   - AWS CLI configured

2. **AWS Requirements:**
   - S3 bucket created: `chattingo-logs`
   - IAM permissions for S3 upload
   - AWS credentials configured

## 🚀 Quick Start

### Step 1: Setup S3 Upload Service (Host)

```bash
# Navigate to s3-upload directory
cd s3-upload/

# Install dependencies
pip3 install -r requirements.txt

# Configure AWS credentials
aws configure

# Update configuration
vim config/settings.yaml

# Install as systemd service
sudo ./scripts/install-service.sh

# Start the service
sudo systemctl start s3-uploader
sudo systemctl enable s3-uploader

# Check status
sudo systemctl status s3-uploader
```

### Step 2: Deploy Application (Kubernetes)

```bash
# For development with Docker Compose
cd backend/
docker-compose up -d

# For production with Kubernetes
# (Create your K8s manifests based on docker-compose.yml)
kubectl apply -f k8s-manifests/
```

### Step 3: Verify Setup

```bash
# Test S3 uploader
cd s3-upload/
sudo ./scripts/test-uploader.sh

# Check application logs
kubectl logs -f deployment/chattingo-backend

# Check S3 uploader logs
sudo journalctl -u s3-uploader -f

# Verify S3 uploads
aws s3 ls s3://chattingo-logs/ --recursive
```

## ⚙️ Configuration

### S3 Uploader Configuration

Edit `s3-upload/config/settings.yaml`:

```yaml
log_path: "/var/log/chattingo"
s3:
  bucket_name: "your-bucket-name"
  region: "us-east-1"
cleanup:
  max_age_days: 7
  delete_after_upload: true
schedule:
  check_interval_minutes: 30
```

### Application Configuration

The containerized app only handles local log rotation. Key settings in `application.properties`:

```properties
# Local log rotation only
log.rotation.enabled=true
log.rotation.max-age-days=7
log.rotation.max-size-mb=100
log.path=/app/logs
```

## 🔧 Kubernetes Volume Mapping

Ensure your Kubernetes pods mount the log directory to the host:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: chattingo-backend
spec:
  template:
    spec:
      containers:
      - name: chattingo-backend
        image: chattingo-backend:latest
        volumeMounts:
        - name: log-volume
          mountPath: /app/logs
      volumes:
      - name: log-volume
        hostPath:
          path: /var/log/chattingo
          type: DirectoryOrCreate
```

## 🐳 Docker Compose (Development)

For local development, ensure the volume mapping exists:

```yaml
services:
  chattingo-backend:
    volumes:
      - /var/log/chattingo:/app/logs  # Map to host directory
```

## 📊 Monitoring

### Check S3 Upload Service

```bash
# Service status
sudo systemctl status s3-uploader

# Live logs
sudo journalctl -u s3-uploader -f

# Service metrics
sudo journalctl -u s3-uploader --since "1 hour ago" | grep "Upload cycle completed"
```

### Check Application Logs

```bash
# Container logs
docker logs chattingo-backend

# Kubernetes logs
kubectl logs -f deployment/chattingo-backend

# Host log files
ls -la /var/log/chattingo/
```

### Verify S3 Uploads

```bash
# List recent uploads
aws s3 ls s3://chattingo-logs/ --recursive --human-readable

# Check specific date
aws s3 ls s3://chattingo-logs/2025/09/09/ --recursive
```

## 🛠️ Troubleshooting

### S3 Upload Issues

1. **Check AWS credentials:**
   ```bash
   aws sts get-caller-identity
   ```

2. **Check S3 bucket permissions:**
   ```bash
   aws s3 ls s3://chattingo-logs/
   ```

3. **Check service logs:**
   ```bash
   sudo journalctl -u s3-uploader -n 50
   ```

### Container Issues

1. **Check volume mounts:**
   ```bash
   docker exec chattingo-backend ls -la /app/logs
   ```

2. **Check log rotation:**
   ```bash
   docker exec chattingo-backend tail -f /app/logs/app/application.log
   ```

### Kubernetes Issues

1. **Check volume mounts:**
   ```bash
   kubectl exec -it deployment/chattingo-backend -- ls -la /app/logs
   ```

2. **Check hostPath permissions:**
   ```bash
   sudo ls -la /var/log/chattingo/
   ```

## 🔄 Log Flow

1. **Application writes logs** → `/app/logs/` (inside container)
2. **Volume mount maps** → `/var/log/chattingo/` (on host)
3. **App rotates & compresses** → `*.log.gz` files created
4. **S3 service finds** → compressed files every 30 minutes
5. **S3 service uploads** → files to S3 with date partitioning
6. **S3 service cleans up** → deletes local files after successful upload

## 💡 Benefits of This Architecture

- ✅ **No AWS credentials in containers**
- ✅ **Kubernetes-friendly deployment**
- ✅ **Independent scaling of app and S3 service**
- ✅ **Simple troubleshooting**
- ✅ **Cost-effective (no data transfer between nodes)**
- ✅ **No S3 Glacier complexity**
