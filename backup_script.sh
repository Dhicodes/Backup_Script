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
IMAGE_DIR="/path/to/image_directory"

# Create a timestamp
TIMESTAMP=$(date +"%F_%H-%M-%S")

# Backup file names
DB_BACKUP_FILE="${DB_DATABASE}_${TIMESTAMP}.sql"
IMAGE_BACKUP_FILE="images_${TIMESTAMP}.tar.gz"

# Full paths for the backup files
DB_BACKUP_PATH="/tmp/${DB_BACKUP_FILE}"
IMAGE_BACKUP_PATH="/tmp/${IMAGE_BACKUP_FILE}"

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

# Function to delete backups older than 7 days
cleanup_old_backups() {
    log "Cleaning up old backups older than 7 days..."

    # Find and delete backups older than 7 days
    find "${BACKUP_DIR}" -type f -name "${DB_DATABASE}_*.zip" -mtime +7 -exec rm -f {} \; || error_exit "Failed to clean up old backups"
    find "${BACKUP_DIR}" -type f -name "images_*.tar.gz" -mtime +7 -exec rm -f {} \; || error_exit "Failed to clean up old image backups"
}

# Function to delete database data older than 7 days
delete_old_data() {
    log "Deleting data older than 7 days from the database..."

    # Get the list of tables
    tables=$(mysql ${DB_DATABASE} -e "SHOW TABLES;" -s --skip-column-names)

    # Iterate over each table and delete old data
    for table in $tables; do
        log "Deleting old data from table $table..."
        mysql ${DB_DATABASE} -e "
            DELETE FROM $table WHERE updated_at < NOW() - INTERVAL 7 DAY;
        " || error_exit "Failed to delete old data from table $table"
    done
}

# Delete old data from the database
delete_old_data

# Dump the database into a SQL file
log "Starting database backup..."
mysqldump ${DB_DATABASE} > ${DB_BACKUP_PATH} || error_exit "Failed to dump database"

# Compress the SQL file into a zip file
log "Compressing database backup file..."
zip "${DB_BACKUP_PATH}.zip" "${DB_BACKUP_PATH}" || error_exit "Failed to compress database backup file"

# Move the zip file to the backup directory
log "Moving database backup file to ${BACKUP_DIR}..."
mv "${DB_BACKUP_PATH}.zip" "${BACKUP_DIR}" || error_exit "Failed to move database backup file"

# Remove the original SQL file
log "Removing temporary SQL file..."
rm "${DB_BACKUP_PATH}" || error_exit "Failed to remove temporary SQL file"

# Backup the image directory
log "Starting image directory backup..."
tar -czf "${IMAGE_BACKUP_PATH}" -C "${IMAGE_DIR}" . || error_exit "Failed to backup image directory"

# Move the tar.gz file to the backup directory
log "Moving image backup file to ${BACKUP_DIR}..."
mv "${IMAGE_BACKUP_PATH}" "${BACKUP_DIR}" || error_exit "Failed to move image backup file"

# Clean up old backups older than 7 days
cleanup_old_backups

log "Backup completed and stored in ${BACKUP_DIR}"
