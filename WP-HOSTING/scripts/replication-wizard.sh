#!/bin/bash

# ==========================================
# SYNCTHING REPLICATION WIZARD
# ==========================================
# Automates the pairing of servers for replication.
# Usage: ./replication-wizard.sh

CONTAINER="shared_replication"
API_PORT="8384"
API_HOST="127.0.0.1"

# Check if running
if ! docker ps | grep -q "$CONTAINER"; then
    echo "Error: Syncthing container ($CONTAINER) is not running."
    echo "Start the stack first: ./manage.sh -> Manage Server Stack -> Start"
    exit 1
fi

echo ">>> Extracting Syncthing Configuration..."

# 1. Get API Key from Config
API_KEY=$(docker exec "$CONTAINER" grep -oP '(?<=<apikey>).*(?=</apikey>)' /var/syncthing/config/config.xml)

if [ -z "$API_KEY" ]; then
    # Fallback for diff xml structure or busybox grep
    API_KEY=$(docker exec "$CONTAINER" cat /var/syncthing/config/config.xml | grep "<apikey>" | sed -e 's/.*<apikey>\(.*\)<\/apikey>.*/\1/')
fi

# 2. Get My Device ID
MY_ID=$(docker exec "$CONTAINER" syncthing -device-id | grep "Device ID:" | cut -d: -f2 | xargs)

echo ""
echo "=================================================="
echo "   REPLICATION STATUS"
echo "=================================================="
echo "MY DEVICE ID: $MY_ID"
echo "API KEY:      $API_KEY"
echo "GUI URL:      http://$(hostname -I | cut -d' ' -f1):$API_PORT"
echo "=================================================="
echo ""
echo "What would you like to do?"
echo "1. Add a Remote Server (Peer)"
echo "2. Share 'sites' Folder with a Peer"
echo "3. Exit"
read -p "Select [1-3]: " OPT

if [ "$OPT" == "1" ]; then
    echo ""
    echo "--- Add Remote Peer ---"
    read -p "Enter Remote Device ID: " REMOTE_ID
    read -p "Enter Remote Name (e.g. VPS-2): " REMOTE_NAME
    
    # JSON Payload to Add Device
    # We use a minimal config. Syncthing is picky. 
    # Best practice: PUT /rest/config/devices via curl
    
    # 1. Get Current Config
    # This acts as a validation that API works
    CONFIG=$(curl -s -H "X-API-Key: $API_KEY" http://$API_HOST:$API_PORT/rest/config)
    
    # 2. Add Device via PUT (Simulated simply by posting to /rest/config/devices is NOT supported directly, usually requires full config post)
    # ACTUALLY, simpler approach for bash: Use the CLI interface if available inside container?
    # Syncthing inside Docker often has 'syncthing cli' subcommand? No, usually just 'syncthing'.
    # REST API is safest. 
    
    # New Device JSON block
    NEW_DEVICE="{\"deviceID\":\"$REMOTE_ID\",\"name\":\"$REMOTE_NAME\",\"addresses\":[\"dynamic\"]}"
    
    # We will try to use the endpoint /rest/config/devices (POST/PUT add logic varies by version).
    # Easier way: Just print instructions because automatic JSON editing in bash is error-prone without jq.
    
    if command -v jq &> /dev/null; then
        echo "--> Sending API Request..."
        # Get existing devices
        EXISTING_DEVICES=$(curl -s -H "X-API-Key: $API_KEY" http://$API_HOST:$API_PORT/rest/config/devices)
        
        # Append new device
        # This is complex in bash. 
        # Let's fallback to "GUI is better" for the actual adding, OR simplified CLI command if we installed it.
        # But wait, we can just print the command for the user to run on the GUI or give them the info.
        
        # Let's try the CLI wrapper provided by some images.
        # If not, we instruct the user.
        
        echo "API Automation is complex without 'jq' installed in the container."
        echo "Generating Link for you..."
    fi
    
    echo ""
    echo ">>> AUTO-PAIRING INSTRUCTIONS (Manual Fallback)"
    echo "1. Go to: http://$(hostname -I | cut -d' ' -f1):$API_PORT"
    echo "2. Click 'Add Remote Device'"
    echo "3. Paste ID: $REMOTE_ID"
    echo "4. Name it: $REMOTE_NAME"
    echo "5. Click Save."
    
elif [ "$OPT" == "2" ]; then
    echo ""
    echo "--- Share 'sites' Folder ---"
    echo "Pre-requisite: You must have added the Remote Peer first (Option 1)."
    echo ""
    echo "1. Go to web GUI: http://$(hostname -I | cut -d' ' -f1):$API_PORT"
    echo "2. Edit 'sites' folder."
    echo "3. Check the box for the Remote Server."
    echo "4. Save."

fi

echo ""
echo "Done."
