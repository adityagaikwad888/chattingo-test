#!/bin/bash

# Chattingo Kubernetes Cluster Management Script
# Provides various operations for managing the Kind cluster

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Configuration
CLUSTER_NAME="chattingo-cluster"
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

print_header() {
    echo -e "${PURPLE}
╔══════════════════════════════════════════════════════════════════════════════╗
║                      CHATTINGO CLUSTER MANAGEMENT                           ║
╚══════════════════════════════════════════════════════════════════════════════╝${NC}"
}

# Function to show usage
show_usage() {
    echo "Usage: $0 [COMMAND]"
    echo ""
    echo "Commands:"
    echo "  status      - Show cluster and application status"
    echo "  logs        - Show application logs"
    echo "  scale       - Scale application components"
    echo "  restart     - Restart application components"
    echo "  update      - Update application with new images"
    echo "  backup      - Backup database and configurations"
    echo "  restore     - Restore from backup"
    echo "  debug       - Debug and troubleshooting tools"
    echo "  cleanup     - Clean up resources"
    echo "  destroy     - Destroy the entire cluster"
    echo "  help        - Show this help message"
    echo ""
}

# Function to check cluster status
check_status() {
    print_header
    print_status "Checking Chattingo cluster status..."
    
    # Check if cluster exists
    if ! kind get clusters | grep -q "^${CLUSTER_NAME}$"; then
        print_error "Cluster '${CLUSTER_NAME}' not found"
        print_status "Run './create-cluster.sh' to create the cluster"
        return 1
    fi
    
    print_success "Cluster '${CLUSTER_NAME}' is running"
    
    # Check nodes
    echo -e "\n${CYAN}Nodes:${NC}"
    kubectl get nodes -o wide
    
    # Check namespaces
    echo -e "\n${CYAN}Namespaces:${NC}"
    kubectl get namespaces --show-labels
    
    # Check pods in chattingo namespace
    echo -e "\n${CYAN}Application Pods:${NC}"
    kubectl get pods -n chattingo -o wide
    
    # Check pods in monitoring namespace
    echo -e "\n${CYAN}Monitoring Pods:${NC}"
    kubectl get pods -n chattingo-monitoring -o wide
    
    # Check services
    echo -e "\n${CYAN}Services:${NC}"
    kubectl get services -n chattingo
    kubectl get services -n chattingo-monitoring
    
    # Check ingress
    echo -e "\n${CYAN}Ingress:${NC}"
    kubectl get ingress -n chattingo
    kubectl get ingress -n chattingo-monitoring
    
    # Check persistent volumes
    echo -e "\n${CYAN}Persistent Volumes:${NC}"
    kubectl get pv,pvc -A
    
    # Check HPA status
    echo -e "\n${CYAN}Horizontal Pod Autoscalers:${NC}"
    kubectl get hpa -n chattingo
    
    # Check application health
    echo -e "\n${CYAN}Application Health:${NC}"
    check_app_health
}

# Function to check application health
check_app_health() {
    local backend_ready=$(kubectl get deployment chattingo-backend -n chattingo -o jsonpath='{.status.readyReplicas}' 2>/dev/null || echo "0")
    local frontend_ready=$(kubectl get deployment chattingo-frontend -n chattingo -o jsonpath='{.status.readyReplicas}' 2>/dev/null || echo "0")
    local mysql_ready=$(kubectl get statefulset mysql-statefulset -n chattingo -o jsonpath='{.status.readyReplicas}' 2>/dev/null || echo "0")
    
    echo "  Backend: ${backend_ready} replicas ready"
    echo "  Frontend: ${frontend_ready} replicas ready" 
    echo "  MySQL: ${mysql_ready} replicas ready"
    
    # Test endpoints
    echo -e "\n${CYAN}Endpoint Health Checks:${NC}"
    
    # Test backend health
    if kubectl exec -n chattingo deployment/chattingo-backend -- curl -s -f http://localhost:8080/actuator/health >/dev/null 2>&1; then
        echo -e "  Backend Health: ${GREEN}✓ Healthy${NC}"
    else
        echo -e "  Backend Health: ${RED}✗ Unhealthy${NC}"
    fi
    
    # Test frontend health
    if kubectl exec -n chattingo deployment/chattingo-frontend -- curl -s -f http://localhost/health >/dev/null 2>&1; then
        echo -e "  Frontend Health: ${GREEN}✓ Healthy${NC}"
    else
        echo -e "  Frontend Health: ${RED}✗ Unhealthy${NC}"
    fi
}

