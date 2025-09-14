# Chattingo Kubernetes Logging Infrastructure

## 🏗️ Overview

This document describes the comprehensive logging infrastructure for the Chattingo chat application deployed on Kubernetes. The system implements the **ELK Stack** (Elasticsearch, Logstash/Filebeat, Kibana) with **automated log rotation**, **S3 archival**, and **comprehensive monitoring**.

## 📋 Components

### Core ELK Stack

| Component | Purpose | Kubernetes Resource | Port | Storage |
|-----------|---------|-------------------|------|---------|
| **Elasticsearch** | Log storage & indexing | Deployment | 9200, 9300 | 10Gi PV |
| **Kibana** | Log visualization | Deployment | 5601 | - |
| **Filebeat** | Log shipping & processing | DaemonSet | - | Host volumes |

### Log Management Services

| Service | Purpose | Schedule | Storage |
|---------|---------|----------|---------|
| **Log Rotation** | Compress & archive logs | Every hour | 5Gi shared PV |
| **S3 Uploader** | Archive to cloud storage | Every 2 hours | AWS S3 |
| **Setup Jobs** | Initialize log structure | One-time | - |

### Monitoring & Alerting

| Component | Purpose | Dashboard | Alerts |
|-----------|---------|-----------|--------|
| **Grafana Dashboards** | Log metrics visualization | 2 dashboards | ✅ |
| **Prometheus Rules** | Log infrastructure alerts | 6 rules | ✅ |
| **ServiceMonitors** | Metrics collection | 3 monitors | ✅ |

## 🚀 Quick Start

### 1. Prerequisites

```bash
# Ensure you have a running Kind cluster
kind create cluster --config=00-kind-config.yaml

# Install necessary operators
kubectl apply -f https://github.com/prometheus-operator/prometheus-operator/releases/download/v0.68.0/bundle.yaml
```

### 2. Deploy Logging Infrastructure

```bash
# Deploy all logging components
kubectl apply -k .

# Wait for all pods to be ready
kubectl wait --for=condition=ready pod -l tier=logging --timeout=300s

# Check the deployment status
kubectl get pods -n chattingo -l tier=logging
```

### 3. Verify Services

```bash
# Check Elasticsearch health
kubectl exec -n chattingo deployment/elasticsearch -- curl -s http://localhost:9200/_cluster/health

# Check Kibana status
kubectl port-forward -n chattingo svc/kibana 5601:5601 &
curl -s http://localhost:5601/api/status

# Check Filebeat harvesting
kubectl logs -n chattingo daemonset/filebeat --tail=50
```

## 📂 Log Directory Structure

The system creates and manages the following log directory structure:

```
/var/log/chattingo/
├── app/                    # Application logs
│   └── application.log
├── auth/                   # Authentication logs  
│   └── auth.log
├── chat/                   # Chat & messaging logs
│   └── chat.log
├── error/                  # Error logs
│   └── error.log
├── system/                 # System logs
│   └── system.log
├── websocket/              # WebSocket logs
│   └── websocket.log
├── elasticsearch/          # Elasticsearch logs
├── kibana/                 # Kibana logs
├── filebeat/              # Filebeat logs
└── archive/               # Rotated & compressed logs
    ├── app_application_20250910_120000.log.gz
    ├── auth_auth_20250910_120000.log.gz
    └── ...
```

## 🔄 Log Rotation & Retention

### Automatic Rotation

The system automatically rotates logs based on:

- **Size Threshold**: 100MB per file (configurable)
- **Age Threshold**: 7 days (configurable)  
- **Schedule**: Every hour at minute 30
- **Compression**: Gzip compression enabled

### Configuration

```yaml
# In log-rotation ConfigMap
env:
- name: MAX_AGE_DAYS
  value: "7"                    # Rotate after 7 days
- name: MAX_SIZE_MB  
  value: "100"                  # Rotate after 100MB
- name: COMPRESSION_ENABLED
  value: "true"                 # Enable gzip compression
```

### Manual Rotation

```bash
# Trigger manual log rotation
kubectl create job -n chattingo --from=cronjob/log-rotation manual-rotation-$(date +%s)

# Check rotation status
kubectl logs -n chattingo job/manual-rotation-xxxxx
```

