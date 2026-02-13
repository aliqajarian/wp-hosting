#!/bin/bash

# ==========================================
# CLUSTER HEALTH CHECK
# ==========================================
# Verifies critical connections without needing a browser.

GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

echo ">>> Cluster Health Check"

# 1. Check Internet
echo -n "1. Internet Connectivity: "
if ping -c 1 8.8.8.8 &> /dev/null; then
    echo -e "${GREEN}OK${NC}"
else
    echo -e "${RED}FAIL${NC}"
fi

# 2. Check Local Docker
echo -n "2. Docker Engine:         "
if docker ps &> /dev/null; then
    echo -e "${GREEN}OK${NC}"
else
    echo -e "${RED}FAIL${NC} (Docker not running)"
    exit 1
fi

# 3. Check Syncthing (Replication)
echo -n "3. Replication Service:   "
if docker ps | grep -q "shared_replication"; then
    # Check Connection Count via API (if grep works)
    # Simple check: logs "Connected to device"
    if docker logs shared_replication --tail 100 2>&1 | grep -q "Connected to device"; then
        echo -e "${GREEN}CONNECTED${NC} (Peers found)"
    else
        echo -e "${GREEN}RUNNING${NC} (No active storage peers seen in logs recently)"
    fi
else
    echo -e "${RED}STOPPED${NC}"
fi

# 4. Check Agent (if Node)
if [ -f "/opt/wp-hosting/node_id" ]; then
    echo -n "4. Portainer Agent:       "
    if docker ps | grep -q "shared_portainer_agent"; then
         echo -e "${GREEN}OK${NC} (Ready for Manager)"
    else
         echo -e "${RED}FAIL${NC}"
    fi
fi

# 5. Check Manager Services (if Manager)
if [ -f "shared/docker-compose-central.yml" ] && docker ps | grep -q "central_dashboard"; then
    echo -n "5. Dashboard (Panel):     "
    if curl -Ifs http://localhost:3000 &> /dev/null; then
        echo -e "${GREEN}ONLINE${NC}"
    else
        echo -e "${RED}ERROR${NC} (Service running but HTTP failed)"
    fi
fi

echo ""
echo "Done."
