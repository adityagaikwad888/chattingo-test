#!/bin/bash

echo "Starting Chattingo Log Processor..."

# Check required environment variables
if [ -z "$LOG_PATH" ]; then
    export LOG_PATH="/var/log/chattingo"
fi

if [ -z "$S3_BUCKET" ]; then
    echo "Warning: S3_BUCKET not set, S3 upload will be disabled"
fi

# Create log directories if they don't exist
mkdir -p "$LOG_PATH"/{app,auth,chat,error,system,websocket}

echo "Log processor configuration:"
echo "  LOG_PATH: $LOG_PATH"
echo "  S3_BUCKET: $S3_BUCKET"
echo "  AWS_REGION: ${AWS_REGION:-us-east-1}"
echo "  MAX_AGE_DAYS: ${MAX_AGE_DAYS:-7}"
echo "  MAX_SIZE_MB: ${MAX_SIZE_MB:-100}"

# Start the log processor
exec python log_processor.py
