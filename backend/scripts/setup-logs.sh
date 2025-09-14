#!/bin/bash

# Script to create log directory structure for Chattingo application

# Base log directory (can be overridden with environment variable)
LOG_BASE_DIR=${LOG_BASE_DIR:-"./logs"}

echo "Creating log directory structure at: $LOG_BASE_DIR"

# Create main log directories
mkdir -p "$LOG_BASE_DIR"/{app,auth,chat,error,system,websocket}

# Set appropriate permissions
chmod -R 755 "$LOG_BASE_DIR"

# Create placeholder files to ensure directories are preserved in git
touch "$LOG_BASE_DIR/app/.gitkeep"
touch "$LOG_BASE_DIR/auth/.gitkeep"
touch "$LOG_BASE_DIR/chat/.gitkeep"
touch "$LOG_BASE_DIR/error/.gitkeep"
touch "$LOG_BASE_DIR/system/.gitkeep"
touch "$LOG_BASE_DIR/websocket/.gitkeep"

echo "Log directory structure created successfully:"
tree "$LOG_BASE_DIR" 2>/dev/null || ls -la "$LOG_BASE_DIR"

echo "Directories created:"
echo "  - $LOG_BASE_DIR/app/       (Application logs)"
echo "  - $LOG_BASE_DIR/auth/      (Authentication & Security logs)"
echo "  - $LOG_BASE_DIR/chat/      (Chat & Messaging logs)"
echo "  - $LOG_BASE_DIR/error/     (Error logs)"
echo "  - $LOG_BASE_DIR/system/    (System & Infrastructure logs)"
echo "  - $LOG_BASE_DIR/websocket/ (WebSocket logs)"