## ☁️ S3 Archival System

### Configuration

```yaml
# S3 Uploader Configuration
s3:
  bucket_name: "chattingo-logs"
  region: "us-east-1"
  storage_class: "STANDARD_IA"      # Cost-optimized storage

upload:
  file_patterns: ["*.gz"]           # Only upload compressed files
  upload_directories: ["archive/"]  # Only from archive directory
  
cleanup:
  max_age_days: 30                  # Keep local archives for 30 days
  delete_after_upload: true         # Clean up after successful upload
```

### AWS Credentials Setup

```bash
# Create secret with AWS credentials
kubectl create secret generic s3-uploader-credentials \
  --from-literal=AWS_ACCESS_KEY_ID=your-access-key \
  --from-literal=AWS_SECRET_ACCESS_KEY=your-secret-key \
  -n chattingo

# Or use IAM roles for service accounts (IRSA) - recommended
kubectl annotate serviceaccount s3-uploader \
  eks.amazonaws.com/role-arn=arn:aws:iam::ACCOUNT:role/ChattingoS3Role \
  -n chattingo
```

### S3 Bucket Structure

```
chattingo-logs/
└── 2025/
    └── 09/
        └── 10/
            ├── archive/
            │   ├── app_application_20250910_120000.log.gz
            │   ├── auth_auth_20250910_120000.log.gz
            │   └── chat_chat_20250910_120000.log.gz
            └── metadata/
                └── upload_manifest.json
```

## 📊 Monitoring & Dashboards

### Grafana Dashboards

1. **Chattingo Logs Overview**
   - Log volume by category
   - Error rate trends
   - Elasticsearch index status
   - Recent critical errors

2. **ELK Stack Monitoring**
   - Elasticsearch cluster health
   - JVM memory usage
   - Filebeat event rates
   - Kibana response times

### Key Metrics

```promql
# Log ingestion rate
rate(filebeat_events_total[5m])

# Error rate by category
rate(filebeat_events_total{category="error"}[5m])

# Elasticsearch cluster health
elasticsearch_cluster_health_status

# Log directory disk usage
(node_filesystem_size_bytes{mountpoint="/var/log/chattingo"} - node_filesystem_avail_bytes{mountpoint="/var/log/chattingo"}) / node_filesystem_size_bytes{mountpoint="/var/log/chattingo"} * 100
```

### Alerts

| Alert | Condition | Severity | Action Required |
|-------|-----------|----------|----------------|
| **ElasticsearchClusterDown** | Cluster unhealthy > 5min | Critical | Check ES pods |
| **HighErrorRate** | >10 errors/sec for 2min | Warning | Check application |
| **LogVolumeSpike** | >1000 events/sec for 5min | Warning | Check for issues |
| **LogRotationFailed** | Rotation job failed | Warning | Check disk space |
| **S3UploaderDown** | No replicas available | Warning | Check AWS creds |
| **LogDiskSpaceHigh** | >80% disk usage | Warning | Increase storage |

## 🔍 Kibana Usage

### Access Kibana

```bash
# Port forward to access Kibana
kubectl port-forward -n chattingo svc/kibana 5601:5601

# Open browser to http://localhost:5601
```

### Index Patterns

The system automatically creates index patterns:

- `chattingo-application-*` - Application logs
- `chattingo-authentication-*` - Auth logs  
- `chattingo-chat-*` - Chat logs
- `chattingo-error-*` - Error logs
- `chattingo-system-*` - System logs
- `chattingo-websocket-*` - WebSocket logs

### Common Queries

```json
// Find all errors in the last hour
{
  "query": {
    "bool": {
      "must": [
        {"match": {"category": "error"}},
        {"range": {"@timestamp": {"gte": "now-1h"}}}
      ]
    }
  }
}

// Find authentication failures
{
  "query": {
    "bool": {
      "must": [
        {"match": {"category": "authentication"}},
        {"match": {"message": "login failed"}}
      ]
    }
  }
}

// Find chat messages for specific user
{
  "query": {
    "bool": {
      "must": [
        {"match": {"category": "chat"}},
        {"match": {"user_id": "12345"}}
      ]
    }
  }
}
```

