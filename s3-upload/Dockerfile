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
