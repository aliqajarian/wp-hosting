#!/bin/bash

# ==========================================
# REFRESH SITES SCRIPT
# ==========================================
# Updates all existing sites to the latest template standards:
# 1. Updates Dockerfile (Memcached, Curl-based downloads)
# 2. Updates docker-compose.yml (Adds Memcached service)
# 3. Rebuilds and restarts the sites.

BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEMPLATE_DIR="$BASE_DIR/site-template"
SITES_DIR="$BASE_DIR/sites"

echo ">>> Starting Site Refresh..."

if [ ! -d "$SITES_DIR" ] || [ -z "$(ls -A "$SITES_DIR")" ]; then
    echo "    [INFO] No sites found in $SITES_DIR to refresh."
    exit 0
fi

for SITE_PATH in "$SITES_DIR"/*; do
    if [ -d "$SITE_PATH" ] && [ -f "$SITE_PATH/docker-compose.yml" ]; then
        SITE_NAME=$(basename "$SITE_PATH")
        echo ">>> Refreshing Site: $SITE_NAME"

        # 1. Update Dockerfile
        echo "    Updating Dockerfile..."
        cp "$TEMPLATE_DIR/Dockerfile" "$SITE_PATH/Dockerfile"

        # 2. Update docker-compose.yml (Check if memcached service exists)
        if ! grep -q "memcached:" "$SITE_PATH/docker-compose.yml"; then
            echo "    Adding Memcached service to docker-compose.yml..."
            
            # This is a simple append/inject. For a robust solution, we'd use a parser.
            # Here we'll just inject the memcached block before 'networks:'
            
            MEMCACHED_BLOCK="  # ==========================================\n  # [CACHE] MEMCACHED\n  # ==========================================\n  memcached:\n    image: memcached:alpine\n    container_name: \${PROJECT_NAME}_memcached\n    restart: unless-stopped\n    networks:\n      - wp_net\n"
            
            sed -i "/networks:/i $MEMCACHED_BLOCK" "$SITE_PATH/docker-compose.yml"
            
            # Also add to depends_on
            sed -i "/depends_on:/a \      - memcached" "$SITE_PATH/docker-compose.yml"
        fi

        # 3. Pull/Rebuild and Restart
        echo "    Rebuilding and Restarting..."
        cd "$SITE_PATH"
        docker compose up -d --build
        cd "$BASE_DIR"
        
        echo "    [DONE] $SITE_NAME is now updated."
    fi
done

echo ">>> All sites have been refreshed successfully!"
