#!/bin/bash
# Test the S3 uploader service

set -e

echo "Testing Chattingo S3 Uploader Service"

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SERVICE_DIR="$(dirname "$SCRIPT_DIR")"

echo "Service directory: $SERVICE_DIR"

# Check if config exists
if [[ ! -f "$SERVICE_DIR/config/settings.yaml" ]]; then
    echo "Configuration file not found: $SERVICE_DIR/config/settings.yaml"
    exit 1
fi

# Check if AWS credentials are configured
echo "Checking AWS credentials..."
if ! aws sts get-caller-identity &>/dev/null; then
    echo "AWS credentials not configured. Run: aws configure"
    exit 1
fi

echo "AWS credentials OK"

# Create test log files if they don't exist
echo "Creating test log files..."
mkdir -p /var/log/chattingo/app
mkdir -p /var/log/chattingo/error

# Create a test compressed log file
echo "$(date): Test log entry for S3 upload" | gzip > /var/log/chattingo/app/test_$(date +%Y%m%d_%H%M%S).log.gz
echo "$(date): Test error log entry for S3 upload" | gzip > /var/log/chattingo/error/test_error_$(date +%Y%m%d_%H%M%S).log.gz

echo "Test log files created"

# Run the uploader once
echo "Running S3 uploader (single run)..."
cd "$SERVICE_DIR"
python3 s3-uploader.py &
UPLOADER_PID=$!

# Let it run for 10 seconds
sleep 10

# Stop the process
kill $UPLOADER_PID 2>/dev/null || true

echo "Test completed!"
echo ""
echo "Check the logs above for any errors."
echo "If successful, you should see upload confirmations."
echo ""
echo "To run as a service:"
echo "  sudo systemctl start s3-uploader"
echo "  sudo systemctl status s3-uploader"
