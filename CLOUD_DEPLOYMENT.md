# 🐳 Docker Build & Cloud Deployment Guide

## 🚀 Building & Pushing Docker Images

### Prerequisites
1. **Docker installed and running**
2. **Docker Hub account** (you have: `adityagaikwad888`)
3. **Git repository access**

### Step 1: Login to Docker Hub

```bash
# Login to Docker Hub
docker login

# Enter your credentials:
# Username: adityagaikwad888
# Password: [your-docker-hub-password]
```

### Step 2: Build All Images

```bash
# Navigate to project root
cd "/home/ubuntu/Desktop/TWS - Hackathon"

# Build all images locally (test first)
./build-and-push.sh v1.0.0

# Build and push to Docker Hub
./build-and-push.sh v1.0.0 push
```

### Step 3: Docker Hub Repositories to Create

You'll need to create these repositories on Docker Hub:

1. **chattingo-backend** - Spring Boot API
2. **chattingo-frontend** - React application  
3. **chattingo-s3-uploader** - Log archival service
4. **chattingo-log-processor** - Custom log processing

#### Create Repositories:
```bash
# Go to https://hub.docker.com
# Click "Create Repository"
# Repository names:
# - adityagaikwad888/chattingo-backend
# - adityagaikwad888/chattingo-frontend  
# - adityagaikwad888/chattingo-s3-uploader
# - adityagaikwad888/chattingo-log-processor
```

### Step 4: Manual Build Commands (Alternative)

```bash
# Backend
cd backend
docker build -t adityagaikwad888/chattingo-backend:v1.0.0 .
docker push adityagaikwad888/chattingo-backend:v1.0.0

# Frontend  
cd ../frontend
docker build -t adityagaikwad888/chattingo-frontend:v1.0.0 .
docker push adityagaikwad888/chattingo-frontend:v1.0.0

# S3 Uploader
cd ../s3-upload
docker build -t adityagaikwad888/chattingo-s3-uploader:v1.0.0 .
docker push adityagaikwad888/chattingo-s3-uploader:v1.0.0

# Log Processor
cd ../backend/log-processor
docker build -t adityagaikwad888/chattingo-log-processor:v1.0.0 .
docker push adityagaikwad888/chattingo-log-processor:v1.0.0
```

## ☁️ Cloud Deployment Options

### Option 1: Google Cloud Platform (GKE)

#### Setup GKE Cluster
```bash
# Install gcloud CLI
curl https://sdk.cloud.google.com | bash
exec -l $SHELL
gcloud init

# Create GKE cluster
gcloud container clusters create chattingo-cluster \
    --zone=us-central1-a \
    --num-nodes=3 \
    --machine-type=e2-standard-2 \
    --disk-size=50GB \
    --enable-autorepair \
    --enable-autoupgrade

# Get credentials
gcloud container clusters get-credentials chattingo-cluster --zone=us-central1-a
```

#### Deploy to GKE
```bash
# Update image references in manifests
find k8s-kind/ -name "*.yaml" -exec sed -i 's|image: chattingo-backend|image: adityagaikwad888/chattingo-backend:v1.0.0|g' {} \;
find k8s-kind/ -name "*.yaml" -exec sed -i 's|image: chattingo-frontend|image: adityagaikwad888/chattingo-frontend:v1.0.0|g' {} \;

# Deploy
kubectl apply -k k8s-kind/

# Get external IP
kubectl get service nginx-ingress-controller -n ingress-nginx
```

### Option 2: Amazon EKS

#### Setup EKS Cluster
```bash
# Install eksctl
curl --location "https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_$(uname -s)_amd64.tar.gz" | tar xz -C /tmp
sudo mv /tmp/eksctl /usr/local/bin

# Create EKS cluster
eksctl create cluster \
    --name chattingo-cluster \
    --region us-west-2 \
    --nodes 3 \
    --node-type t3.medium \
    --managed

# Update kubeconfig
aws eks update-kubeconfig --region us-west-2 --name chattingo-cluster
```

### Option 3: Azure AKS

#### Setup AKS Cluster
```bash
# Install Azure CLI
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
az login

# Create resource group
az group create --name chattingo-rg --location eastus

# Create AKS cluster
az aks create \
    --resource-group chattingo-rg \
    --name chattingo-cluster \
    --node-count 3 \
    --node-vm-size Standard_B2s \
    --generate-ssh-keys

# Get credentials
az aks get-credentials --resource-group chattingo-rg --name chattingo-cluster
```

### Option 4: DigitalOcean Kubernetes (Cost-Effective)

#### Setup DOKS Cluster
```bash
# Install doctl
snap install doctl
doctl auth init

# Create cluster
doctl kubernetes cluster create chattingo-cluster \
    --region nyc1 \
    --size s-2vcpu-4gb \
    --count 3 \
    --auto-upgrade \
    --surge-upgrade

# Get credentials
doctl kubernetes cluster kubeconfig save chattingo-cluster
```

## 🔧 Update Kubernetes Manifests for Cloud

Create cloud-specific kustomization:

```bash
# Create cloud overlay
mkdir -p k8s-kind/overlays/cloud
```

Create `k8s-kind/overlays/cloud/kustomization.yaml`:

