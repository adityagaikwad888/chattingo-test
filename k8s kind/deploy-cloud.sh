#!/bin/bash

# Chattingo Cloud Deployment Script
# Supports AWS EKS, Google GKE, Azure AKS, and local Kind clusters

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to show usage
show_usage() {
    cat << EOF
Usage: $0 [COMMAND] [OPTIONS]

Commands:
    deploy          Deploy Chattingo to cloud
    destroy         Destroy the deployment
    update          Update existing deployment
    status          Show deployment status
    logs            Show application logs
    shell           Get shell access to pods
    port-forward    Forward ports for local access

Cloud Providers:
    kind            Local Kind cluster
    aws             Amazon EKS
    gcp             Google GKE
    azure           Azure AKS
    digitalocean    DigitalOcean Kubernetes

Options:
    -p, --provider  Cloud provider (kind, aws, gcp, azure, digitalocean)
    -e, --env       Environment (dev, staging, prod)
    -r, --region    Cloud region
    -z, --zone      Cloud zone (for GCP)
    -c, --cluster   Cluster name
    --node-count    Number of nodes (default: 3)
    --node-size     Node instance size
    --disk-size     Node disk size in GB (default: 100)
    --dry-run       Show what would be done
    --auto-approve  Skip confirmation prompts

Examples:
    $0 deploy -p kind -e dev
    $0 deploy -p aws -e prod -r us-west-2 -c chattingo-prod
    $0 deploy -p gcp -e staging -r us-central1 -z us-central1-a
    $0 update -p aws -e prod
    $0 status -p kind
    $0 logs -p aws backend
    $0 destroy -p kind --auto-approve

EOF
}

# Cloud provider configurations
configure_aws() {
    local region=${1:-"us-west-2"}
    local cluster_name=${2:-"chattingo-cluster"}
    local node_count=${3:-3}
    local node_size=${4:-"t3.medium"}
    local disk_size=${5:-100}
    
    print_status "Configuring AWS EKS deployment..."
    
    # Check AWS CLI
    if ! command -v aws &> /dev/null; then
        print_error "AWS CLI is required but not installed"
        exit 1
    fi
    
    # Check eksctl
    if ! command -v eksctl &> /dev/null; then
        print_error "eksctl is required but not installed"
        print_status "Install with: curl --silent --location \"https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_$(uname -s)_amd64.tar.gz\" | tar xz -C /tmp && sudo mv /tmp/eksctl /usr/local/bin"
        exit 1
    fi
    
    # Create EKS cluster configuration
    cat > "$SCRIPT_DIR/eks-cluster.yaml" << EOF
apiVersion: eksctl.io/v1alpha5
kind: ClusterConfig

metadata:
  name: $cluster_name
  region: $region
  version: "1.27"

iam:
  withOIDC: true

nodeGroups:
  - name: chattingo-workers
    instanceType: $node_size
    desiredCapacity: $node_count
    minSize: 1
    maxSize: 10
    volumeSize: $disk_size
    volumeType: gp3
    amiFamily: AmazonLinux2
    labels:
      role: worker
      app: chattingo
    tags:
      Environment: $ENVIRONMENT
      Application: chattingo
      ManagedBy: eksctl
    iam:
      attachPolicyARNs:
        - arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy
        - arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy
        - arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly
        - arn:aws:iam::aws:policy/AmazonEBSCSIDriverPolicy

addons:
  - name: vpc-cni
  - name: coredns
  - name: kube-proxy
  - name: aws-ebs-csi-driver

cloudWatch:
  clusterLogging:
    enable: ["api", "audit", "authenticator", "controllerManager", "scheduler"]
EOF
    
    print_success "AWS EKS configuration created"
}

configure_gcp() {
    local region=${1:-"us-central1"}
    local zone=${2:-"us-central1-a"}
    local cluster_name=${3:-"chattingo-cluster"}
    local node_count=${4:-3}
    local node_size=${5:-"e2-standard-2"}
    local disk_size=${6:-100}
    
    print_status "Configuring Google GKE deployment..."
    
    # Check gcloud CLI
    if ! command -v gcloud &> /dev/null; then
        print_error "Google Cloud CLI is required but not installed"
        exit 1
    fi
    
    # Set GCP project
    if [[ -z "$GOOGLE_CLOUD_PROJECT" ]]; then
        print_error "GOOGLE_CLOUD_PROJECT environment variable is required"
        exit 1
    fi
    
    export GCP_PROJECT="$GOOGLE_CLOUD_PROJECT"
    export GCP_REGION="$region"
    export GCP_ZONE="$zone"
    export GCP_CLUSTER_NAME="$cluster_name"
    export GCP_NODE_COUNT="$node_count"
    export GCP_NODE_SIZE="$node_size"
    export GCP_DISK_SIZE="$disk_size"
    
    print_success "Google GKE configuration set"
}

