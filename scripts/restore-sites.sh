#!/bin/bash

# ==========================================
# RESTORE SITES (Replica Recovery)
# ==========================================
# This script should be run on a REPLICA server.
# It checks if any SITES folder contains a 'backups/latest.sql'.
# If the corresponding DB container exists, it RESTORES the DB.

SITES_DIR="/opt/wp-hosting/sites"
# Detect if we should use a replica domain suffix
# e.g. if main is "site.com", replica becomes "site.replica.com"
# For now, we assume the user might want to access the replica directly to test it.
REPLICA_DOMAIN_SUFFIX="replica.yourdomain.com" 

echo ">>> Starting Database Restore Process..."

# Loop through sites
for SITE_PATH in "$SITES_DIR"/*; do
    if [ -d "$SITE_PATH" ]; then
        SITE_NAME=$(basename "$SITE_PATH")
        ENV_FILE="$SITE_PATH/.env"
        
        # ---------------------------------------------------------
        # DOMAIN HANDLING (Replica Mode)
        # ---------------------------------------------------------
        # If we are on a replica, we might want to override the domain 
        # so we can access it (e.g. client1.replica.com) instead of client1.com
        # This prevents DNS conflict if both are online, or allows testing.
        
        # Check if we are actually on a replica node (simple check for now)
        # We can check if hostname contains 'replica' or user set a flag file.
        # Let's check for a marker file created by setup-ubuntu.sh or manually.
        
        if [ -f "/opt/wp-hosting/replica_mode_active" ]; then
             echo "--> [REPLICA MODE] Checking Domain for $SITE_NAME"
             # Read original domain
             ORIG_DOMAIN=$(grep "DOMAIN_NAME=" "$ENV_FILE" | cut -d '=' -f2)
             
             # Construct new domain: site-name.replica-server.com
             # We need to know the replica server's base domain.
             # Let's assume the user configured a wildcard like *.replica.myhost.com pointing to this server.
             
             # For now, let's just append "-replica" to the original domain host? 
             # No, that requires DNS. 
             # Best approach: Traefik handles multiple routers. We can add a secondary router?
             # Or just replace the domain in .env temporarily?
             
             # If we replace it in .env, the next sync might overwrite it?
             # Syncthing is continuous.
             # BETTER: Add a docker-compose.override.yml for replica?
             # Complex.
             
             # SIMPLE SOLUTON: The replica serves the SAME domain.
             # You switch traffic by changing DNS (Cloudflare/Godaddy) from IP A to IP B.
             # This is a Failover cluster, not a staging environment.
             # So we do NOTHING to the domain.
             
             echo "    Domain is: $ORIG_DOMAIN (Standard Failover Configuration)"
        fi

        # ---------------------------------------------------------
        # DATABASE RESTORE
        # ---------------------------------------------------------
        
        # Check running container
        CONTAINER="${SITE_NAME}_db"
        
        # We need to ensure container is running first (auto-replica starts it)
        
        if docker ps --format '{{.Names}}' | grep -q "^${CONTAINER}$"; then
            echo "--> Restoring DB: $SITE_NAME"
            
            BACKUP_FILE="$SITE_PATH/backups/latest.sql"
            LAST_RESTORE_FILE="$SITE_PATH/backups/last_restore.txt"
            
            if [ -f "$BACKUP_FILE" ]; then
                # Check if backup is newer than last restore to avoid loop
                if [ -f "$LAST_RESTORE_FILE" ] && [ "$BACKUP_FILE" -ot "$LAST_RESTORE_FILE" ]; then
                    echo "    [SKIP] Backup is older than last restore."
                    continue
                fi
            
                # Get DB credentials
                DB_USER=$(grep "DB_USER=" "$ENV_FILE" | cut -d '=' -f2)
                DB_PASS=$(grep "DB_PASSWORD=" "$ENV_FILE" | cut -d '=' -f2)
                DB_NAME=$(grep "DB_NAME=" "$ENV_FILE" | cut -d '=' -f2)
                
                echo "    Importing SQL..."
                
                # Restore
                cat "$BACKUP_FILE" | docker exec -i "$CONTAINER" mysql -u"$DB_USER" -p"$DB_PASS" "$DB_NAME"
                
                # SEARCH & REPLACE (Critical for DB Sync)
                # If we were changing domains, we would do it here using WP-CLI.
                # docker exec -u www-data "${SITE_NAME}_wp" wp search-replace "old" "new"
                
                echo "    [SUCCESS] Database Restored."
                touch "$LAST_RESTORE_FILE"
                
            else
                echo "    [SKIP] No backup found."
            fi
        fi
    fi
done

echo ">>> Restore Complete."
