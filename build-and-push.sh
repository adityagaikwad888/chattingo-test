#!/bin/bash

# 🚀 Chattingo Docker Build & Push Script
# Usage: ./build-and-push.sh [version] [push]
# Example: ./build-and-push.sh v1.0.0 push

set -e

# Configuration
DOCKER_USERNAME="adityagaikwad888"
VERSION=${1:-"latest"}
PUSH_TO_HUB=${2:-""}

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🚀 Starting Chattingo Docker Build Process${NC}"
echo -e "${YELLOW}Version: ${VERSION}${NC}"
echo -e "${YELLOW}Docker Username: ${DOCKER_USERNAME}${NC}"

# Function to print section headers
print_section() {
    echo -e "\n${GREEN}===== $1 =====${NC}"
}

# Function to build image
build_image() {
    local service=$1
    local dockerfile_path=$2
    local context_path=$3
    local image_name="${DOCKER_USERNAME}/chattingo-${service}:${VERSION}"
    
    print_section "Building ${service} image"
    echo -e "${YELLOW}Image: ${image_name}${NC}"
    echo -e "${YELLOW}Context: ${context_path}${NC}"
    echo -e "${YELLOW}Dockerfile: ${dockerfile_path}${NC}"
    
    docker build \
        -t "${image_name}" \
        -t "${DOCKER_USERNAME}/chattingo-${service}:latest" \
        -f "${dockerfile_path}" \
        "${context_path}"
    
    echo -e "${GREEN}✅ Successfully built ${image_name}${NC}"
    
    # Show image info
    echo -e "${BLUE}Image size: $(docker images --format 'table {{.Repository}}:{{.Tag}}\t{{.Size}}' | grep chattingo-${service} | head -1 | awk '{print $2}')${NC}"
}

# Function to push image
push_image() {
    local service=$1
    local image_name="${DOCKER_USERNAME}/chattingo-${service}"
    
    print_section "Pushing ${service} to Docker Hub"
    echo -e "${YELLOW}Pushing ${image_name}:${VERSION}${NC}"
    docker push "${image_name}:${VERSION}"
    
    echo -e "${YELLOW}Pushing ${image_name}:latest${NC}"
    docker push "${image_name}:latest"
    
    echo -e "${GREEN}✅ Successfully pushed ${service} images${NC}"
}

# Check if Docker is running
if ! docker info >/dev/null 2>&1; then
    echo -e "${RED}❌ Docker is not running. Please start Docker first.${NC}"
    exit 1
fi

# Check if logged into Docker Hub (if pushing)
if [[ "$PUSH_TO_HUB" == "push" ]]; then
    if ! docker info | grep -q "Username: ${DOCKER_USERNAME}"; then
        echo -e "${YELLOW}⚠️  Not logged into Docker Hub. Attempting login...${NC}"
        docker login
    fi
fi

print_section "Building Application Images"

# 1. Build Backend Image
echo -e "\n${BLUE}📦 Building Spring Boot Backend${NC}"
build_image "backend" "./backend/Dockerfile" "./backend"

# 2. Build Frontend Image  
echo -e "\n${BLUE}🌐 Building React Frontend${NC}"
build_image "frontend" "./frontend/Dockerfile" "./frontend"

# 3. Build S3 Uploader Image
print_section "Building S3 Uploader Image"
echo -e "${YELLOW}Creating S3 Uploader Dockerfile...${NC}"

# Create S3 uploader Dockerfile if it doesn't exist
cat > ./s3-upload/Dockerfile << 'EOF'
FROM python:3.11-alpine

WORKDIR /app

# Install required packages
RUN apk add --no-cache curl tzdata && \
    pip install --no-cache-dir boto3 pyyaml schedule

# Copy application files
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY s3-uploader.py .
COPY config/ ./config/
COPY scripts/ ./scripts/

# Create directories for logs
RUN mkdir -p /var/log/chattingo

# Health check
HEALTHCHECK --interval=60s --timeout=10s --start-period=30s --retries=3 \
    CMD python -c "import boto3; print('S3 uploader healthy')" || exit 1

CMD ["python", "s3-uploader.py"]
EOF

build_image "s3-uploader" "./s3-upload/Dockerfile" "./s3-upload"

# 4. Build Log Processor Image (for custom log processing)
print_section "Building Log Processor Image"
build_image "log-processor" "./backend/log-processor/Dockerfile" "./backend/log-processor"

print_section "Build Summary"
echo -e "${GREEN}✅ All images built successfully!${NC}"

# Show all built images
echo -e "\n${BLUE}📋 Built Images:${NC}"
docker images | grep "${DOCKER_USERNAME}/chattingo" | head -10

# Calculate total size
total_size=$(docker images --format "table {{.Repository}}:{{.Tag}}\t{{.Size}}" | grep "${DOCKER_USERNAME}/chattingo" | grep -v "latest" | awk '{print $2}' | sed 's/MB//' | sed 's/GB/*1000/' | bc | awk '{sum += $1} END {print sum}')
echo -e "${BLUE}📊 Total size: ~${total_size}MB${NC}"

# Push to Docker Hub if requested
if [[ "$PUSH_TO_HUB" == "push" ]]; then
    print_section "Pushing to Docker Hub"
    
    push_image "backend"
    push_image "frontend" 
    push_image "s3-uploader"
    push_image "log-processor"
    
    print_section "Docker Hub URLs"
    echo -e "${GREEN}🐳 Your images are now available at:${NC}"
    echo -e "${BLUE}• Backend: https://hub.docker.com/r/${DOCKER_USERNAME}/chattingo-backend${NC}"
    echo -e "${BLUE}• Frontend: https://hub.docker.com/r/${DOCKER_USERNAME}/chattingo-frontend${NC}"
    echo -e "${BLUE}• S3 Uploader: https://hub.docker.com/r/${DOCKER_USERNAME}/chattingo-s3-uploader${NC}"
    echo -e "${BLUE}• Log Processor: https://hub.docker.com/r/${DOCKER_USERNAME}/chattingo-log-processor${NC}"
    
    print_section "Next Steps"
    echo -e "${YELLOW}1. Update Kubernetes manifests with new image URLs${NC}"
    echo -e "${YELLOW}2. Deploy to your cloud Kubernetes cluster${NC}"
    echo -e "${YELLOW}3. Update image tags in deployment files${NC}"
    
else
    print_section "Local Build Complete"
    echo -e "${YELLOW}💡 To push to Docker Hub, run:${NC}"
    echo -e "${BLUE}   ./build-and-push.sh ${VERSION} push${NC}"
    echo -e "\n${YELLOW}💡 Or push individual images:${NC}"
    echo -e "${BLUE}   docker push ${DOCKER_USERNAME}/chattingo-backend:${VERSION}${NC}"
    echo -e "${BLUE}   docker push ${DOCKER_USERNAME}/chattingo-frontend:${VERSION}${NC}"
fi

echo -e "\n${GREEN}🎉 Build process completed successfully!${NC}"
