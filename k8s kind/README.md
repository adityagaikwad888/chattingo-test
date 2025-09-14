# Chattingo Kubernetes Deployment with Kind

🚀 **Production-ready Kubernetes deployment for Chattingo chat application using Kind cluster**

## 📋 Overview

This repository contains a complete Kubernetes deployment setup for the Chattingo real-time chat application using Kind (Kubernetes in Docker). The deployment includes:

- **Multi-node Kind cluster** with ingress support
- **Spring Boot backend** with WebSocket support
- **React frontend** with Nginx
- **MySQL database** with persistent storage
- **Comprehensive monitoring** with Prometheus and Grafana
- **Auto-scaling** with HPA and VPA
- **SSL/TLS certificates** with cert-manager
- **Production-ready configurations** with proper resource limits, health checks, and security

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────────────────────────────┐
│                                  Kind Cluster                                   │
├─────────────────────────────────────────────────────────────────────────────────┤
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────┐  │
│  │  Control Plane  │  │   Worker Node   │  │   Worker Node   │  │ Worker Node │  │
│  │   (Ingress)     │  │   (Backend)     │  │   (Frontend)    │  │ (Database)  │  │
│  └─────────────────┘  └─────────────────┘  └─────────────────┘  └─────────────┘  │
└─────────────────────────────────────────────────────────────────────────────────┘
                                       │
                              ┌─────────────────┐
                              │   Load Balancer │
                              │     (Ingress)   │
                              └─────────────────┘
                                       │
                              ┌─────────────────┐
                              │   External DNS  │
                              │ chattingo.local │
                              └─────────────────┘
```

## 📁 Project Structure

```
k8s kind/
├── 00-kind-config.yaml           # Kind cluster configuration
├── 00-priority-class.yaml        # Pod priority classes
├── 01-namespace.yaml              # Namespace definitions
├── 02-mysql-pv.yaml               # Persistent volumes for MySQL
├── 04-configmap.yaml              # Application configuration
├── 05-secrets.yaml                # Sensitive data (passwords, keys)
├── 06-mysql-service.yaml          # MySQL service
├── 07-mysql-statefulset.yaml     # MySQL StatefulSet
├── 08-backend-deployment.yaml     # Backend deployment
├── 09-backend-service.yaml        # Backend service
├── 10-frontend-deployment.yaml    # Frontend deployment
├── 11-frontend-service.yaml       # Frontend service
├── 12-ingress.yaml                # Ingress rules
├── 13-hpa.yaml                    # Horizontal Pod Autoscaler
├── 14-vpa.yaml                    # Vertical Pod Autoscaler
├── 15-prometheus.yaml             # Prometheus monitoring
├── 16-grafana.yaml                # Grafana dashboards
├── 17-selfsigned-issuer.yaml      # SSL certificate issuer
├── kustomization.yaml             # Kustomize configuration
├── install-kind-kubectl.sh        # Installation script
├── create-cluster.sh              # Cluster creation script
├── manage-cluster.sh              # Cluster management script
└── README.md                      # This file
```

## 🚀 Quick Start

### Prerequisites

- **Operating System**: Linux (Ubuntu/Debian recommended)
- **RAM**: Minimum 8GB (16GB recommended)
- **CPU**: Minimum 4 cores
- **Disk Space**: 20GB free space
- **Internet**: Required for downloading images

### 1. Install Required Tools

```bash
# Make installation script executable
chmod +x install-kind-kubectl.sh

# Install Kind, kubectl, Docker, and Helm
./install-kind-kubectl.sh

# Reload shell or restart terminal
source ~/.bashrc
```

### 2. Create and Deploy Cluster

```bash
# Make cluster creation script executable
chmod +x create-cluster.sh

# Create Kind cluster and deploy Chattingo
./create-cluster.sh
```

### 3. Access the Application

After successful deployment, access the application at:

- **Frontend**: http://chattingo.local
- **API**: http://chattingo.local/api
- **Grafana**: http://grafana.chattingo.local
  - Username: `admin`
  - Password: `chattingo_grafana_admin_2025`
- **Prometheus**: http://prometheus.chattingo.local

## 🛠️ Management Commands

### Cluster Management

```bash
# Make management script executable
chmod +x manage-cluster.sh

