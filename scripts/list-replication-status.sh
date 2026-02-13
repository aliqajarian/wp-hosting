#!/bin/bash

# ==========================================
# LIST REPLICATION STATUS
# ==========================================
# Displays a table of all sites and their replication configuration.

BASE_DIR="/opt/wp-hosting"
SITES_DIR="$BASE_DIR/sites"
current_node=$(hostname)

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

printf "${BLUE}%-20s %-20s %-15s %-15s %-15s${NC}\n" "SITE" "PRIMARY NODE" "REPLICA MODE" "LOCAL STATUS" "ACTION"
echo "-----------------------------------------------------------------------------------------"

for SITE_PATH in "$SITES_DIR"/*; do
    if [ -d "$SITE_PATH" ]; then
        SITE_NAME=$(basename "$SITE_PATH")
        ENV_FILE="$SITE_PATH/.env"
        
        if [ -f "$ENV_FILE" ]; then
            PRI=$(grep "PRIMARY_NODE=" "$ENV_FILE" | cut -d '=' -f2)
            MODE=$(grep "REPLICA_MODE=" "$ENV_FILE" | cut -d '=' -f2)
            
            # Local Docker Status
            if docker ps --format '{{.Names}}' | grep -q "${SITE_NAME}_wp"; then
                STATUS="${GREEN}RUNNING${NC}"
            else
                STATUS="${RED}STOPPED${NC}"
            fi
            
            # Determine Action taken by Auto-Sync
            # If Primary == Current -> Should Run
            # If Mode == active -> Should Run
            ACTION="-"
            
            if [ "$PRI" == "$current_node" ]; then
                ACTION="(Primary)"
            elif [ "$MODE" == "active" ]; then
                ACTION="(Replica)"
            else
                ACTION="(Passive)"
            fi

            printf "%-20s %-20s %-15s %-15b %-15s\n" "$SITE_NAME" "$PRI" "$MODE" "$STATUS" "$ACTION"
        fi
    fi
done
echo ""
