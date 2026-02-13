#!/bin/bash

# ==========================================
# ADD WORKER NODE TO MANAGER
# ==========================================
# Connects a remote VPS to:
# 1. Central Portainer (via API)
# 2. Central Homepage (via YAML config)

NODE_NAME=$1
NODE_IP=$2
PORTAINER_USER=$3
PORTAINER_PASS=$4

HOMEPAGE_CONFIG="../shared/homepage/services.yaml"
PORTAINER_API="http://localhost:9000/api"

if [ -z "$NODE_IP" ]; then
    echo "Usage: ./add-node.sh <name> <ip> <portainer-user> <portainer-pass>"
    exit 1
fi

echo ">>> Adding Node: $NODE_NAME ($NODE_IP)..."

# ------------------------------------------
# 1. CONNECT TO PORTAINER
# ------------------------------------------
echo "--> Connecting to Portainer..."

if ! command -v jq &> /dev/null; then
    echo "    Installing 'jq' for JSON parsing..."
    apt-get update && apt-get install -y jq
fi

# Authenticate & Get JWT
JWT=$(curl -s -X POST -H "Content-Type: application/json" \
    -d "{\"Username\":\"$PORTAINER_USER\",\"Password\":\"$PORTAINER_PASS\"}" \
    "$PORTAINER_API/auth" | jq -r .jwt)

if [ "$JWT" == "null" ] || [ -z "$JWT" ]; then
    echo "    [ERROR] Portainer Request failed. Invalid credentials or Portainer not ready."
else
    # Register Endpoint (Type 2 = Agent)
    # We use a sub-shell to capture the response code or body
    RESPONSE=$(curl -s -X POST -H "Authorization: Bearer $JWT" \
        -F "Name=$NODE_NAME" \
        -F "URL=$NODE_IP:9001" \
        -F "EndpointCreationType=2" \
        "$PORTAINER_API/endpoints")

    # Check for success (primitive check)
    if echo "$RESPONSE" | grep -q "\"Id\":"; then
        echo "    [SUCCESS] Node added to Portainer Environment."
    else
        echo "    [WARNING] Failed to add to Portainer. It might already exist."
        echo "    Response: $RESPONSE"
    fi
fi

# ------------------------------------------
# 2. ADD TO HOMEPAGE (Netdata)
# ------------------------------------------
echo "--> Adding to Homepage Dashboard..."

if [ ! -f "$HOMEPAGE_CONFIG" ]; then
    echo "    [ERROR] $HOMEPAGE_CONFIG not found. Are you on the Manager Node?"
else
    # Append a new group/service block to the end of the file
    # Caution: YAML is whitespace sensitive.
    
    cat <<EOF >> "$HOMEPAGE_CONFIG"

- $NODE_NAME:
    - Netdata ($NODE_NAME):
        icon: netdata.png
        href: "http://$NODE_IP:19999"
        description: "Status for $NODE_NAME"
        widget:
            type: netdata
            url: "http://$NODE_IP:19999"
            units: "%"
EOF

    echo "    [SUCCESS] Added $NODE_NAME to services.yaml"
    
    # Restart Homepage to pick up changes
    docker restart central_dashboard
    echo "    [INFO] Dashboard restarted."
fi

echo ">>> Node Registration Complete!"