# Function to show logs
show_logs() {
    local component="$1"
    
    case $component in
        backend|be)
            print_status "Showing backend logs..."
            kubectl logs -f deployment/chattingo-backend -n chattingo
            ;;
        frontend|fe)
            print_status "Showing frontend logs..."
            kubectl logs -f deployment/chattingo-frontend -n chattingo
            ;;
        mysql|db)
            print_status "Showing MySQL logs..."
            kubectl logs -f statefulset/mysql-statefulset -n chattingo -c mysql
            ;;
        prometheus)
            print_status "Showing Prometheus logs..."
            kubectl logs -f deployment/prometheus -n chattingo-monitoring
            ;;
        grafana)
            print_status "Showing Grafana logs..."
            kubectl logs -f deployment/grafana -n chattingo-monitoring
            ;;
        all)
            print_status "Showing all application logs..."
            kubectl logs -f deployment/chattingo-backend -n chattingo &
            kubectl logs -f deployment/chattingo-frontend -n chattingo &
            kubectl logs -f statefulset/mysql-statefulset -n chattingo -c mysql &
            wait
            ;;
        *)
            print_error "Unknown component: $component"
            echo "Available components: backend, frontend, mysql, prometheus, grafana, all"
            return 1
            ;;
    esac
}

# Function to scale components
scale_component() {
    local component="$1"
    local replicas="$2"
    
    if [[ -z "$replicas" ]]; then
        print_error "Please specify number of replicas"
        return 1
    fi
    
    case $component in
        backend|be)
            print_status "Scaling backend to $replicas replicas..."
            kubectl scale deployment chattingo-backend --replicas="$replicas" -n chattingo
            ;;
        frontend|fe)
            print_status "Scaling frontend to $replicas replicas..."
            kubectl scale deployment chattingo-frontend --replicas="$replicas" -n chattingo
            ;;
        *)
            print_error "Unknown component: $component"
            echo "Available components: backend, frontend"
            return 1
            ;;
    esac
    
    print_success "Scaling completed"
}

# Function to restart components
restart_component() {
    local component="$1"
    
    case $component in
        backend|be)
            print_status "Restarting backend..."
            kubectl rollout restart deployment/chattingo-backend -n chattingo
            kubectl rollout status deployment/chattingo-backend -n chattingo
            ;;
        frontend|fe)
            print_status "Restarting frontend..."
            kubectl rollout restart deployment/chattingo-frontend -n chattingo
            kubectl rollout status deployment/chattingo-frontend -n chattingo
            ;;
        mysql|db)
            print_status "Restarting MySQL..."
            kubectl delete pod -l app.kubernetes.io/name=mysql -n chattingo
            kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=mysql -n chattingo --timeout=300s
            ;;
        all)
            print_status "Restarting all components..."
            restart_component backend
            restart_component frontend
            restart_component mysql
            ;;
        *)
            print_error "Unknown component: $component"
            echo "Available components: backend, frontend, mysql, all"
            return 1
            ;;
    esac
    
    print_success "Restart completed"
}

# Function to update images
update_images() {
    print_status "Updating application images..."
    
    # Rebuild and load images
    cd ../backend
    docker build -t chattingo/backend:latest .
    cd ../frontend
    docker build -t chattingo/frontend:latest .
    cd ../k8s\ kind
    
    # Load new images
    kind load docker-image chattingo/backend:latest --name "${CLUSTER_NAME}"
    kind load docker-image chattingo/frontend:latest --name "${CLUSTER_NAME}"
    
    # Rolling update
    kubectl set image deployment/chattingo-backend chattingo-backend=chattingo/backend:latest -n chattingo
    kubectl set image deployment/chattingo-frontend chattingo-frontend=chattingo/frontend:latest -n chattingo
    
    # Wait for rollout
    kubectl rollout status deployment/chattingo-backend -n chattingo
    kubectl rollout status deployment/chattingo-frontend -n chattingo
    
    print_success "Images updated successfully"
}