configure_azure() {
    local region=${1:-"eastus"}
    local cluster_name=${2:-"chattingo-cluster"}
    local node_count=${3:-3}
    local node_size=${4:-"Standard_B2s"}
    local disk_size=${5:-100}
    
    print_status "Configuring Azure AKS deployment..."
    
    # Check Azure CLI
    if ! command -v az &> /dev/null; then
        print_error "Azure CLI is required but not installed"
        exit 1
    fi
    
    # Set Azure variables
    export AZURE_LOCATION="$region"
    export AZURE_CLUSTER_NAME="$cluster_name"
    export AZURE_NODE_COUNT="$node_count"
    export AZURE_NODE_SIZE="$node_size"
    export AZURE_DISK_SIZE="$disk_size"
    
    if [[ -z "$AZURE_RESOURCE_GROUP" ]]; then
        export AZURE_RESOURCE_GROUP="chattingo-rg"
        print_warning "AZURE_RESOURCE_GROUP not set, using default: $AZURE_RESOURCE_GROUP"
    fi
    
    print_success "Azure AKS configuration set"
}

# Deployment functions
deploy_to_kind() {
    local env=${1:-"dev"}
    
    print_status "Deploying to Kind cluster..."
    
    # Create Kind cluster if it doesn't exist
    if ! kind get clusters | grep -q "chattingo-cluster"; then
        print_status "Creating Kind cluster..."
        kind create cluster --config="$SCRIPT_DIR/00-kind-config.yaml"
        print_success "Kind cluster created"
    else
        print_status "Kind cluster already exists"
    fi
    
    # Set kubectl context
    kubectl cluster-info --context kind-chattingo-cluster
    
    # Install ingress controller
    print_status "Installing NGINX Ingress Controller..."
    kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml
    
    # Wait for ingress controller
    print_status "Waiting for ingress controller to be ready..."
    kubectl wait --namespace ingress-nginx \
        --for=condition=ready pod \
        --selector=app.kubernetes.io/component=controller \
        --timeout=90s
    
    deploy_application "$env"
}

deploy_to_aws() {
    local env=${1:-"prod"}
    local region=${2:-"us-west-2"}
    local cluster_name=${3:-"chattingo-cluster"}
    
    print_status "Deploying to AWS EKS..."
    
    # Create EKS cluster if it doesn't exist
    if ! eksctl get cluster --name="$cluster_name" --region="$region" &>/dev/null; then
        print_status "Creating EKS cluster (this may take 15-20 minutes)..."
        eksctl create cluster -f "$SCRIPT_DIR/eks-cluster.yaml"
        print_success "EKS cluster created"
    else
        print_status "EKS cluster already exists"
    fi
    
    # Update kubeconfig
    aws eks update-kubeconfig --region "$region" --name "$cluster_name"
    
    # Install AWS Load Balancer Controller
    print_status "Installing AWS Load Balancer Controller..."
    
    # Create IAM role for AWS Load Balancer Controller
    eksctl create iamserviceaccount \
        --cluster="$cluster_name" \
        --namespace=kube-system \
        --name=aws-load-balancer-controller \
        --attach-policy-arn=arn:aws:iam::$(aws sts get-caller-identity --query Account --output text):policy/AWSLoadBalancerControllerIAMPolicy \
        --override-existing-serviceaccounts \
        --approve
    
    # Install cert-manager
    kubectl apply --validate=false -f https://github.com/jetstack/cert-manager/releases/download/v1.5.4/cert-manager.yaml
    
    # Install AWS Load Balancer Controller
    kubectl apply -k "github.com/aws/eks-charts/stable/aws-load-balancer-controller//crds?ref=master"
    
    deploy_application "$env"
}

