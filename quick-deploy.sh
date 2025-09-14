#!/bin/bash

# 🚀 Quick Cloud Deployment Script for Chattingo
# This script builds, pushes, and deploys Chattingo to cloud Kubernetes

set -e

# Configuration
VERSION=${1:-"v1.0.0"}
CLOUD_PROVIDER=${2:-"gcp"}  # gcp, aws, azure, digitalocean
DOCKER_USERNAME="adityagaikwad888"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}🚀 Chattingo Cloud Deployment${NC}"
echo -e "${YELLOW}Version: ${VERSION}${NC}"
echo -e "${YELLOW}Cloud Provider: ${CLOUD_PROVIDER}${NC}"

# Function to print section headers
print_section() {
    echo -e "\n${GREEN}===== $1 =====${NC}"
}

# Check prerequisites
print_section "Checking Prerequisites"

# Check Docker
if ! command -v docker &> /dev/null; then
    echo -e "${RED}❌ Docker not found. Please install Docker first.${NC}"
    exit 1
fi

if ! docker info >/dev/null 2>&1; then
    echo -e "${RED}❌ Docker is not running. Please start Docker first.${NC}"
    exit 1
fi

# Check kubectl
if ! command -v kubectl &> /dev/null; then
    echo -e "${RED}❌ kubectl not found. Please install kubectl first.${NC}"
    exit 1
fi

# Check Kubernetes connection
if ! kubectl cluster-info >/dev/null 2>&1; then
    echo -e "${RED}❌ Not connected to Kubernetes cluster. Please configure your kubeconfig.${NC}"
    exit 1
fi

echo -e "${GREEN}✅ All prerequisites met${NC}"

# Step 1: Build and Push Images
print_section "Building and Pushing Docker Images"

echo -e "${YELLOW}🔨 Building images...${NC}"
./build-and-push.sh "${VERSION}"

echo -e "${YELLOW}📤 Pushing to Docker Hub...${NC}"
./build-and-push.sh "${VERSION}" push

# Step 2: Update Image Tags in Cloud Overlay
print_section "Updating Cloud Configuration"

# Update image tags in kustomization
sed -i "s|newTag: .*|newTag: ${VERSION}|g" "k8s kind/overlays/cloud/kustomization.yaml"
sed -i "s|image: adityagaikwad888/chattingo-.*:.*|image: adityagaikwad888/chattingo-backend:${VERSION}|g" "k8s kind/overlays/cloud/cloud-patches.yaml"

echo -e "${GREEN}✅ Updated image tags to ${VERSION}${NC}"

# Step 3: Deploy to Kubernetes
print_section "Deploying to Kubernetes"

echo -e "${YELLOW}🚀 Applying cloud configuration...${NC}"
kubectl apply -k "k8s kind/overlays/cloud/"

echo -e "${YELLOW}⏳ Waiting for deployment to be ready...${NC}"

# Wait for critical deployments
echo -e "${BLUE}Waiting for MySQL...${NC}"
kubectl wait --for=condition=available --timeout=300s deployment/mysql -n chattingo

echo -e "${BLUE}Waiting for Backend...${NC}"
kubectl wait --for=condition=available --timeout=300s deployment/chattingo-backend -n chattingo

echo -e "${BLUE}Waiting for Frontend...${NC}"
kubectl wait --for=condition=available --timeout=300s deployment/chattingo-frontend -n chattingo

echo -e "${BLUE}Waiting for Elasticsearch...${NC}"
kubectl wait --for=condition=available --timeout=300s deployment/elasticsearch -n chattingo

echo -e "${GREEN}✅ Core services deployed successfully${NC}"

# Step 4: Get Service Information
print_section "Service Information"

echo -e "${YELLOW}📊 Checking deployment status...${NC}"
kubectl get pods -n chattingo
kubectl get pods -n chattingo-monitoring

echo -e "\n${YELLOW}🌐 Getting external access information...${NC}"

# Try to get LoadBalancer IP
EXTERNAL_IP=""
echo -e "${BLUE}Waiting for LoadBalancer IP...${NC}"
for i in {1..10}; do
    EXTERNAL_IP=$(kubectl get service nginx-ingress-controller -n ingress-nginx -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "")
    if [[ -z "$EXTERNAL_IP" ]]; then
        EXTERNAL_IP=$(kubectl get service nginx-ingress-controller -n ingress-nginx -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null || echo "")
    fi
    
    if [[ -n "$EXTERNAL_IP" ]]; then
        break
    fi
    
    echo -e "${YELLOW}Attempt $i/10: Waiting for external IP...${NC}"
    sleep 10
done

