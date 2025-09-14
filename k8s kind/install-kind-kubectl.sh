#!/bin/bash

# Chattingo Kubernetes Installation Script
# This script installs the latest versions of Kind and kubectl

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
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

# Check if running as root
if [[ $EUID -eq 0 ]]; then
   print_error "This script should not be run as root for security reasons"
   exit 1
fi

# Detect OS and Architecture
OS=$(uname -s | tr '[:upper:]' '[:lower:]')
ARCH=$(uname -m)

case $ARCH in
    x86_64) ARCH="amd64" ;;
    arm64|aarch64) ARCH="arm64" ;;
    *) print_error "Unsupported architecture: $ARCH"; exit 1 ;;
esac

print_status "Detected OS: $OS, Architecture: $ARCH"

# Create bin directory if it doesn't exist
mkdir -p $HOME/bin

# Function to install kubectl
install_kubectl() {
    print_status "Installing kubectl..."
    
    # Get latest stable version
    KUBECTL_VERSION=$(curl -L -s https://dl.k8s.io/release/stable.txt)
    print_status "Latest kubectl version: $KUBECTL_VERSION"
    
    # Download kubectl
    curl -LO "https://dl.k8s.io/release/$KUBECTL_VERSION/bin/$OS/$ARCH/kubectl"
    
    # Verify checksum
    curl -LO "https://dl.k8s.io/release/$KUBECTL_VERSION/bin/$OS/$ARCH/kubectl.sha256"
    if command -v sha256sum &> /dev/null; then
        echo "$(<kubectl.sha256) kubectl" | sha256sum --check
    else
        print_warning "sha256sum not available, skipping checksum verification"
    fi
    
    # Make executable and move to bin
    chmod +x kubectl
    mv kubectl $HOME/bin/
    
    # Clean up
    rm -f kubectl.sha256
    
    print_success "kubectl installed successfully"
}

# Function to install Kind
install_kind() {
    print_status "Installing Kind..."
    
    # Get latest Kind version from GitHub API
    KIND_VERSION=$(curl -s https://api.github.com/repos/kubernetes-sigs/kind/releases/latest | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
    print_status "Latest Kind version: $KIND_VERSION"
    
    # Download Kind
    curl -Lo ./kind "https://kind.sigs.k8s.io/dl/$KIND_VERSION/kind-$OS-$ARCH"
    
    # Make executable and move to bin
    chmod +x ./kind
    mv ./kind $HOME/bin/
    
    print_success "Kind installed successfully"
}

# Function to install Docker (if not present)
install_docker() {
    if command -v docker &> /dev/null; then
        print_success "Docker is already installed"
        return
    fi
    
    print_status "Docker not found. Installing Docker..."
    
    case $OS in
        linux)
            # Install Docker using official script
            curl -fsSL https://get.docker.com -o get-docker.sh
            sh get-docker.sh
            rm get-docker.sh
            
            # Add user to docker group
            sudo usermod -aG docker $USER
            print_warning "Please log out and log back in for Docker group changes to take effect"
            ;;
        darwin)
            print_error "Please install Docker Desktop for Mac manually from https://docs.docker.com/docker-for-mac/install/"
            exit 1
            ;;
        *)
            print_error "Unsupported OS for automatic Docker installation: $OS"
            exit 1
            ;;
    esac
    
    print_success "Docker installed successfully"
}

# Function to install Helm
install_helm() {
    print_status "Installing Helm..."
    
    # Download and install Helm
    curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
    
    print_success "Helm installed successfully"
}

# Function to update PATH
update_path() {
    # Add $HOME/bin to PATH if not already present
    if [[ ":$PATH:" != *":$HOME/bin:"* ]]; then
        echo 'export PATH="$HOME/bin:$PATH"' >> $HOME/.bashrc
        echo 'export PATH="$HOME/bin:$PATH"' >> $HOME/.profile
        
        # Also add to current session
        export PATH="$HOME/bin:$PATH"
        
        print_success "Added $HOME/bin to PATH"
    else
        print_status "$HOME/bin is already in PATH"
    fi
}

# Function to verify installations
verify_installations() {
    print_status "Verifying installations..."
    
    # Add to current PATH for verification
    export PATH="$HOME/bin:$PATH"
    
    if command -v kubectl &> /dev/null; then
        KUBECTL_VER=$(kubectl version --client --short 2>/dev/null | cut -d' ' -f3 || kubectl version --client -o yaml | grep gitVersion | cut -d' ' -f4)
        print_success "kubectl version: $KUBECTL_VER"
    else
        print_error "kubectl installation failed"
        exit 1
    fi
    
    if command -v kind &> /dev/null; then
        KIND_VER=$(kind version | cut -d' ' -f2)
        print_success "Kind version: $KIND_VER"
    else
        print_error "Kind installation failed"
        exit 1
    fi
    
    if command -v docker &> /dev/null; then
        DOCKER_VER=$(docker --version | cut -d' ' -f3 | sed 's/,//')
        print_success "Docker version: $DOCKER_VER"
    else
        print_error "Docker is not available"
        exit 1
    fi
    
    if command -v helm &> /dev/null; then
        HELM_VER=$(helm version --short | cut -d' ' -f1)
        print_success "Helm version: $HELM_VER"
    else
        print_warning "Helm installation may have failed"
    fi
}

# Main execution
main() {
    print_status "Starting Chattingo Kubernetes tools installation..."
    
    # Install dependencies
    install_docker
    install_kubectl
    install_kind
    install_helm
    
    # Update PATH
    update_path
    
    # Verify installations
    verify_installations
    
    print_success "All tools installed successfully!"
    print_status "You may need to restart your terminal or run 'source ~/.bashrc' to use the tools"
    print_status "To create the Kind cluster, run: ./create-cluster.sh"
}

# Run main function
main "$@"
