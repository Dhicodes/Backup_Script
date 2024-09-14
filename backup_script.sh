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

# Function to store backups in specific directories
store_backups() {
    log "Storing backups in specific directories..."

    # Create directories if they don't exist
    mkdir -p "${BACKUP_DIR}/last_3_days"
    mkdir -p "${BACKUP_DIR}/7_days"
    mkdir -p "${BACKUP_DIR}/14_days"
    mkdir -p "${BACKUP_DIR}/30_days"
    mkdir -p "${BACKUP_DIR}/180_days"

    # Move backups to specific directories based on their age
    find "${BACKUP_DIR}" -type f -name "${DB_DATABASE}_*.zip" -exec bash -c '
        for file; do
            base=$(basename "$file")
            date_part=$(echo "$base" | sed -E "s/^.*_([0-9]{4}-[0-9]{2}-[0-9]{2})_.*$/\1/")
            file_date=$(date -d "$date_part" +%s)
            now=$(date +%s)
            days_diff=$(( (now - file_date) / 86400 ))

            if [[ $days_diff -le 3 ]]; then
                mv "$file" "${BACKUP_DIR}/last_3_days/"
            elif [[ $days_diff -eq 7 ]]; then
                mv "$file" "${BACKUP_DIR}/7_days/"
            elif [[ $days_diff -eq 14 ]]; then
                mv "$file" "${BACKUP_DIR}/14_days/"
            elif [[ $days_diff -eq 30 ]]; then
                mv "$file" "${BACKUP_DIR}/30_days/"
            elif [[ $days_diff -eq 180 ]]; then
                mv "$file" "${BACKUP_DIR}/180_days/"
            fi
        done
    ' bash {} +
}

# Function to remove old backups
cleanup_old_backups() {
    log "Cleaning up old backups..."

    # Remove backups older than 3 days, except for those on the 7th, 14th, 30th, and 180th day
    find "${BACKUP_DIR}" -type f -name "${DB_DATABASE}_*.zip" -mtime +3 -exec bash -c '
        for file; do
            base=$(basename "$file")
            date_part=$(echo "$base" | sed -E "s/^.*_([0-9]{4}-[0-9]{2}-[0-9]{2})_.*$/\1/")
            file_date=$(date -d "$date_part" +%s)
            now=$(date +%s)
            days_diff=$(( (now - file_date) / 86400 ))

            if [[ $days_diff -ne 7 && $days_diff -ne 14 && $days_diff -ne 30 && $days_diff -ne 180 ]]; then
                rm "$file"
            fi
        done
    ' bash {} +
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

# Store backups in specific directories
store_backups

# Clean up old backups
cleanup_old_backups

log "Backup completed and stored in ${BACKUP_DIR}"