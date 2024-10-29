#!/bin/bash

# Variables
BACKUP_BASE_DIR="/backups/mongodb"
LOG_FILE="/backups/logs.txt"
TODAY=$(date +"%Y-%m-%d")
YESTERDAY=$(date -d "yesterday" +"%Y-%m-%d")
MAX_RETRIES=3
RETRY_DELAY=60 # in seconds

# Array of databases to back up (excluding large one)
DATABASES=("AUGSD" "ID-dev" "TDLeave" "TDLeaves" "TDLeavess" "admin" "airnotifier" "app_moodlecmsandroidgcm" "config" "dbName" "local" "medical")

# Ensure base backup directory exists
mkdir -p "$BACKUP_BASE_DIR"

# Clear the log file at the start of each run
> "$LOG_FILE"

echo "$(date) - Starting backup process for $TODAY" >> "$LOG_FILE"

# Initialize an array to track failed backups
FAILED_BACKUPS=()

# Perform the backup with retries
for DB in "${DATABASES[@]}"; do
    # Create today's backup directory for this database
    TODAY_BACKUP_DIR="$BACKUP_BASE_DIR/$TODAY"
    mkdir -p "$TODAY_BACKUP_DIR"

    DB_SUCCESS=false

    for (( i=1; i<=MAX_RETRIES; i++ )); do
        echo "$(date) - Attempting backup for database: $DB (Attempt $i)" >> "$LOG_FILE"
        mongodump --db "$DB" --out "$TODAY_BACKUP_DIR" >> "$LOG_FILE" 2>&1
        
        if [ $? -eq 0 ]; then
            echo "$(date) - Successfully created backup for database: $DB" >> "$LOG_FILE"
            DB_SUCCESS=true
            break
        else
            echo "$(date) - Attempt $i failed for database: $DB" >> "$LOG_FILE"
            sleep $RETRY_DELAY
        fi
    done

    if [ "$DB_SUCCESS" = true ]; then
        # Delete yesterday's backup if today's was successful
        if [ -d "$BACKUP_BASE_DIR/$YESTERDAY/$DB" ]; then
            echo "$(date) - Removing yesterday's backup for database: $DB" >> "$LOG_FILE"
            rm -rf "$BACKUP_BASE_DIR/$YESTERDAY/$DB" >> "$LOG_FILE" 2>&1
        fi
    else
        echo "$(date) - Backup failed for database: $DB after $MAX_RETRIES attempts." >> "$LOG_FILE"
        FAILED_BACKUPS+=("$DB")  # Add the failed database to the array
    fi
done

# Final log message based on backup status
if [ ${#FAILED_BACKUPS[@]} -eq 0 ]; then
    echo "$(date) - Backup process completed successfully." >> "$LOG_FILE"
else
    echo "$(date) - Backup process completed with failures for the following databases: ${FAILED_BACKUPS[*]}" >> "$LOG_FILE"
fi
