#!/bin/bash
# Install and setup S3 uploader service

set -e

echo "Installing Chattingo S3 Uploader Service"

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root (use sudo)"
   exit 1
fi

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SERVICE_DIR="$(dirname "$SCRIPT_DIR")"

echo "Service directory: $SERVICE_DIR"

# Install Python dependencies
echo "Installing Python dependencies..."
pip3 install -r "$SERVICE_DIR/requirements.txt"

# Create log directory
echo "Creating log directory..."
mkdir -p /var/log/chattingo
chmod 755 /var/log/chattingo

# Create systemd service file
echo "Creating systemd service..."
cat > /etc/systemd/system/s3-uploader.service << EOF
[Unit]
Description=Chattingo S3 Log Uploader Service
After=network.target
Wants=network.target

[Service]
Type=simple
User=root
WorkingDirectory=$SERVICE_DIR
ExecStart=/usr/bin/python3 $SERVICE_DIR/s3-uploader.py
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal

# Environment variables (can be overridden)
Environment=AWS_REGION=us-east-1
Environment=S3_BUCKET=chattingo-logs

[Install]
WantedBy=multi-user.target
EOF

# Reload systemd and enable service
echo "Reloading systemd daemon..."
systemctl daemon-reload

echo "Enabling s3-uploader service..."
systemctl enable s3-uploader

echo "S3 uploader service installed successfully!"
echo ""
echo "Next steps:"
echo "1. Configure AWS credentials: aws configure"
echo "2. Update settings in: $SERVICE_DIR/config/settings.yaml"
echo "3. Start the service: sudo systemctl start s3-uploader"
echo "4. Check status: sudo systemctl status s3-uploader"
echo "5. View logs: sudo journalctl -u s3-uploader -f"
