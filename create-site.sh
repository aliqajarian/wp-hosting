#!/bin/bash

# ==========================================
# CREATE SITE SCRIPT (Global-Ready)
# ==========================================
# Supports 'Primary Node' and 'Replica Mode' from start.
# Automatically detects location and uses mirrors if in Iran.

SITE_NAME=$1
DOMAIN_NAME=$2
DB_NAME=$3
DB_USER=$3
SFTP_USER=$3
SFTP_PASS=$4

# Paths
BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SITE_DIR="$BASE_DIR/sites/$SITE_NAME"

# Default Node ID (current hostname)
CURRENT_NODE=$(hostname) 
# Default Replica Mode (active)
REPLICA_MODE="active"

if [ -z "$SITE_NAME" ] || [ -z "$DOMAIN_NAME" ]; then
    echo "Usage: ./create-site.sh <site_name> <domain> <db/user> <password>"
    exit 1
fi

echo ">>> Creating site $SITE_NAME ($DOMAIN_NAME)..."

# 1. Location Detection (Smart Mirror)
echo ">>> Checking location for optimal mirrors..."
COUNTRY=$(curl -s --connect-timeout 2 http://ip-api.com/line?fields=countryCode || echo "UNKNOWN")
BUILD_ARGS=""
if [ "$COUNTRY" == "IR" ]; then
    echo "    [DETECTED: IRAN] Setting up ArvanCloud mirrors for build..."
    BUILD_ARGS="--build-arg MIRROR=mirror.arvancloud.ir"
else
    echo "    [DETECTED: GLOBAL] Using official repositories."
fi

# 2. Create directory and copy template
mkdir -p "$SITE_DIR"
cp -r "$BASE_DIR/site-template/"* "$SITE_DIR/" 2>/dev/null || true
cp "$BASE_DIR/site-template/Dockerfile" "$SITE_DIR/" 2>/dev/null || true

# 3. Generate Random Passwords
DB_PASS=$(openssl rand -base64 12)
WP_ADMIN_PASS=$(openssl rand -base64 12)
ROOT_DB_PASS=$(openssl rand -base64 16)

# 4. Create .env file with Metadata
cat <<EOF > "$SITE_DIR/.env"
# Site Configuration
PROJECT_NAME=$SITE_NAME
DOMAIN_NAME=$DOMAIN_NAME

# Replication Metadata
PRIMARY_NODE=$CURRENT_NODE
REPLICA_MODE=$REPLICA_MODE

# Database Credentials
DB_NAME=$DB_NAME
DB_USER=$DB_USER
DB_PASSWORD=$DB_PASS
DB_ROOT_PASSWORD=$ROOT_DB_PASS

# System User (Isolation)
SYS_USER=$SFTP_USER
SYS_UID=1001 
SYS_GID=1001
SYS_PASSWORD=$SFTP_PASS

# WordPress Salts (Security)
AUTH_KEY='$(openssl rand -base64 48)'
SECURE_AUTH_KEY='$(openssl rand -base64 48)'
LOGGED_IN_KEY='$(openssl rand -base64 48)'
NONCE_KEY='$(openssl rand -base64 48)'
EOF

# 5. Set Permissions (Host side)
echo ">>> Setting permissions for user 1001..."
chown -R 1001:1001 "$SITE_DIR"
chmod -R 775 "$SITE_DIR"

# 6. Register with Dashboard
HOMEPAGE_FILE="$BASE_DIR/shared/homepage/services.yaml"
if [ -f "$HOMEPAGE_FILE" ]; then
    if ! grep -q "$DOMAIN_NAME" "$HOMEPAGE_FILE"; then
        echo ">>> Registering with Dashboard..."
        if ! grep -q -- "- Sites:" "$HOMEPAGE_FILE"; then
            echo -e "\n- Sites:" >> "$HOMEPAGE_FILE"
        fi
        cat <<EOF >> "$HOMEPAGE_FILE"
    - $SITE_NAME:
        icon: wordpress.png
        href: "https://$DOMAIN_NAME"
        description: "$DOMAIN_NAME (Local)"
        widget:
            type: wordpress
            url: http://${SITE_NAME}_wp
EOF
    fi
fi

# 7. Launch Site
echo ">>> Launching containers for $SITE_NAME..."
cd "$SITE_DIR"
if [ ! -z "$BUILD_ARGS" ]; then
    docker compose build $BUILD_ARGS
fi
docker compose up -d

echo ""
echo -e "\033[0;32m✅ SUCCESS: Site Created & Started!\033[0m"
echo "    Site Name:    $SITE_NAME"
echo "    Domain:       $DOMAIN_NAME"
echo "    Primary Node: $CURRENT_NODE"
echo "    Replica Mode: $REPLICA_MODE"
echo ""
echo "Manage this site via: ./manage.sh -> Option 5"