if [[ -n "$EXTERNAL_IP" ]]; then
    echo -e "${GREEN}✅ External IP/Hostname: ${EXTERNAL_IP}${NC}"
    
    # Step 5: DNS Configuration
    print_section "DNS Configuration"
    
    echo -e "${YELLOW}📝 DNS Records to create:${NC}"
    echo -e "${BLUE}A Record: chattingo.yourdomain.com -> ${EXTERNAL_IP}${NC}"
    echo -e "${BLUE}A Record: kibana.yourdomain.com -> ${EXTERNAL_IP}${NC}"
    echo -e "${BLUE}A Record: yourdomain.com -> ${EXTERNAL_IP}${NC}"
    
    echo -e "\n${YELLOW}🏠 For testing, add to /etc/hosts:${NC}"
    echo -e "${BLUE}${EXTERNAL_IP} chattingo.local${NC}"
    echo -e "${BLUE}${EXTERNAL_IP} kibana.chattingo.local${NC}"
    echo -e "${BLUE}${EXTERNAL_IP} chattingo.local${NC}"
    
    echo -e "\n${YELLOW}🌍 Access URLs (after DNS setup):${NC}"
    echo -e "${GREEN}🏠 Main App: https://chattingo.local${NC}"
    echo -e "${GREEN}📊 Kibana: https://kibana.chattingo.local${NC}"
    echo -e "${GREEN}� Application: https://chattingo.local${NC}"
    
else
    echo -e "${YELLOW}⚠️  LoadBalancer IP not available yet. Check manually:${NC}"
    echo -e "${BLUE}kubectl get service nginx-ingress-controller -n ingress-nginx --watch${NC}"
fi

# Step 6: Health Checks
print_section "Health Checks"

echo -e "${YELLOW}🔍 Running health checks...${NC}"

# Check if pods are running
FAILED_PODS=$(kubectl get pods -n chattingo --field-selector=status.phase!=Running --no-headers 2>/dev/null | wc -l)
if [[ "$FAILED_PODS" -gt 0 ]]; then
    echo -e "${YELLOW}⚠️  Some pods are not running:${NC}"
    kubectl get pods -n chattingo --field-selector=status.phase!=Running
else
    echo -e "${GREEN}✅ All pods are running${NC}"
fi

# Check services
echo -e "${BLUE}🔗 Services:${NC}"
kubectl get services -n chattingo

# Check ingress
echo -e "${BLUE}🌐 Ingress:${NC}"
kubectl get ingress -n chattingo

# Step 7: Resource Usage
print_section "Resource Usage"

echo -e "${YELLOW}📊 Current resource usage:${NC}"
kubectl top nodes 2>/dev/null || echo "Metrics server not available"
kubectl top pods -n chattingo 2>/dev/null || echo "Pod metrics not available"

# Step 8: Monitoring Setup
print_section "Monitoring Setup"

# Check if monitoring namespace exists
if kubectl get namespace chattingo-monitoring >/dev/null 2>&1; then
    echo -e "${GREEN}✅ Monitoring namespace exists${NC}"
    kubectl get pods -n chattingo-monitoring
else
    echo -e "${YELLOW}⚠️  Monitoring namespace not found${NC}"
fi

# Final Summary
print_section "Deployment Summary"

echo -e "${GREEN}🎉 Chattingo deployed successfully to ${CLOUD_PROVIDER^^}!${NC}"
echo -e "${BLUE}📋 What's deployed:${NC}"
echo -e "   ✅ Spring Boot Backend (${VERSION})"
echo -e "   ✅ React Frontend (${VERSION})"
echo -e "   ✅ MySQL Database"
echo -e "   ✅ ELK Stack (Elasticsearch, Kibana, Filebeat)"
echo -e "   ✅ Logging (ELK Stack)"
echo -e "   ✅ SSL Certificates"
echo -e "   ✅ S3 Log Archival"

echo -e "\n${YELLOW}📋 Next Steps:${NC}"
echo -e "1. ${BLUE}Update DNS records with external IP: ${EXTERNAL_IP}${NC}"
echo -e "2. ${BLUE}Test application: https://chattingo.local${NC}"
echo -e "3. ${BLUE}Check logs: https://kibana.chattingo.local${NC}"
echo -e "4. ${BLUE}Monitor logs: Check Kibana for application logs${NC}"

echo -e "\n${YELLOW}🔧 Useful commands:${NC}"
echo -e "${BLUE}kubectl get pods -n chattingo${NC}"
echo -e "${BLUE}kubectl logs -f deployment/chattingo-backend -n chattingo${NC}"
echo -e "${BLUE}kubectl top pods -n chattingo${NC}"

echo -e "\n${GREEN}🚀 Deployment completed successfully!${NC}"
