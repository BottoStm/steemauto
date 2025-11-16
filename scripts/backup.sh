#!/bin/bash
#
# SteemAuto Backup Script
# This script creates backups of the database and application files
#

set -e

# Configuration
BACKUP_DIR="/home/user/backups/steemauto"
DATE=$(date +%Y%m%d_%H%M%S)
RETENTION_DAYS=30

# Load database credentials from .env
if [ -f /home/user/steemauto/.env ]; then
    source <(grep -E '^(DB_USER|DB_PASSWORD|DB_NAME)=' /home/user/steemauto/.env | sed 's/^/export /')
else
    echo "Error: .env file not found!"
    exit 1
fi

# Create backup directory
mkdir -p $BACKUP_DIR

# Function to print messages
log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1"
}

# Backup database
backup_database() {
    log "Starting database backup..."

    mysqldump -u $DB_USER -p$DB_PASSWORD $DB_NAME | gzip > $BACKUP_DIR/steemauto_db_$DATE.sql.gz

    if [ $? -eq 0 ]; then
        log "Database backup completed: steemauto_db_$DATE.sql.gz"
    else
        log "Error: Database backup failed!"
        exit 1
    fi
}

# Backup application files
backup_files() {
    log "Starting application files backup..."

    tar -czf $BACKUP_DIR/steemauto_files_$DATE.tar.gz \
        -C /home/user steemauto \
        --exclude='steemauto/node_modules' \
        --exclude='steemauto/logs' \
        --exclude='steemauto/.git' \
        --exclude='steemauto/backups'

    if [ $? -eq 0 ]; then
        log "Files backup completed: steemauto_files_$DATE.tar.gz"
    else
        log "Error: Files backup failed!"
        exit 1
    fi
}

# Clean old backups
cleanup_old_backups() {
    log "Cleaning up old backups (older than $RETENTION_DAYS days)..."

    find $BACKUP_DIR -name "steemauto_*" -mtime +$RETENTION_DAYS -delete

    log "Cleanup completed"
}

# Calculate backup size
calculate_size() {
    local size=$(du -sh $BACKUP_DIR | cut -f1)
    log "Total backup size: $size"
}

# Main backup process
main() {
    log "=== SteemAuto Backup Started ==="

    backup_database
    backup_files
    cleanup_old_backups
    calculate_size

    log "=== Backup Completed Successfully ==="
}

# Run main function
main