# Function to backup
backup_data() {
    local backup_dir="backups/$(date +%Y%m%d_%H%M%S)"
    
    print_status "Creating backup in $backup_dir..."
    mkdir -p "$backup_dir"
    
    # Backup database
    print_status "Backing up MySQL database..."
    kubectl exec -n chattingo statefulset/mysql-statefulset -c mysql -- \
        mysqldump -u root -p"$(kubectl get secret mysql-secrets -n chattingo -o jsonpath='{.data.MYSQL_ROOT_PASSWORD}' | base64 -d)" \
        --all-databases > "$backup_dir/mysql_backup.sql"
    
    # Backup configurations
    print_status "Backing up configurations..."
    kubectl get configmaps -n chattingo -o yaml > "$backup_dir/configmaps.yaml"
    kubectl get secrets -n chattingo -o yaml > "$backup_dir/secrets.yaml"
    
    # Backup persistent volume data
    print_status "Backing up persistent volumes..."
    kubectl cp chattingo/mysql-statefulset-0:/var/lib/mysql "$backup_dir/mysql_data" -c mysql || true
    
    print_success "Backup completed: $backup_dir"
}

# Function to debug
debug_cluster() {
    print_status "Running diagnostics..."
    
    echo -e "\n${CYAN}Cluster Events:${NC}"
    kubectl get events --sort-by=.metadata.creationTimestamp -A | tail -20
    
    echo -e "\n${CYAN}Resource Usage:${NC}"
    kubectl top nodes 2>/dev/null || echo "Metrics server not available"
    kubectl top pods -n chattingo 2>/dev/null || echo "Metrics server not available"
    
    echo -e "\n${CYAN}Failed Pods:${NC}"
    kubectl get pods -A --field-selector=status.phase!=Running,status.phase!=Succeeded
    
    echo -e "\n${CYAN}Pod Descriptions (Recent Failures):${NC}"
    local failed_pods=$(kubectl get pods -n chattingo --field-selector=status.phase!=Running -o jsonpath='{.items[*].metadata.name}')
    for pod in $failed_pods; do
        echo -e "\n--- $pod ---"
        kubectl describe pod "$pod" -n chattingo | tail -20
    done
    
    echo -e "\n${CYAN}Network Policies:${NC}"
    kubectl get networkpolicies -A
    
    echo -e "\n${CYAN}Ingress Controllers:${NC}"
    kubectl get pods -n ingress-nginx
}

# Function to cleanup resources
cleanup_resources() {
    print_warning "This will clean up unused resources but keep the application running"
    read -p "Continue? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        return
    fi
    
    print_status "Cleaning up unused resources..."
    
    # Clean up completed jobs
    kubectl delete jobs --field-selector=status.successful=1 -A
    
    # Clean up failed pods
    kubectl delete pods --field-selector=status.phase=Failed -A
    
    # Clean up dangling replica sets
    kubectl delete replicasets --all -n chattingo
    kubectl delete replicasets --all -n chattingo-monitoring
    
    print_success "Cleanup completed"
}

# Function to destroy cluster
destroy_cluster() {
    print_warning "This will completely destroy the cluster and all data!"
    read -p "Are you sure? Type 'yes' to confirm: " confirm
    
    if [[ "$confirm" != "yes" ]]; then
        print_status "Aborted"
        return
    fi
    
    print_status "Destroying cluster..."
    kind delete cluster --name "${CLUSTER_NAME}"
    
    # Clean up local directories
    print_status "Cleaning up local directories..."
    rm -rf logs/* mysql-data/* 2>/dev/null || true
    
    print_success "Cluster destroyed"
}

# Main command handler
main() {
    local command="$1"
    
    case $command in
        status|st)
            check_status
            ;;
        logs|log)
            show_logs "$2"
            ;;
        scale)
            scale_component "$2" "$3"
            ;;
        restart|rs)
            restart_component "$2"
            ;;
        update|up)
            update_images
            ;;
        backup|bk)
            backup_data
            ;;
        debug|dbg)
            debug_cluster
            ;;
        cleanup|clean)
            cleanup_resources
            ;;
        destroy|del)
            destroy_cluster
            ;;
        help|--help|-h)
            show_usage
            ;;
        "")
            show_usage
            ;;
        *)
            print_error "Unknown command: $command"
            show_usage
            exit 1
            ;;
    esac
}

# Execute main function
main "$@"
