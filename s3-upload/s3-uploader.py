#!/usr/bin/env python3
"""
Chattingo S3 Log Upload Service
Runs on host machine to upload log files from /var/log/chattingo/* to S3
Designed for Kubernetes deployment where pods write to host volume
"""

import os
import time
import gzip
import shutil
import logging
import boto3
import yaml
from datetime import datetime, timedelta
from pathlib import Path
from botocore.exceptions import ClientError
import schedule
import signal
import sys

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[
        logging.StreamHandler(),
        logging.FileHandler('/var/log/s3-uploader.log')
    ]
)
logger = logging.getLogger('s3-uploader')

class S3LogUploader:
    def __init__(self, config_path='config/settings.yaml'):
        """Initialize S3 uploader with configuration"""
        self.config = self.load_config(config_path)
        self.log_path = self.config['log_path']
        self.s3_bucket = self.config['s3']['bucket_name']
        self.aws_region = self.config['s3']['region']
        self.max_age_days = self.config['cleanup']['max_age_days']
        self.check_interval_minutes = self.config['schedule']['check_interval_minutes']
        
        # Initialize S3 client
        try:
            self.s3_client = boto3.client('s3', region_name=self.aws_region)
            logger.info(f"S3 client initialized for bucket: {self.s3_bucket}")
            # Test S3 connectivity
            self.s3_client.head_bucket(Bucket=self.s3_bucket)
            logger.info("S3 bucket connectivity verified")
        except Exception as e:
            logger.error(f"Failed to initialize S3 client: {e}")
            raise

    def load_config(self, config_path):
        """Load configuration from YAML file"""
        try:
            with open(config_path, 'r') as f:
                config = yaml.safe_load(f)
            logger.info(f"Configuration loaded from {config_path}")
            return config
        except Exception as e:
            logger.error(f"Failed to load config from {config_path}: {e}")
            # Return default config
            return {
                'log_path': '/var/log/chattingo',
                's3': {
                    'bucket_name': 'chattingo-logs',
                    'region': 'us-east-1'
                },
                'cleanup': {
                    'max_age_days': 7,
                    'delete_after_upload': True
                },
                'schedule': {
                    'check_interval_minutes': 30
                }
            }

    def find_log_files_to_upload(self):
        """Find compressed log files ready for upload"""
        log_base_path = Path(self.log_path)
        
        if not log_base_path.exists():
            logger.warning(f"Log directory does not exist: {log_base_path}")
            return []

        # Find all .gz files (compressed logs ready for upload)
        files_to_upload = []
        for gz_file in log_base_path.rglob('*.gz'):
            if gz_file.is_file():
                # Get category from parent directory
                category = gz_file.parent.name
                files_to_upload.append({
                    'file_path': gz_file,
                    'category': category,
                    'size': gz_file.stat().st_size,
                    'modified': gz_file.stat().st_mtime
                })
        
        return files_to_upload

    def upload_to_s3(self, file_info):
        """Upload a single file to S3"""
        file_path = file_info['file_path']
        category = file_info['category']
        
        try:
            # Create S3 key with date partition
            date_str = datetime.now().strftime('%Y/%m/%d')
            s3_key = f"chattingo-logs/{date_str}/{category}/{file_path.name}"
            
            # Upload file to S3 Standard storage (no Glacier)
            extra_args = {
                'ContentType': 'application/gzip',
                'ContentEncoding': 'gzip',
                'Metadata': {
                    'source': 'chattingo-k8s',
                    'category': category,
                    'upload_time': datetime.now().isoformat()
                }
            }
            
            self.s3_client.upload_file(
                str(file_path),
                self.s3_bucket,
                s3_key,
                ExtraArgs=extra_args
            )
            
            logger.info(f"Uploaded: {file_path.name} -> s3://{self.s3_bucket}/{s3_key}")
            return True
            
        except ClientError as e:
            logger.error(f"Failed to upload {file_path}: {e}")
            return False

    def cleanup_uploaded_file(self, file_path):
        """Delete local file after successful upload"""
        if self.config['cleanup']['delete_after_upload']:
            try:
                file_path.unlink()
                logger.info(f"🗑️  Cleaned up local file: {file_path}")
            except Exception as e:
                logger.warning(f"Failed to delete local file {file_path}: {e}")

    def cleanup_old_files(self):
        """Clean up old log files that haven't been uploaded"""
        logger.info("Starting cleanup of old local files")
        cutoff_time = time.time() - (self.max_age_days * 24 * 3600)
        deleted_count = 0
        
        log_base_path = Path(self.log_path)
        if not log_base_path.exists():
            return

        for file_path in log_base_path.rglob('*'):
            if file_path.is_file() and file_path.suffix in ['.log', '.gz']:
                try:
                    if file_path.stat().st_mtime < cutoff_time:
                        file_path.unlink()
                        deleted_count += 1
                        logger.info(f"Deleted old file: {file_path}")
                except Exception as e:
                    logger.warning(f"Failed to delete {file_path}: {e}")
        
        logger.info(f"Cleanup completed - deleted {deleted_count} old files")

    def process_logs(self):
        """Main processing function - find and upload logs"""
        logger.info("Starting log upload cycle")
        
        try:
            files_to_upload = self.find_log_files_to_upload()
            
            if not files_to_upload:
                logger.debug("No compressed log files found for upload")
                return
            
            logger.info(f"Found {len(files_to_upload)} files to upload")
            
            upload_count = 0
            for file_info in files_to_upload:
                if self.upload_to_s3(file_info):
                    self.cleanup_uploaded_file(file_info['file_path'])
                    upload_count += 1
                else:
                    logger.warning(f"Skipping cleanup for failed upload: {file_info['file_path']}")
            
            logger.info(f"Upload cycle completed - {upload_count}/{len(files_to_upload)} files uploaded")
            
        except Exception as e:
            logger.error(f"Error during log processing: {e}")

    def run(self):
        """Run the uploader service"""
        logger.info("Starting Chattingo S3 Log Uploader Service")
        logger.info(f"Monitoring: {self.log_path}")
        logger.info(f"S3 Bucket: {self.s3_bucket}")
        logger.info(f"Check interval: {self.check_interval_minutes} minutes")
        
        # Schedule periodic tasks
        schedule.every(self.check_interval_minutes).minutes.do(self.process_logs)
        schedule.every().day.at("02:00").do(self.cleanup_old_files)
        
        # Setup signal handlers for graceful shutdown
        def signal_handler(signum, frame):
            logger.info("Received shutdown signal, stopping service...")
            sys.exit(0)
        
        signal.signal(signal.SIGINT, signal_handler)
        signal.signal(signal.SIGTERM, signal_handler)
        
        # Run initial processing
        self.process_logs()
        
        # Main loop
        try:
            while True:
                schedule.run_pending()
                time.sleep(60)  # Check every minute
        except KeyboardInterrupt:
            logger.info("Service stopped by user")
        except Exception as e:
            logger.error(f"Service crashed: {e}")
            raise

def main():
    """Main entry point"""
    try:
        uploader = S3LogUploader()
        uploader.run()
    except Exception as e:
        logger.error(f"Failed to start S3 uploader service: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()
