# 🏆 Chattingo Hackathon Deployment Guide

## 🎯 System Specifications
- **CPU**: 2 vCPU cores
- **RAM**: 8GB total (6GB available after Jenkins/SonarQube)
- **Storage**: 100GB NVMe (fast!)
- **Expected Traffic**: 2-3 concurrent users
- **Environment**: Hackathon (development/demo)

## 📊 Resource Allocation Plan

### Memory Distribution (6GB Available)
| Service | Memory Request | Memory Limit | Purpose |
|---------|---------------|--------------|---------|
| **Backend** | 512Mi | 1Gi | Spring Boot API |
| **MySQL** | 512Mi | 1Gi | Database |
| **Elasticsearch** | 1Gi | 1.5Gi | Log storage |
| **Kibana** | 384Mi | 512Mi | Log visualization |
| **Frontend** | 128Mi | 256Mi | React app |
| **Prometheus** | 384Mi | 512Mi | Monitoring |
| **Grafana** | 256Mi | 384Mi | Dashboards |
| **Filebeat** | 128Mi | 256Mi | Log shipping |
| **Others** | 256Mi | 512Mi | SSL, S3, etc. |
| **Total** | ~3.6Gi | ~6Gi | **Perfect fit!** |

### Storage Allocation (100GB NVMe)
| Component | Size | Type | Purpose |
|-----------|------|------|---------|
| **MySQL Data** | 20GB | PV | Database storage |
| **Elasticsearch** | 15GB | PV | Log indices |
| **Application Logs** | 10GB | PV | Structured logs |
| **System Reserve** | 55GB | Host | OS, images, temp |

## 🚀 Quick Deployment

### 1. Deploy Hackathon-Optimized Configuration

```bash
# Use the hackathon-optimized configuration
kubectl apply -k . -f kustomization-hackathon.yaml

# Or if you prefer the base config (it will still work fine)
kubectl apply -k .

# Check deployment status
kubectl get pods -n chattingo
kubectl get pods -n chattingo-monitoring
```

### 2. Monitor Resource Usage

```bash
# Check real-time resource usage
kubectl top nodes
kubectl top pods -n chattingo
kubectl top pods -n chattingo-monitoring

# Check memory usage specifically
kubectl describe nodes | grep -A 5 "Allocated resources"
```

### 3. Access Your Services

```bash
# Add to /etc/hosts
sudo tee -a /etc/hosts << EOF
127.0.0.1 chattingo.local
127.0.0.1 kibana.chattingo.local
127.0.0.1 grafana.chattingo.local
EOF

# Access URLs
echo "🏠 Main App: https://chattingo.local"
echo "📊 Kibana: https://kibana.chattingo.local (admin/kibana123)"
echo "📈 Grafana: https://grafana.chattingo.local (admin/monitor123)"
```

## ⚡ Performance Optimizations Applied

### Backend Optimizations
- **Single replica** (perfect for 2-3 users)
- **768MB JVM heap** (fits in 1GB limit)
- **G1GC collector** for low-latency
- **Reduced thread pools** (2-5 threads vs 10-50)

### Database Optimizations
- **256MB InnoDB buffer pool** (optimal for 1GB limit)
- **50 max connections** (more than enough for hackathon)
- **32MB query cache** for fast repeated queries
- **Disabled slow query log** (saves I/O)

### Elasticsearch Optimizations
- **Single node cluster** (no replication overhead)
- **512MB JVM heap** (fits in 1.5GB limit)
- **0 replicas** for indices (single node anyway)
- **30s refresh interval** (less frequent indexing)

### Logging Optimizations
- **Reduced log levels** (ERROR for Hibernate, WARN for Security)
- **3-day retention** vs 7-day default
- **6-hour S3 uploads** vs 2-hour default
- **50MB rotation** vs 100MB default

## 🎯 Expected Performance

### Response Times
- **API calls**: < 200ms (NVMe storage helps!)
- **Page loads**: < 2 seconds
- **WebSocket**: Real-time
- **Database queries**: < 50ms (optimized MySQL)

