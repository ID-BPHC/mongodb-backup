#!/bin/bash

# Variables
BACKUP_DIR="/backups/mongodb"
LOG_FILE="/backups/logs.txt"
TODAY=$(date +"%Y-%m-%d")
YESTERDAY=$(date -d "yesterday" +"%Y-%m-%d")
TODAY_BACKUP_DIR="$BACKUP_DIR/$TODAY"
MAX_RETRIES=3
RETRY_DELAY=60 # in seconds
SUCCESS=false

# Ensure backup directory exists
mkdir -p $TODAY_BACKUP_DIR

# Perform the backup with retries
echo "$(date) - Starting backup for $TODAY" >> $LOG_FILE
for (( i=1; i<=MAX_RETRIES; i++ ))
do
    mongodump --out $TODAY_BACKUP_DIR >> $LOG_FILE 2>&1
    if [ $? -eq 0 ]; then
        echo "$(date) - Backup successful on attempt $i" >> $LOG_FILE
        SUCCESS=true
        break
    else
        echo "$(date) - Backup attempt $i failed" >> $LOG_FILE
        sleep $RETRY_DELAY
    fi
done

# If the backup was successful, delete yesterday's backup
if [ "$SUCCESS" = true ]; then
    if [ -d "$BACKUP_DIR/$YESTERDAY" ]; then
        echo "$(date) - Removing yesterday's backup: $YESTERDAY" >> $LOG_FILE
        rm -rf "$BACKUP_DIR/$YESTERDAY" >> $LOG_FILE 2>&1
    fi
else
    echo "$(date) - Backup failed after $MAX_RETRIES attempts. Yesterday's backup not deleted." >> $LOG_FILE
fi

echo "$(date) - Backup process completed" >> $LOG_FILE