```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

namespace: chattingo

resources:
  - ../../base

# Update images to use Docker Hub
images:
  - name: chattingo-backend
    newName: adityagaikwad888/chattingo-backend
    newTag: v1.0.0
  - name: chattingo-frontend  
    newName: adityagaikwad888/chattingo-frontend
    newTag: v1.0.0
  - name: chattingo-s3-uploader
    newName: adityagaikwad888/chattingo-s3-uploader
    newTag: v1.0.0
  - name: log-processor
    newName: adityagaikwad888/chattingo-log-processor
    newTag: v1.0.0

# Cloud-specific patches
patchesStrategicMerge:
  - cloud-patches.yaml

# Add LoadBalancer service
patches:
  - target:
      kind: Service
      name: nginx-ingress-controller
    patch: |-
      - op: replace
        path: /spec/type
        value: LoadBalancer
```

Create `k8s-kind/overlays/cloud/cloud-patches.yaml`:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: chattingo-backend
  namespace: chattingo
spec:
  template:
    spec:
      containers:
      - name: chattingo-backend
        resources:
          requests:
            memory: "1Gi"
            cpu: "500m"
          limits:
            memory: "2Gi" 
            cpu: "1000m"
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: mysql
  namespace: chattingo
spec:
  template:
    spec:
      containers:
      - name: mysql
        resources:
          requests:
            memory: "1Gi"
            cpu: "500m"
          limits:
            memory: "2Gi"
            cpu: "1000m"
```

## 🚀 Deploy to Cloud

```bash
# Deploy with cloud configuration
kubectl apply -k k8s-kind/overlays/cloud/

# Check deployment
kubectl get pods -n chattingo
kubectl get services -n chattingo

# Get external IP (for LoadBalancer)
kubectl get service nginx-ingress-controller -n ingress-nginx --watch

# Update DNS/hosts with external IP
# Example: 34.123.45.67 chattingo.local
```

## 🔐 Production Considerations

### 1. Secrets Management
```bash
# Create production secrets
kubectl create secret generic mysql-secret \
  --from-literal=root-password=your-secure-password \
  --from-literal=user-password=your-user-password \
  -n chattingo

kubectl create secret generic jwt-secret \
  --from-literal=secret=your-jwt-secret-key \
  -n chattingo

kubectl create secret generic aws-credentials \
  --from-literal=access-key-id=your-access-key \
  --from-literal=secret-access-key=your-secret-key \
  -n chattingo
```

### 2. SSL Certificates (Production)
```bash
# Install cert-manager for real certificates
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.13.0/cert-manager.yaml

# Create Let's Encrypt issuer
kubectl apply -f - <<EOF
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-prod
spec:
  acme:
    server: https://acme-v02.api.letsencrypt.org/directory
    email: adityagaikwad888@example.com
    privateKeySecretRef:
      name: letsencrypt-prod
    solvers:
    - http01:
        ingress:
          class: nginx
EOF
```

### 3. Domain Setup
```bash
# Point your domain to the LoadBalancer IP
# Example DNS records:
# A record: chattingo.yourdomain.com -> 34.123.45.67
# A record: kibana.yourdomain.com -> 34.123.45.67  
# A record: yourdomain.com -> 34.123.45.67
```

### 4. Monitoring Setup
```bash
# Deploy logging and monitoring stack
kubectl apply -k k8s-kind/
```

## 📊 Cost Estimation

### Cloud Provider Costs (Monthly)

**Google Cloud (GKE)**
- 3x e2-standard-2 nodes: ~$150/month
- Load balancer: ~$25/month
- Storage (150GB): ~$15/month
- **Total: ~$190/month**

**Amazon EKS**
- Control plane: $73/month
- 3x t3.medium nodes: ~$100/month  
- Load balancer: ~$25/month
- Storage (150GB): ~$15/month
- **Total: ~$213/month**

**Azure AKS**
- 3x Standard_B2s nodes: ~$120/month
- Load balancer: ~$25/month
- Storage (150GB): ~$20/month
- **Total: ~$165/month**

**DigitalOcean (Recommended for hackathon/demo)**
- 3x s-2vcpu-4gb nodes: ~$72/month
- Load balancer: ~$12/month
- Storage (150GB): ~$15/month
- **Total: ~$99/month**

## 🎯 Quick Deployment Script

```bash
#!/bin/bash
# quick-deploy.sh

# Build and push images
./build-and-push.sh v1.0.0 push

# Deploy to cloud
kubectl apply -k k8s-kind/overlays/cloud/

# Wait for deployment
kubectl wait --for=condition=available --timeout=300s deployment --all -n chattingo

# Get external IP
kubectl get service nginx-ingress-controller -n ingress-nginx

echo "🎉 Chattingo deployed to cloud successfully!"
echo "Update your DNS to point to the external IP above"
```

Make it executable:
```bash
chmod +x quick-deploy.sh
```

## 🔧 Troubleshooting

### Image Pull Issues
```bash
# Check if images exist
docker pull adityagaikwad888/chattingo-backend:v1.0.0

# Check secrets
kubectl describe pods -n chattingo
```

### Resource Issues  
```bash
# Check node resources
kubectl describe nodes
kubectl top nodes

# Scale if needed
kubectl scale deployment chattingo-backend --replicas=2 -n chattingo
```

### Networking Issues
```bash
# Check services
kubectl get services -n chattingo
kubectl describe service frontend-service -n chattingo

# Check ingress
kubectl get ingress -n chattingo
kubectl describe ingress chattingo-ingress -n chattingo
```

---

**Your cloud deployment is ready!** 🚀

Choose your preferred cloud provider, follow the setup steps, and deploy your Chattingo application with full monitoring, logging, and SSL support.
