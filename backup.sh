#!/bin/bash

# Set variables
BACKUP_DIR="/home/$USER/backups"
DATE=$(date +%Y%m%d)
POSTGRES_CONTAINER=$(docker ps --filter "name=postgres" --format "{{.Names}}")
POSTGRES_USER="n8n"
POSTGRES_DB="n8n"

# Check if required directory exists
mkdir -p ${BACKUP_DIR}

# Source environment variables including DB_PASSWORD
if [ -f "/home/$USER/n8n/.env" ]; then
    source /home/$USER/n8n/.env
else
    echo "Error: .env file not found"
    exit 1
fi

# Backup PostgreSQL using password from environment
PGPASSWORD=${DB_PASSWORD} docker exec ${POSTGRES_CONTAINER} pg_dump -U ${POSTGRES_USER} ${POSTGRES_DB} > ${BACKUP_DIR}/backup_${DATE}.sql

# Check if the database backup was successful
if [ $? -eq 0 ]; then
    echo "Database backup successful: ${BACKUP_DIR}/backup_${DATE}.sql"
else
    echo "Database backup failed"
    exit 1
fi

# Backup n8n data
tar -czf ${BACKUP_DIR}/n8n_data_${DATE}.tar.gz /var/lib/docker/volumes/n8n_n8n_data

# Check if the data backup was successful
if [ $? -eq 0 ]; then
    echo "n8n data backup successful: ${BACKUP_DIR}/n8n_data_${DATE}.tar.gz"
else
    echo "n8n data backup failed"
    exit 1
fi

# Backup .env file
cp /home/$USER/n8n/.env ${BACKUP_DIR}/env_backup_${DATE}.env
echo "Environment file backed up: ${BACKUP_DIR}/env_backup_${DATE}.env"

# Only attempt Azure upload if storage variables are set
if [ ! -z "${AZURE_STORAGE_ACCOUNT}" ] && [ ! -z "${AZURE_CONTAINER_NAME}" ]; then
    az storage blob upload \
      --account-name ${AZURE_STORAGE_ACCOUNT} \
      --container-name ${AZURE_CONTAINER_NAME} \
      --name backup_${DATE}.sql \
      --file ${BACKUP_DIR}/backup_${DATE}.sql
    
    az storage blob upload \
      --account-name ${AZURE_STORAGE_ACCOUNT} \
      --container-name ${AZURE_CONTAINER_NAME} \
      --name n8n_data_${DATE}.tar.gz \
      --file ${BACKUP_DIR}/n8n_data_${DATE}.tar.gz
else
    echo "Azure storage variables not set, skipping upload"
fi

# Optional: Clean up old backups (keep only last 7 days)
find ${BACKUP_DIR} -name "backup_*.sql" -mtime +7 -delete
find ${BACKUP_DIR} -name "n8n_data_*.tar.gz" -mtime +7 -delete
find ${BACKUP_DIR} -name "env_backup_*.env" -mtime +7 -delete

echo "Backup process completed"
