# Chattingo S3 Log Upload Service

This service runs on the **host machine** to upload compressed log files from `/var/log/chattingo/*` to S3.

## Architecture

```
┌─────────────────────┐    ┌─────────────────────┐    ┌─────────────────────┐
│   Kubernetes Pod    │    │    Host Machine     │    │        AWS S3       │
│                     │    │                     │    │                     │
│  ┌─────────────────┐│    │  ┌─────────────────┐│    │  ┌─────────────────┐│
│  │ Chattingo App   ││────▶  │ /var/log/       ││────▶  │ chattingo-logs/ ││
│  │ (Log Rotation)  ││    │  │ chattingo/      ││    │  │                 ││
│  └─────────────────┘│    │  │                 ││    │  └─────────────────┘│
│                     │    │  │ ┌─────────────┐ ││    │                     │
└─────────────────────┘    │  │ │S3 Upload Svc││    │                     │
                           │  │ │(This folder)││    │                     │
                           │  │ └─────────────┘ ││    │                     │
                           │  └─────────────────┘│    │                     │
                           └─────────────────────┘    └─────────────────────┘
```

## Why Host-Based Upload?

1. **Kubernetes-friendly**: No S3 credentials in container images
2. **Simpler deployment**: S3 service runs independently of app lifecycle
3. **Better security**: AWS credentials only on host, not in cluster
4. **Cost-effective**: No data transfer between nodes and S3

## Files

- `s3-uploader.py` - Main Python script for log upload
- `s3-uploader.service` - Systemd service file
- `requirements.txt` - Python dependencies  
- `config/` - Configuration files
- `scripts/` - Setup and management scripts

## Setup

1. Install dependencies: `pip install -r requirements.txt`
2. Configure AWS credentials: `aws configure`
3. Update configuration in `config/settings.yaml`
4. Install systemd service: `sudo ./scripts/install-service.sh`
5. Start service: `sudo systemctl start s3-uploader`

## Simple Approach

- **No Glacier transfers** - just standard S3 storage
- **Automatic cleanup** - delete files after successful upload
- **Simple configuration** - minimal settings required
