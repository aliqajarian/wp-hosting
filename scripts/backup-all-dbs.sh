#!/bin/bash

# ==========================================
# BACKUP ALL DATABASES
# ==========================================
# Loops through all running db containers and dumps SQL to the site folder.
# Syncthing will then replicate these .sql files to the replica server.

SITES_DIR="/opt/wp-hosting/sites"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")

echo ">>> Starting Database Dump..."

# Loop through all site directories
for SITE_PATH in "$SITES_DIR"/*; do
    if [ -d "$SITE_PATH" ]; then
        SITE_NAME=$(basename "$SITE_PATH")
        
        # Check if DB container is running
        CONTAINER="${SITE_NAME}_db"
        if docker ps --format '{{.Names}}' | grep -q "^${CONTAINER}$"; then
            echo "--> Backing up: $SITE_NAME"
            
            # Create backup dir inside site folder (so it gets synced)
            BACKUP_DIR="$SITE_PATH/backups"
            mkdir -p "$BACKUP_DIR"
            
            # Get DB credentials from .env
            DB_USER=$(grep "DB_USER=" "$SITE_PATH/.env" | cut -d '=' -f2)
            DB_PASS=$(grep "DB_PASSWORD=" "$SITE_PATH/.env" | cut -d '=' -f2)
            DB_NAME=$(grep "DB_NAME=" "$SITE_PATH/.env" | cut -d '=' -f2)
            
            # Dump
            # We use docker exec to run mysqldump inside the container
            docker exec "$CONTAINER" mysqldump -u"$DB_USER" -p"$DB_PASS" "$DB_NAME" > "$BACKUP_DIR/latest.sql"
            
            # Keep a timestamped copy too?
            # cp "$BACKUP_DIR/latest.sql" "$BACKUP_DIR/db_$TIMESTAMP.sql"
            
            echo "    Saved to: $BACKUP_DIR/latest.sql"
        else
            echo "--> Skipping $SITE_NAME (Container not running)"
        fi
    fi
done

echo ">>> Database Backup Complete."