## 🛠️ Troubleshooting

### Common Issues

#### 1. Elasticsearch Won't Start

```bash
# Check pod status
kubectl describe pod -n chattingo -l app=elasticsearch

# Common fixes:
# - Increase vm.max_map_count on nodes
kubectl exec -it node-name -- sysctl -w vm.max_map_count=262144

# - Check persistent volume permissions
kubectl exec -it -n chattingo deployment/elasticsearch -- ls -la /usr/share/elasticsearch/data
```

#### 2. Filebeat Not Harvesting

```bash
# Check Filebeat logs
kubectl logs -n chattingo daemonset/filebeat --tail=100

# Check log file permissions
kubectl exec -it -n chattingo pod-name -- ls -la /var/log/chattingo/

# Restart Filebeat
kubectl rollout restart daemonset/filebeat -n chattingo
```

#### 3. S3 Upload Failures

```bash
# Check S3 uploader logs
kubectl logs -n chattingo deployment/s3-uploader

# Verify AWS credentials
kubectl get secret s3-uploader-credentials -n chattingo -o yaml

# Test S3 connectivity
kubectl exec -it -n chattingo deployment/s3-uploader -- aws s3 ls s3://chattingo-logs/
```

#### 4. Log Rotation Issues

```bash
# Check rotation job status
kubectl get jobs -n chattingo -l app=log-rotation

# Check rotation logs
kubectl logs -n chattingo job/log-rotation-xxxxx

# Manual cleanup
kubectl exec -it -n chattingo deployment/chattingo-backend -- find /var/log/chattingo -name "*.log" -size +100M
```

## 🔧 Maintenance

### Regular Tasks

#### Daily
- Monitor disk usage
- Check alert notifications
- Verify S3 uploads

#### Weekly  
- Review log retention policies
- Clean up old Kubernetes jobs
- Update Elasticsearch indices

#### Monthly
- Review and optimize Kibana dashboards
- Analyze log patterns and volumes
- Update log retention policies
- Review S3 storage costs

### Scaling Considerations

#### Elasticsearch Scaling

```yaml
# For production, consider StatefulSet with multiple replicas
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: elasticsearch
spec:
  replicas: 3                    # Scale to 3 nodes
  serviceName: elasticsearch-headless
```

#### Filebeat Resource Scaling

```yaml
# Adjust resources based on log volume
resources:
  requests:
    memory: 200Mi
    cpu: 200m
  limits:
    memory: 500Mi
    cpu: 500m
```

## 💰 Cost Optimization

### S3 Storage Classes

```yaml
# Use appropriate storage class
StorageClass: "STANDARD_IA"      # For infrequent access
# StorageClass: "GLACIER"        # For long-term archival
# StorageClass: "DEEP_ARCHIVE"   # For compliance/audit logs
```

### Log Retention Policies

```yaml
# Adjust retention based on requirements
MAX_AGE_DAYS: "3"               # Reduce for development
MAX_AGE_DAYS: "30"              # Standard for production  
MAX_AGE_DAYS: "90"              # Extended for compliance
```

## 🔐 Security Considerations

### Network Security
- All services use ClusterIP (internal only)
- TLS termination at ingress level
- Network policies restrict inter-pod communication

### Data Security
- Logs may contain sensitive information
- S3 bucket uses server-side encryption
- RBAC controls access to log data

### Access Controls
- Kibana access through ingress with authentication
- Elasticsearch API not exposed externally
- Log files readable only by application pods

## 📚 References

- [Elasticsearch Documentation](https://www.elastic.co/guide/en/elasticsearch/reference/current/)
- [Kibana User Guide](https://www.elastic.co/guide/en/kibana/current/)
- [Filebeat Reference](https://www.elastic.co/guide/en/beats/filebeat/current/)
- [Kubernetes Logging Architecture](https://kubernetes.io/docs/concepts/cluster-administration/logging/)
- [Prometheus Monitoring](https://prometheus.io/docs/)

---

**Note**: This logging infrastructure is designed for production use with comprehensive monitoring, alerting, and data retention policies. Adjust configurations based on your specific requirements and compliance needs.