### Concurrent Users
- **Comfortable**: 2-3 users (as planned)
- **Maximum**: 8-10 users (with some slowdown)
- **Database connections**: 50 available

### Resource Utilization
- **RAM usage**: ~4-5GB (leaving 1-2GB buffer)
- **CPU usage**: ~30-50% average
- **Storage**: ~45GB used (55GB free)

## 🔧 Troubleshooting

### If Memory is Tight
```bash
# Reduce Elasticsearch memory
kubectl patch deployment elasticsearch -n chattingo -p '{"spec":{"template":{"spec":{"containers":[{"name":"elasticsearch","resources":{"requests":{"memory":"512Mi"},"limits":{"memory":"1Gi"}}}]}}}}'

# Reduce JVM heap for backend
kubectl patch deployment chattingo-backend -n chattingo -p '{"spec":{"template":{"spec":{"containers":[{"name":"chattingo-backend","env":[{"name":"JAVA_OPTS","value":"-Xmx512m -Xms256m -XX:+UseG1GC"}]}]}}}}'
```

### If CPU is High
```bash
# Check what's consuming CPU
kubectl top pods --sort-by=cpu -n chattingo

# Reduce background processes
kubectl scale deployment s3-uploader --replicas=0 -n chattingo  # Disable S3 uploads temporarily
kubectl patch cronjob log-rotation -n chattingo -p '{"spec":{"suspend":true}}'  # Pause log rotation
```

### If Storage Fills Up
```bash
# Check storage usage
df -h

# Clean up old logs manually
kubectl exec -it deployment/chattingo-backend -n chattingo -- find /var/log/chattingo -name "*.log" -size +10M -delete

# Reduce log retention
kubectl patch configmap chattingo-backend-config -n chattingo -p '{"data":{"LOG_ROTATION_MAX_AGE_DAYS":"1"}}'
```

## 📊 Monitoring Commands

### Resource Monitoring
```bash
# Real-time resource usage
watch kubectl top pods -n chattingo

# Memory usage breakdown
kubectl describe nodes | grep -A 10 "Allocated resources"

# Storage usage
kubectl exec -it deployment/chattingo-backend -n chattingo -- df -h
```

### Application Health
```bash
# Check all services
kubectl get pods -n chattingo -o wide
kubectl get pods -n chattingo-monitoring -o wide

# Health checks
curl -k https://chattingo.local/actuator/health
curl -k https://kibana.chattingo.local/api/status
```

### Log Analysis
```bash
# Check application logs
kubectl logs -f deployment/chattingo-backend -n chattingo

# Check resource logs
kubectl logs -f deployment/elasticsearch -n chattingo
kubectl logs -f deployment/mysql -n chattingo
```

## 🎉 Hackathon Success Tips

1. **Pre-warm services**: Access all URLs once to load everything into memory
2. **Monitor resources**: Keep `kubectl top pods` running in a terminal
3. **Prepare demos**: Create sample data before judging time
4. **Have backups**: Keep port-forward commands ready if ingress fails
5. **Test everything**: Verify all features work before presenting

## 🔧 Emergency Commands

```bash
# Quick restart if something goes wrong
kubectl rollout restart deployment/chattingo-backend -n chattingo
kubectl rollout restart deployment/chattingo-frontend -n chattingo

# Scale down if resources are tight
kubectl scale deployment elasticsearch --replicas=0 -n chattingo  # Disable logging temporarily
kubectl scale deployment grafana --replicas=0 -n chattingo-monitoring  # Disable monitoring

# Port forward if ingress fails
kubectl port-forward svc/frontend-service 3000:80 -n chattingo &
kubectl port-forward svc/backend-service 8080:8080 -n chattingo &
```

---

**Your hackathon setup is optimized for:**
✅ **Full functionality** with all logging and monitoring
✅ **Fast performance** on NVMe storage
✅ **Efficient resource usage** within 6GB RAM limit
✅ **Easy troubleshooting** with simple commands
✅ **Professional presentation** with HTTPS and dashboards

**Good luck with your hackathon!** 🚀
