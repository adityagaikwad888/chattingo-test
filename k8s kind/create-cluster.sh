#!/bin/bash

# Chattingo Kubernetes Cluster Creation and Deployment Script
# Creates Kind cluster and deploys the complete Chattingo application

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

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

print_header() {
    echo -e "${PURPLE}
╔══════════════════════════════════════════════════════════════════════════════╗
║                           CHATTINGO KUBERNETES DEPLOYMENT                    ║
║                        Production-Ready Kind Cluster Setup                   ║
╚══════════════════════════════════════════════════════════════════════════════╝${NC}"
}

print_step() {
    echo -e "${CYAN}[STEP]${NC} $1"
}

# Configuration
CLUSTER_NAME="chattingo-cluster"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="${SCRIPT_DIR}/deployment.log"

# Create log file
exec 1> >(tee -a "$LOG_FILE")
exec 2> >(tee -a "$LOG_FILE" >&2)

print_header

# Function to check prerequisites
check_prerequisites() {
    print_step "Checking prerequisites..."
    
    local missing_tools=()
    
    command -v kind >/dev/null 2>&1 || missing_tools+=("kind")
    command -v kubectl >/dev/null 2>&1 || missing_tools+=("kubectl")
    command -v docker >/dev/null 2>&1 || missing_tools+=("docker")
    command -v helm >/dev/null 2>&1 || missing_tools+=("helm")
    
    if [ ${#missing_tools[@]} -ne 0 ]; then
        print_error "Missing required tools: ${missing_tools[*]}"
        print_status "Please run ./install-kind-kubectl.sh first"
        exit 1
    fi
    
    # Check if Docker daemon is running
    if ! docker info >/dev/null 2>&1; then
        print_error "Docker daemon is not running. Please start Docker first."
        exit 1
    fi
    
    print_success "All prerequisites are met"
}

# Function to create directories
setup_directories() {
    print_step "Setting up directories..."
    
    mkdir -p logs/{app,auth,chat,error,system,websocket}
    mkdir -p mysql-data
    
    # Set proper permissions
    chmod 755 logs mysql-data
    chmod -R 777 logs/
    
    print_success "Directories created successfully"
}

# Function to create Kind cluster
create_cluster() {
    print_step "Creating Kind cluster..."
    
    # Check if cluster already exists
    if kind get clusters | grep -q "^${CLUSTER_NAME}$"; then
        print_warning "Cluster '${CLUSTER_NAME}' already exists"
        read -p "Do you want to delete and recreate it? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            print_status "Deleting existing cluster..."
            kind delete cluster --name "${CLUSTER_NAME}"
        else
            print_status "Using existing cluster"
            return 0
        fi
    fi
    
    print_status "Creating new Kind cluster with configuration..."
    kind create cluster \
        --name "${CLUSTER_NAME}" \
        --config 00-kind-config.yaml \
        --wait 300s
    
    # Update kubeconfig
    kubectl config use-context "kind-${CLUSTER_NAME}"
    
    print_success "Kind cluster created successfully"
}

# Function to install ingress controller
install_ingress_controller() {
    print_step "Installing NGINX Ingress Controller..."
    
    # Apply ingress-nginx
    kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml
    
    # Wait for ingress controller to be ready
    print_status "Waiting for ingress controller to be ready..."
    kubectl wait --namespace ingress-nginx \
        --for=condition=ready pod \
        --selector=app.kubernetes.io/component=controller \
        --timeout=300s
    
    print_success "NGINX Ingress Controller installed successfully"
}

# Function to install cert-manager
install_cert_manager() {
    print_step "Installing cert-manager..."
    
    # Add the Jetstack Helm repository
    helm repo add jetstack https://charts.jetstack.io
    helm repo update
    
    # Install cert-manager
    helm upgrade --install \
        cert-manager jetstack/cert-manager \
        --namespace cert-manager \
        --create-namespace \
        --version v1.13.0 \
        --set installCRDs=true \
        --wait
    
    print_success "cert-manager installed successfully"
}

# Function to install metrics server
install_metrics_server() {
    print_step "Installing metrics server..."
    
    # Install metrics server for HPA/VPA
    kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
    
    # Patch metrics server for Kind (disable TLS verification)
    kubectl patch deployment metrics-server -n kube-system --type='json' -p='[
        {
            "op": "add",
            "path": "/spec/template/spec/containers/0/args/-",
            "value": "--kubelet-insecure-tls"
        },
        {
            "op": "add",
            "path": "/spec/template/spec/containers/0/args/-",
            "value": "--kubelet-preferred-address-types=InternalIP"
        }
    ]'
    
    # Wait for metrics server to be ready
    print_status "Waiting for metrics server to be ready..."
    kubectl wait --namespace kube-system \
        --for=condition=ready pod \
        --selector=k8s-app=metrics-server \
        --timeout=300s
    
    print_success "Metrics server installed successfully"
}

# Function to install VPA
install_vpa() {
    print_step "Installing Vertical Pod Autoscaler..."
    
    # Clone VPA repository if not exists
    if [ ! -d "autoscaler" ]; then
        git clone https://github.com/kubernetes/autoscaler.git
    fi
    
    # Install VPA
    cd autoscaler/vertical-pod-autoscaler
    ./hack/vpa-up.sh
    cd ../..
    
    print_success "VPA installed successfully"
}

# Function to build and load images
build_and_load_images() {
    print_step "Building and loading Docker images..."
    
    # Build backend image
    print_status "Building backend image..."
    cd ../backend
    docker build -t chattingo/backend:latest .
    
    # Build frontend image
    print_status "Building frontend image..."
    cd ../frontend
    docker build -t chattingo/frontend:latest .
    
    cd ../k8s\ kind
    
    # Load images into Kind cluster
    print_status "Loading images into Kind cluster..."
    kind load docker-image chattingo/backend:latest --name "${CLUSTER_NAME}"
    kind load docker-image chattingo/frontend:latest --name "${CLUSTER_NAME}"
    
    print_success "Images built and loaded successfully"
}

# Function to deploy application
deploy_application() {
    print_step "Deploying Chattingo application..."
    
    # Apply manifests in order
    print_status "Applying Kubernetes manifests..."
    
    # Infrastructure
    kubectl apply -f 00-priority-class.yaml
    kubectl apply -f 01-namespace.yaml
    
    # Wait for namespaces
    kubectl wait --for=condition=ready namespace/chattingo --timeout=60s
    kubectl wait --for=condition=ready namespace/chattingo-monitoring --timeout=60s
    
    # Storage and Configuration
    kubectl apply -f 02-mysql-pv.yaml
    kubectl apply -f 04-configmap.yaml
    kubectl apply -f 05-secrets.yaml
    
    # Database
    kubectl apply -f 06-mysql-service.yaml
    kubectl apply -f 07-mysql-statefulset.yaml
    
    # Wait for MySQL to be ready
    print_status "Waiting for MySQL to be ready..."
    kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=mysql -n chattingo --timeout=300s
    
    # Application
    kubectl apply -f 08-backend-deployment.yaml
    kubectl apply -f 09-backend-service.yaml
    kubectl apply -f 10-frontend-deployment.yaml
    kubectl apply -f 11-frontend-service.yaml
    
    # Wait for application to be ready
    print_status "Waiting for application to be ready..."
    kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=chattingo-backend -n chattingo --timeout=300s
    kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=chattingo-frontend -n chattingo --timeout=300s
    
    # Networking
    kubectl apply -f 17-selfsigned-issuer.yaml
    sleep 10  # Wait for cert-manager to process
    kubectl apply -f 12-ingress.yaml
    
    # Autoscaling
    kubectl apply -f 13-hpa.yaml
    kubectl apply -f 14-vpa.yaml
    
    # Monitoring
    kubectl apply -f 15-prometheus.yaml
    kubectl apply -f 16-grafana.yaml
    
    print_success "Application deployed successfully"
}

# Function to configure local DNS
setup_local_dns() {
    print_step "Setting up local DNS..."
    
    # Add entries to /etc/hosts
    local hosts_entries="
# Chattingo Kind Cluster
127.0.0.1 chattingo.local
127.0.0.1 www.chattingo.local
127.0.0.1 api.chattingo.local
127.0.0.1 grafana.chattingo.local
127.0.0.1 prometheus.chattingo.local
127.0.0.1 monitoring.chattingo.local
"
    
    if ! grep -q "chattingo.local" /etc/hosts; then
        print_status "Adding DNS entries to /etc/hosts..."
        echo "$hosts_entries" | sudo tee -a /etc/hosts
        print_success "DNS entries added to /etc/hosts"
    else
        print_warning "DNS entries already exist in /etc/hosts"
    fi
}

# Function to display cluster information
display_cluster_info() {
    print_step "Cluster Information"
    
    echo -e "${GREEN}
╔══════════════════════════════════════════════════════════════════════════════╗
║                            DEPLOYMENT SUCCESSFUL!                            ║
╚══════════════════════════════════════════════════════════════════════════════╝${NC}"
    
    echo -e "${CYAN}Cluster Details:${NC}"
    echo "  Cluster Name: ${CLUSTER_NAME}"
    echo "  Kubernetes Version: $(kubectl version --short --client | grep Client)"
    echo "  Nodes: $(kubectl get nodes --no-headers | wc -l)"
    echo ""
    
    echo -e "${CYAN}Application URLs:${NC}"
    echo "  🌐 Frontend: http://chattingo.local"
    echo "  🔗 API: http://chattingo.local/api"
    echo "  📊 Grafana: http://grafana.chattingo.local (admin/chattingo_grafana_admin_2025)"
    echo "  📈 Prometheus: http://prometheus.chattingo.local"
    echo ""
    
    echo -e "${CYAN}Useful Commands:${NC}"
    echo "  kubectl get pods -n chattingo"
    echo "  kubectl get services -n chattingo"
    echo "  kubectl logs -f deployment/chattingo-backend -n chattingo"
    echo "  kubectl port-forward svc/frontend-service 3000:80 -n chattingo"
    echo ""
    
    echo -e "${CYAN}Status Check:${NC}"
    kubectl get pods -n chattingo
    echo ""
    kubectl get pods -n chattingo-monitoring
}

# Function to cleanup on failure
cleanup_on_failure() {
    print_error "Deployment failed. Cleaning up..."
    kind delete cluster --name "${CLUSTER_NAME}" 2>/dev/null || true
    exit 1
}

# Main execution
main() {
    print_status "Starting Chattingo Kubernetes deployment..."
    
    # Set up error handling
    trap cleanup_on_failure ERR
    
    check_prerequisites
    setup_directories
    create_cluster
    install_ingress_controller
    install_cert_manager
    install_metrics_server
    # install_vpa  # Commented out as it's optional and can cause issues
    build_and_load_images
    deploy_application
    setup_local_dns
    display_cluster_info
    
    print_success "Chattingo deployment completed successfully! 🎉"
    print_status "Check the log file: $LOG_FILE"
}

# Check if script is being sourced or executed
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
