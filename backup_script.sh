#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

# Database credentials
DB_CONNECTION="mysql"
DB_HOST="127.0.0.1"
DB_PORT="3306"
DB_DATABASE="form"

# Backup directory
BACKUP_DIR="/mnt/d/BackupData"

# Create a timestamp
TIMESTAMP=$(date +"%F_%H-%M-%S")

# Backup file name
BACKUP_FILE="${DB_DATABASE}_${TIMESTAMP}.sql"

# Full path for the backup file
BACKUP_PATH="/tmp/${BACKUP_FILE}"

# Log file
LOG_FILE="/tmp/backup_${TIMESTAMP}.log"

# Function to log messages
log() {
    echo "$(date +"%Y-%m-%d %H:%M:%S") - $1" | tee -a "${LOG_FILE}"
}

# Function to handle errors
error_exit() {
    log "ERROR: $1"
    exit 1
}

# Dump the database into a SQL file
log "Starting database backup..."
mysqldump -h ${DB_HOST} -P ${DB_PORT} ${DB_DATABASE} > ${BACKUP_PATH} || error_exit "Failed to dump database"

# Compress the SQL file into a zip file
log "Compressing backup file..."
zip "${BACKUP_PATH}.zip" "${BACKUP_PATH}" || error_exit "Failed to compress backup file"

# Move the zip file to the backup directory
log "Moving backup file to ${BACKUP_DIR}..."
mv "${BACKUP_PATH}.zip" "${BACKUP_DIR}" || error_exit "Failed to move backup file"

# Remove the original SQL file
log "Removing temporary SQL file..."
rm "${BACKUP_PATH}" || error_exit "Failed to remove temporary SQL file"

log "Backup completed and stored in ${BACKUP_DIR}"