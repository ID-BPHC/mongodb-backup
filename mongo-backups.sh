#!/bin/bash

# Variables
BACKUP_DIR="/backups/mongodb"
LOG_FILE="/backups/logs.txt"
TODAY=$(date +"%Y-%m-%d")
YESTERDAY=$(date -d "yesterday" +"%Y-%m-%d")
MAX_RETRIES=3
RETRY_DELAY=60 # in seconds
SUCCESS=false

# Array of databases to back up (excluding large one)
DATABASES=("AUGSD" "ID-dev" "TDLeave" "TDLeaves" "TDLeavess" "admin" "airnotifier" "app_moodlecmsandroidgcm" "config" "dbName" "local" "medical")

# Ensure backup directory exists
mkdir -p $BACKUP_DIR

# Perform the backup with retries
echo "$(date) - Starting backup for $TODAY" >> $LOG_FILE
for DB in "${DATABASES[@]}"; do
    TODAY_BACKUP_DIR="$BACKUP_DIR/$DB/$TODAY"
    mkdir -p "$TODAY_BACKUP_DIR"  # Create directory for today's backup for this database

    for (( i=1; i<=MAX_RETRIES; i++ )); do
        echo "$(date) - Starting backup for database: $DB" >> $LOG_FILE
        mongodump --db "$DB" --out "$TODAY_BACKUP_DIR" >> $LOG_FILE 2>&1
        
        if [ $? -eq 0 ]; then
            echo "$(date) - Backup successful for database: $DB on attempt $i" >> $LOG_FILE
            SUCCESS=true
            break
        else
            echo "$(date) - Backup attempt $i failed for database: $DB" >> $LOG_FILE
            sleep $RETRY_DELAY
        fi
    done

    if [ "$SUCCESS" = false ]; then
        echo "$(date) - Backup failed for database: $DB after $MAX_RETRIES attempts." >> $LOG_FILE
    fi

    SUCCESS=false  # Reset success flag for the next database
done

# If any backup was successful, delete yesterday's backups for those databases
if [ "$SUCCESS" = true ]; then
    for DB in "${DATABASES[@]}"; do
        if [ -d "$BACKUP_DIR/$DB/$YESTERDAY" ]; then
            echo "$(date) - Removing yesterday's backup for database: $DB" >> $LOG_FILE
            rm -rf "$BACKUP_DIR/$DB/$YESTERDAY" >> $LOG_FILE 2>&1
        fi
    done
else
    echo "$(date) - Backup failed for all databases. Yesterday's backups not deleted." >> $LOG_FILE
fi

echo "$(date) - Backup process completed" >> $LOG_FILE
