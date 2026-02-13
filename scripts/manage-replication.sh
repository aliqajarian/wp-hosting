#!/bin/bash

# ==========================================
# MANAGE SITE REPLICATION
# ==========================================
# Allows changing a site's replication strategy.
# Options:
# 1. Promote to Primary (Makes THIS server the main one)
# 2. Set Replica Mode (Active/Passive/Off)
# Usage: ./manage-replication.sh <site_name>

SITE_NAME=$1
SITES_DIR="/opt/wp-hosting/sites"
SITE_DIR="$SITES_DIR/$SITE_NAME"

if [ -z "$SITE_NAME" ]; then
    echo "Usage: $0 <site_name>"
    exit 1
fi

if [ ! -d "$SITE_DIR" ]; then
    echo "Error: Site $SITE_NAME not found."
    exit 1
fi

ENV_FILE="$SITE_DIR/.env"
CURRENT_NODE=$(hostname)
OLD_PRIMARY=$(grep "PRIMARY_NODE=" "$ENV_FILE" | cut -d '=' -f2)
OLD_MODE=$(grep "REPLICA_MODE=" "$ENV_FILE" | cut -d '=' -f2)

echo ">>> Replication Manager: $SITE_NAME"
echo "    Primary Node: $OLD_PRIMARY"
echo "    Current Mode: $OLD_MODE"
echo ""
echo "1. Change Primary Node (Failover)"
echo "2. Change Replica Mode (Active/Passive)"
echo "3. Exit"
read -p "Select: " OPT

if [ "$OPT" == "1" ]; then
    echo ""
    echo "Current Primary is: $OLD_PRIMARY"
    echo "New Primary Node ID (hostname):"
    echo " - Current Server ID: $CURRENT_NODE"
    read -p "Type target node ID [$CURRENT_NODE]: " NEW_PRIMARY
    NEW_PRIMARY=${NEW_PRIMARY:-$CURRENT_NODE}
    
    # Update .env
    # We use sed to replace PRIMARY_NODE=xxx
    sed -i "s/^PRIMARY_NODE=.*/PRIMARY_NODE=$NEW_PRIMARY/" "$ENV_FILE"
    
    echo "    [UPDATED] Primary Node set to: $NEW_PRIMARY"
    echo "    Note: This change will replicate to other servers shortly."
    echo "          Run 'Option 7 -> Auto-Sync' on other servers to apply changes."

elif [ "$OPT" == "2" ]; then
    echo ""
    echo "Current Mode is: $OLD_MODE"
    echo "Select New Mode:"
    echo "1. active  (Always Run - Use for GeoDNS/Failover)"
    echo "2. passive (Synced but Stopped - Use for Cold Backup)"
    echo "3. off     (Do Not Run - Single Server)"
    read -p "Select [1-3]: " MODE_OPT
    
    case $MODE_OPT in
        1) NEW_MODE="active" ;;
        2) NEW_MODE="passive" ;;
        3) NEW_MODE="off" ;;
    esac
    
    sed -i "s/^REPLICA_MODE=.*/REPLICA_MODE=$NEW_MODE/" "$ENV_FILE"
    
    echo "    [UPDATED] Replica Mode set to: $NEW_MODE"
fi