deploy_to_gcp() {
    local env=${1:-"prod"}
    
    print_status "Deploying to Google GKE..."
    
    # Create GKE cluster if it doesn't exist
    if ! gcloud container clusters describe "$GCP_CLUSTER_NAME" --zone="$GCP_ZONE" &>/dev/null; then
        print_status "Creating GKE cluster..."
        gcloud container clusters create "$GCP_CLUSTER_NAME" \
            --zone="$GCP_ZONE" \
            --num-nodes="$GCP_NODE_COUNT" \
            --machine-type="$GCP_NODE_SIZE" \
            --disk-size="$GCP_DISK_SIZE" \
            --enable-autoscaling \
            --min-nodes=1 \
            --max-nodes=10 \
            --enable-autorepair \
            --enable-autoupgrade \
            --labels="environment=$env,app=chattingo"
        print_success "GKE cluster created"
    else
        print_status "GKE cluster already exists"
    fi
    
    # Get cluster credentials
    gcloud container clusters get-credentials "$GCP_CLUSTER_NAME" --zone="$GCP_ZONE"
    
    deploy_application "$env"
}

deploy_to_azure() {
    local env=${1:-"prod"}
    
    print_status "Deploying to Azure AKS..."
    
    # Create resource group
    az group create --name "$AZURE_RESOURCE_GROUP" --location "$AZURE_LOCATION"
    
    # Create AKS cluster if it doesn't exist
    if ! az aks show --resource-group "$AZURE_RESOURCE_GROUP" --name "$AZURE_CLUSTER_NAME" &>/dev/null; then
        print_status "Creating AKS cluster..."
        az aks create \
            --resource-group "$AZURE_RESOURCE_GROUP" \
            --name "$AZURE_CLUSTER_NAME" \
            --location "$AZURE_LOCATION" \
            --node-count "$AZURE_NODE_COUNT" \
            --node-vm-size "$AZURE_NODE_SIZE" \
            --node-osdisk-size "$AZURE_DISK_SIZE" \
            --enable-addons monitoring \
            --generate-ssh-keys \
            --tags "Environment=$env" "Application=chattingo"
        print_success "AKS cluster created"
    else
        print_status "AKS cluster already exists"
    fi
    
    # Get cluster credentials
    az aks get-credentials --resource-group "$AZURE_RESOURCE_GROUP" --name "$AZURE_CLUSTER_NAME"
    
    deploy_application "$env"
}

# Deploy application to any cluster
deploy_application() {
    local env=${1:-"dev"}
    
    print_status "Deploying Chattingo application (environment: $env)..."
    
    # Create and update secrets
    "$SCRIPT_DIR/manage-env.sh" create-secrets -e "$env"
    
    # Apply Kubernetes manifests in order
    print_status "Applying Kubernetes manifests..."
    
    # Priority Classes and Namespaces
    kubectl apply -f "$SCRIPT_DIR/00-priority-class.yaml"
    kubectl apply -f "$SCRIPT_DIR/01-namespace.yaml"
    
    # Storage
    kubectl apply -f "$SCRIPT_DIR/02-mysql-pv.yaml"
    
    # Configuration
    kubectl apply -f "$SCRIPT_DIR/04-configmap.yaml"
    kubectl apply -f "$SCRIPT_DIR/05-secrets.yaml"
    
    # Database
    kubectl apply -f "$SCRIPT_DIR/06-mysql-service.yaml"
    kubectl apply -f "$SCRIPT_DIR/07-mysql-statefulset.yaml"
    
    # Application
    kubectl apply -f "$SCRIPT_DIR/08-backend-deployment.yaml"
    kubectl apply -f "$SCRIPT_DIR/09-backend-service.yaml"
    kubectl apply -f "$SCRIPT_DIR/10-frontend-deployment.yaml"
    kubectl apply -f "$SCRIPT_DIR/11-frontend-service.yaml"
    
    # Ingress
    kubectl apply -f "$SCRIPT_DIR/12-ingress.yaml"
    
    # Autoscaling
    kubectl apply -f "$SCRIPT_DIR/13-hpa.yaml"
    kubectl apply -f "$SCRIPT_DIR/14-vpa.yaml"
    
    # Monitoring
    kubectl apply -f "$SCRIPT_DIR/15-prometheus.yaml"
    kubectl apply -f "$SCRIPT_DIR/16-grafana.yaml"
    
    # Wait for deployments
    print_status "Waiting for deployments to be ready..."
    kubectl wait --for=condition=available --timeout=300s deployment/chattingo-backend -n chattingo
    kubectl wait --for=condition=available --timeout=300s deployment/chattingo-frontend -n chattingo
    kubectl wait --for=condition=ready --timeout=300s statefulset/mysql-statefulset -n chattingo
    
    print_success "Chattingo application deployed successfully!"
    
    # Show status
    show_deployment_status
}

