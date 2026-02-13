#!/bin/bash

# ==========================================
# AUTO REPLICA SYNC
# ==========================================
# This script makes the Replica "Live" based on Site Configuration.
# It reads 'PRIMARY_NODE' and 'REPLICA_MODE' from each site's .env file.

BASE_DIR="/opt/wp-hosting"
SITES_DIR="$BASE_DIR/sites"
LOG_FILE="/var/log/wp-replica-sync.log"

# Get current Node ID (set during setup)
NODE_ID_FILE="$BASE_DIR/node_id"
if [ -f "$NODE_ID_FILE" ]; then
    CURRENT_NODE=$(cat "$NODE_ID_FILE")
else
    # Fallback if not set (legacy)
    CURRENT_NODE=$(hostname)
fi

echo ">>> [$(date)] Starting Auto-Replica Sync (Node: $CURRENT_NODE)..." >> $LOG_FILE

# 1. Fix Users & Permissions (Always needed for file sync)
bash "$BASE_DIR/scripts/import-replica.sh" >> $LOG_FILE 2>&1

# 2. Process Sites
for SITE_PATH in "$SITES_DIR"/*; do
    if [ -d "$SITE_PATH" ]; then
        SITE_NAME=$(basename "$SITE_PATH")
        ENV_FILE="$SITE_PATH/.env"
        
        if [ -f "$ENV_FILE" ]; then
            # Read Configuration
            PRIMARY_NODE=$(grep "PRIMARY_NODE=" "$ENV_FILE" | cut -d '=' -f2)
            REPLICA_MODE=$(grep "REPLICA_MODE=" "$ENV_FILE" | cut -d '=' -f2)
            
            # Default values if missing
            PRIMARY_NODE=${PRIMARY_NODE:-$CURRENT_NODE} # Assume self if not set
            REPLICA_MODE=${REPLICA_MODE:-active}        # Default to Active (Run everywhere)
            
            echo "--> Processing $SITE_NAME (Primary: $PRIMARY_NODE, Mode: $REPLICA_MODE)" >> $LOG_FILE
            
            # Logic: Should this site run here?
            SHOULD_RUN=false
            
            if [ "$PRIMARY_NODE" == "$CURRENT_NODE" ]; then
                # I am the Primary Node -> Always Run
                SHOULD_RUN=true
            elif [ "$REPLICA_MODE" == "active" ]; then
                # I am a Replica, but Mode is Active (GeoDNS/Failover) -> Run
                SHOULD_RUN=true
            else
                # Mode is 'passive' or 'off' -> Do Not Run
                SHOULD_RUN=false
            fi
            
            # Action
            if [ "$SHOULD_RUN" == "true" ]; then
                # Ensure running
                if ! docker ps --format '{{.Names}}' | grep -q "${SITE_NAME}_wp"; then
                    echo "    [STARTING] Starting container..." >> $LOG_FILE
                    cd "$SITE_PATH" && docker compose up -d >> $LOG_FILE 2>&1
                    
                    # Restore DB if needed (only on Non-Primary to avoid overwriting Main)
                    if [ "$PRIMARY_NODE" != "$CURRENT_NODE" ]; then
                         echo "    [RESTORE] Restoring replicated DB..." >> $LOG_FILE
                         bash "$BASE_DIR/scripts/restore-sites.sh" "$SITE_NAME" >> $LOG_FILE 2>&1
                    fi
                fi
            else
                # Ensure stopped (if mode switched to passive)
                if docker ps --format '{{.Names}}' | grep -q "${SITE_NAME}_wp"; then
                    echo "    [STOPPING] Use is Passive/Off. Stopping container..." >> $LOG_FILE
                    cd "$SITE_PATH" && docker compose stop >> $LOG_FILE 2>&1
                fi
            fi
        fi
    fi
done

echo ">>> [$(date)] Sync Complete." >> $LOG_FILE