# Check cluster and application status
./manage-cluster.sh status

# View application logs
./manage-cluster.sh logs backend    # Backend logs
./manage-cluster.sh logs frontend   # Frontend logs
./manage-cluster.sh logs mysql      # Database logs
./manage-cluster.sh logs all        # All logs

# Scale components
./manage-cluster.sh scale backend 5    # Scale backend to 5 replicas
./manage-cluster.sh scale frontend 3   # Scale frontend to 3 replicas

# Restart components
./manage-cluster.sh restart backend    # Restart backend
./manage-cluster.sh restart frontend   # Restart frontend
./manage-cluster.sh restart all        # Restart all

# Update application with new images
./manage-cluster.sh update

# Backup data
./manage-cluster.sh backup

# Debug cluster issues
./manage-cluster.sh debug

# Clean up unused resources
./manage-cluster.sh cleanup

# Destroy entire cluster
./manage-cluster.sh destroy
```

### Manual kubectl Commands

```bash
# Check cluster nodes
kubectl get nodes -o wide

# Check all pods
kubectl get pods -A

# Check application pods
kubectl get pods -n chattingo

# Check services
kubectl get services -n chattingo

# Check ingress
kubectl get ingress -n chattingo

# Port forward for direct access
kubectl port-forward svc/frontend-service 3000:80 -n chattingo
kubectl port-forward svc/backend-service 8080:8080 -n chattingo
kubectl port-forward svc/mysql-service 3306:3306 -n chattingo

# Execute commands in pods
kubectl exec -it deployment/chattingo-backend -n chattingo -- bash
kubectl exec -it statefulset/mysql-statefulset -n chattingo -c mysql -- mysql -u root -p

# View logs
kubectl logs -f deployment/chattingo-backend -n chattingo
kubectl logs -f deployment/chattingo-frontend -n chattingo
```

## 🔧 Configuration

### Environment Variables

The application uses ConfigMaps and Secrets for configuration:

**Backend Configuration** (`04-configmap.yaml`):
- Database connection settings
- JWT configuration
- CORS settings
- Logging configuration
- Performance tuning

**Secrets** (`05-secrets.yaml`):
- Database passwords
- JWT secrets
- TLS certificates
- Registry credentials

### Resource Limits

**Backend Pods**:
- CPU: 250m request, 500m limit
- Memory: 512Mi request, 1Gi limit

**Frontend Pods**:
- CPU: 100m request, 200m limit
- Memory: 128Mi request, 256Mi limit

**Database**:
- CPU: 250m request, 500m limit
- Memory: 512Mi request, 1Gi limit
- Storage: 10Gi persistent volume

### Auto-scaling Configuration

**Horizontal Pod Autoscaler (HPA)**:
- Backend: 3-15 replicas (CPU: 70%, Memory: 80%)
- Frontend: 2-8 replicas (CPU: 60%, Memory: 70%)

**Vertical Pod Autoscaler (VPA)**:
- Automatically adjusts resource requests/limits
- Backend: 200m-2000m CPU, 256Mi-4Gi Memory
- Frontend: 50m-500m CPU, 64Mi-512Mi Memory

## 📊 Monitoring and Observability

### Prometheus Metrics

The deployment includes comprehensive monitoring:

- **Application metrics**: Custom business metrics from Spring Boot
- **Infrastructure metrics**: CPU, memory, network, disk usage
- **Database metrics**: MySQL performance, connections, queries
- **Kubernetes metrics**: Pod status, resource usage, events

### Grafana Dashboards

Pre-configured dashboards for:
- Application overview and health
- Request rates and response times
- Database performance
- Infrastructure monitoring
- Custom business metrics

### Alerting Rules

Built-in alerts for:
- Application downtime
- High resource usage
- Database connectivity issues
- Pod crash loops
- Node failures

## 🔒 Security Features

### Network Security
- Network policies for pod-to-pod communication
- Ingress with SSL/TLS termination
- Service mesh ready architecture

### Container Security
- Non-root containers
- Read-only root filesystems where possible
- Security contexts with restricted privileges
- Resource limits and quotas

### Data Security
- Encrypted secrets storage
- TLS certificates for all communications
- Database password encryption
- RBAC for service accounts

## 🚨 Troubleshooting

### Common Issues

**1. Cluster Creation Fails**
```bash
# Check Docker daemon
sudo systemctl status docker