# Show deployment status
show_deployment_status() {
    print_status "Deployment Status:"
    echo
    
    print_status "Namespaces:"
    kubectl get namespaces -l app.kubernetes.io/part-of=chattingo-platform
    echo
    
    print_status "Pods in chattingo namespace:"
    kubectl get pods -n chattingo -o wide
    echo
    
    print_status "Services:"
    kubectl get services -n chattingo
    echo
    
    print_status "Ingress:"
    kubectl get ingress -n chattingo
    echo
    
    print_status "HPA Status:"
    kubectl get hpa -n chattingo
    echo
    
    if [[ "$PROVIDER" == "kind" ]]; then
        print_status "Access URLs (add to /etc/hosts):"
        echo "127.0.0.1 chattingo.local"
        echo "127.0.0.1 grafana.chattingo.local" 
        echo "127.0.0.1 prometheus.chattingo.local"
        echo
        print_status "Application: http://chattingo.local"
        print_status "Grafana: http://grafana.chattingo.local (admin/admin123)"
        print_status "Prometheus: http://prometheus.chattingo.local"
    fi
}

# Parse command line arguments
COMMAND=""
PROVIDER="kind"
ENVIRONMENT="dev"
REGION=""
ZONE=""
CLUSTER_NAME=""
NODE_COUNT=3
NODE_SIZE=""
DISK_SIZE=100
DRY_RUN=false
AUTO_APPROVE=false

while [[ $# -gt 0 ]]; do
    case $1 in
        deploy|destroy|update|status|logs|shell|port-forward)
            COMMAND="$1"
            shift
            ;;
        -p|--provider)
            PROVIDER="$2"
            shift 2
            ;;
        -e|--env)
            ENVIRONMENT="$2"
            shift 2
            ;;
        -r|--region)
            REGION="$2"
            shift 2
            ;;
        -z|--zone)
            ZONE="$2"
            shift 2
            ;;
        -c|--cluster)
            CLUSTER_NAME="$2"
            shift 2
            ;;
        --node-count)
            NODE_COUNT="$2"
            shift 2
            ;;
        --node-size)
            NODE_SIZE="$2"
            shift 2
            ;;
        --disk-size)
            DISK_SIZE="$2"
            shift 2
            ;;
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        --auto-approve)
            AUTO_APPROVE=true
            shift
            ;;
        *)
            print_error "Unknown option: $1"
            show_usage
            exit 1
            ;;
    esac
done

# Set defaults based on provider
case "$PROVIDER" in
    kind)
        CLUSTER_NAME=${CLUSTER_NAME:-"chattingo-cluster"}
        ;;
    aws)
        REGION=${REGION:-"us-west-2"}
        CLUSTER_NAME=${CLUSTER_NAME:-"chattingo-eks-$ENVIRONMENT"}
        NODE_SIZE=${NODE_SIZE:-"t3.medium"}
        ;;
    gcp)
        REGION=${REGION:-"us-central1"}
        ZONE=${ZONE:-"us-central1-a"}
        CLUSTER_NAME=${CLUSTER_NAME:-"chattingo-gke-$ENVIRONMENT"}
        NODE_SIZE=${NODE_SIZE:-"e2-standard-2"}
        ;;
    azure)
        REGION=${REGION:-"eastus"}
        CLUSTER_NAME=${CLUSTER_NAME:-"chattingo-aks-$ENVIRONMENT"}
        NODE_SIZE=${NODE_SIZE:-"Standard_B2s"}
        ;;
    *)
        print_error "Unsupported provider: $PROVIDER"
        exit 1
        ;;
esac

# Execute commands
case "$COMMAND" in
    deploy)
        case "$PROVIDER" in
            kind)
                deploy_to_kind "$ENVIRONMENT"
                ;;
            aws)
                configure_aws "$REGION" "$CLUSTER_NAME" "$NODE_COUNT" "$NODE_SIZE" "$DISK_SIZE"
                deploy_to_aws "$ENVIRONMENT" "$REGION" "$CLUSTER_NAME"
                ;;
            gcp)
                configure_gcp "$REGION" "$ZONE" "$CLUSTER_NAME" "$NODE_COUNT" "$NODE_SIZE" "$DISK_SIZE"
                deploy_to_gcp "$ENVIRONMENT"
                ;;
            azure)
                configure_azure "$REGION" "$CLUSTER_NAME" "$NODE_COUNT" "$NODE_SIZE" "$DISK_SIZE"
                deploy_to_azure "$ENVIRONMENT"
                ;;
        esac
        ;;
    status)
        show_deployment_status
        ;;
    *)
        show_usage
        ;;
esac
