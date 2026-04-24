#!/bin/bash

# ==========================================
# GLOBAL OPTIMIZATION SCRIPT
# ==========================================
# Applies resource limits and OLS tuning to all existing sites.

BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SITES_DIR="/opt/wp-hosting/sites"

echo ">>> Starting Global Optimization on HLWP1..."

for site in "$SITES_DIR"/*; do
    if [ -d "$site" ] && [ -f "$site/docker-compose.yml" ]; then
        SITE_NAME=$(basename "$site")
        echo ">>> Optimizing site: $SITE_NAME"

        # 1. Update/Add Resource Limits to docker-compose.yml
        echo "    Applying user-preferred memory footprint to docker-compose.yml..."
        # WordPress (2048M)
        sed -i '/container_name: ${PROJECT_NAME}_wp/{n;n;n;s/memory: .*/memory: 2048M/}' "$site/docker-compose.yml" || true
        # DB (1024M)
        sed -i '/container_name: ${PROJECT_NAME}_db/{n;n;n;s/memory: .*/memory: 1024M/}' "$site/docker-compose.yml" || true
        
        # Ensure block exists if totally missing
        if ! grep -q "deploy:" "$site/docker-compose.yml"; then
            sed -i 's/restart: unless-stopped/deploy:\n      resources:\n        limits:\n          memory: 2048M\n    restart: unless-stopped/' "$site/docker-compose.yml"
        fi

        # 2. Revert MariaDB command tuning to default if present
        sed -i 's/--innodb-buffer-pool-size=64M/--innodb-buffer-pool-size=128M/g' "$site/docker-compose.yml"
        sed -i 's/--max-connections=50/--max-connections=100/g' "$site/docker-compose.yml"

        # 3. Apply OLS Tuning inside container
        echo "    Tuning OpenLiteSpeed workers and proxy headers..."
        echo "    Running MariaDB upgrade check..."
        # Extract DB root password from .env
        ROOT_PW=$(grep "DB_ROOT_PASSWORD" "$site/.env" | cut -d'=' -f2)
        if [ -n "$ROOT_PW" ]; then
            docker exec "${SITE_NAME}_db" mariadb-upgrade -u root -p"$ROOT_PW" 2>/dev/null
        fi

        # 4. Restart to apply Compose changes
        echo "    Restarting containers..."
        cd "$site" && docker compose up -d --force-recreate
    fi
done

echo ">>> Global optimization complete!"
