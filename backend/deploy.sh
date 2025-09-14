#!/bin/bash

# Chattingo Backend Deployment Script with Comprehensive Logging
# This script sets up the complete logging infrastructure

set -e

echo "🚀 Starting Chattingo Backend Deployment with Logging Infrastructure"

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo "❌ Docker is not installed. Please install Docker first."
    exit 1
fi

if ! command -v docker-compose &> /dev/null; then
    echo "❌ Docker Compose is not installed. Please install Docker Compose first."
    exit 1
fi

# Create environment file if it doesn't exist
if [ ! -f .env ]; then
    echo "📝 Creating default .env file..."
    cat > .env << EOL
# Database Configuration
MYSQL_ROOT_PASSWORD=chattingo123
MYSQL_DATABASE=chattingo_db

# JWT Configuration
JWT_SECRET=this-is-a-very-long-jwt-secret-key-that-should-be-256-bits-or-32-characters-long

# CORS Configuration
CORS_ALLOWED_ORIGINS=http://localhost:3000,http://localhost:80
CORS_ALLOWED_METHODS=GET,POST,PUT,DELETE,OPTIONS

# AWS Configuration (optional - for S3 log upload)
#AWS_ACCESS_KEY_ID=your_aws_access_key
#AWS_SECRET_ACCESS_KEY=your_aws_secret_key
AWS_REGION=us-east-1
S3_BUCKET=chattingo-logs

# Logging Configuration
LOG_ROTATION_ENABLED=true
LOG_ROTATION_MAX_AGE_DAYS=7
LOG_ROTATION_MAX_SIZE_MB=100

# Application Configuration
SPRING_PROFILES_ACTIVE=production
SERVER_PORT=8080
EOL
    echo "✅ Default .env file created. Please update with your actual values."
fi

# Create log directories
echo "📁 Creating log directory structure..."
./scripts/setup-logs.sh

# Build the application
echo "🔨 Building Chattingo backend..."
mvn clean package -DskipTests

# Start the services
echo "🐳 Starting Docker services..."
docker-compose up -d --build

# Wait for services to start
echo "⏳ Waiting for services to start..."
sleep 30

# Check service health
echo "🔍 Checking service health..."

# Check MySQL
if docker-compose exec -T mysql mysqladmin ping -h localhost --silent; then
    echo "✅ MySQL is running"
else
    echo "❌ MySQL is not responding"
fi

# Check Elasticsearch
if curl -s http://localhost:9200/_cluster/health > /dev/null; then
    echo "✅ Elasticsearch is running"
else
    echo "❌ Elasticsearch is not responding"
fi

# Check Backend
if curl -s http://localhost:8080/actuator/health > /dev/null; then
    echo "✅ Chattingo Backend is running"
else
    echo "❌ Chattingo Backend is not responding"
fi

# Check Kibana
if curl -s http://localhost:5601/api/status > /dev/null; then
    echo "✅ Kibana is running"
else
    echo "❌ Kibana is not responding"
fi

echo ""
echo "🎉 Deployment completed!"
echo ""
echo "📊 Access Points:"
echo "  • Backend API: http://localhost:8080"
echo "  • Health Check: http://localhost:8080/actuator/health"
echo "  • Metrics: http://localhost:8080/actuator/metrics"
echo "  • Health Check: http://localhost:8080/actuator/health"
echo "  • Kibana Dashboard: http://localhost:5601"
echo "  • Frontend: http://localhost:3000"
echo ""
echo "📁 Log Files:"
echo "  • Application Logs: ./logs/app/"
echo "  • Authentication Logs: ./logs/auth/"
echo "  • Chat Logs: ./logs/chat/"
echo "  • Error Logs: ./logs/error/"
echo "  • System Logs: ./logs/system/"
echo "  • WebSocket Logs: ./logs/websocket/"
echo ""
echo "💡 Commands:"
echo "  • View logs: docker-compose logs -f [service_name]"
echo "  • Stop services: docker-compose down"
echo "  • Restart services: docker-compose restart"
echo "  • View backend logs: tail -f ./logs/app/application.log"
echo ""

# Show log file status
echo "📋 Current Log Files:"
find ./logs -name "*.log" -type f -exec ls -lh {} \; 2>/dev/null | head -10

echo ""
echo "🔗 Next Steps:"
echo "  1. Configure Kibana dashboards for log visualization"
echo "  2. Set up proper log management for application monitoring"
echo "  3. Configure S3 credentials in .env for log archival"
echo "  4. Test the logging by making API calls to the backend"
echo ""