# Check Kind installation
kind version

# Clean up and retry
kind delete cluster --name chattingo-cluster
./create-cluster.sh
```

**2. Pods Stuck in Pending**
```bash
# Check node resources
kubectl describe nodes

# Check pod events
kubectl describe pod <pod-name> -n chattingo

# Check resource quotas
kubectl get resourcequotas -A
```

**3. Application Not Accessible**
```bash
# Check ingress controller
kubectl get pods -n ingress-nginx

# Check DNS resolution
nslookup chattingo.local

# Check ingress rules
kubectl describe ingress chattingo-ingress -n chattingo
```

**4. Database Connection Issues**
```bash
# Check MySQL pod status
kubectl get pods -l app.kubernetes.io/name=mysql -n chattingo

# Test database connectivity
kubectl exec -it deployment/chattingo-backend -n chattingo -- \
  nc -zv mysql-service 3306

# Check database logs
kubectl logs statefulset/mysql-statefulset -n chattingo -c mysql
```

### Debug Commands

```bash
# Get detailed cluster information
./manage-cluster.sh debug

# Check resource usage
kubectl top nodes
kubectl top pods -n chattingo

# View recent events
kubectl get events --sort-by=.metadata.creationTimestamp -n chattingo

# Describe problematic resources
kubectl describe pod <pod-name> -n chattingo
kubectl describe service <service-name> -n chattingo
```

## 🔄 CI/CD Integration

### Building Images

```bash
# Build backend image
cd ../backend
docker build -t chattingo/backend:v1.0.0 .

# Build frontend image
cd ../frontend
docker build -t chattingo/frontend:v1.0.0 .

# Load images into Kind cluster
kind load docker-image chattingo/backend:v1.0.0 --name chattingo-cluster
kind load docker-image chattingo/frontend:v1.0.0 --name chattingo-cluster
```

### Deployment Updates

```bash
# Update with new image tags
kubectl set image deployment/chattingo-backend \
  chattingo-backend=chattingo/backend:v1.0.0 -n chattingo

kubectl set image deployment/chattingo-frontend \
  chattingo-frontend=chattingo/frontend:v1.0.0 -n chattingo

# Wait for rollout completion
kubectl rollout status deployment/chattingo-backend -n chattingo
kubectl rollout status deployment/chattingo-frontend -n chattingo
```

## 📈 Performance Optimization

### Resource Optimization
- **JVM tuning**: Optimized heap sizes and garbage collection
- **Connection pooling**: Database connection optimization
- **Caching**: Application-level caching strategies
- **Compression**: Gzip compression for static assets

### Scaling Strategies
- **Horizontal scaling**: Auto-scaling based on metrics
- **Vertical scaling**: Resource optimization per pod
- **Database scaling**: Read replicas and connection pooling
- **CDN integration**: Static asset optimization

## 🌟 Production Considerations

### High Availability
- Multi-node cluster setup
- Pod anti-affinity rules
- Database replication (can be configured)
- Load balancing across multiple zones

### Backup and Recovery
- Automated database backups
- Configuration backup
- Disaster recovery procedures
- Point-in-time recovery

### Monitoring and Alerting
- 24/7 monitoring setup
- Alert escalation procedures
- Performance baseline establishment
- Capacity planning metrics

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## 📝 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🆘 Support

For support and questions:
- **Email**: adityagaikwad888@gmail.com
- **Issues**: Create a GitHub issue
- **Documentation**: Check the inline comments in configuration files

## 🎉 Acknowledgments

- Kubernetes community for excellent documentation
- Kind project for local Kubernetes development
- Spring Boot and React communities
- Prometheus and Grafana for monitoring solutions

---

**Happy Deploying! 🚀**

> Built with ❤️ for the Hackathon by Chattingo Team
