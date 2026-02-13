#!/bin/bash

# ==========================================
# CREATE SITE SCRIPT
# ==========================================
# Replaces create-site.sh with new metadata
# Supports 'Primary Node' and 'Replica Mode' from start.

SITE_NAME=$1
DOMAIN_NAME=$2
DB_NAME=$3
DB_USER=$3
SFTP_USER=$3
SFTP_PASS=$4

# Default Node ID (current hostname)
CURRENT_NODE=$(hostname) 
# Default Replica Mode (active)
REPLICA_MODE="active"

# ... (Original logic for create) ...

# Ensure sites dir exists
mkdir -p sites

if [ -z "$SITE_NAME" ] || [ -z "$DOMAIN_NAME" ]; then
    echo "Usage: ./create-site.sh <site_name> <domain> <db/user> <password>"
    exit 1
fi

SITE_DIR="sites/$SITE_NAME"
mkdir -p "$SITE_DIR"

# Generate Random Passwords
DB_PASS=$(openssl rand -base64 12)
WP_ADMIN_PASS=$(openssl rand -base64 12)

# Create .env file with Metadata
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
DB_ROOT_PASSWORD=$(openssl rand -base64 16)

# System User (Isolation)
SYS_USER=$SFTP_USER
SYS_UID=1001 # Will be updated by import script
SYS_GID=1001
SYS_PASSWORD=$SFTP_PASS

# WordPress Salts (Security)
AUTH_KEY='$(openssl rand -base64 48)'
SECURE_AUTH_KEY='$(openssl rand -base64 48)'
LOGGED_IN_KEY='$(openssl rand -base64 48)'
NONCE_KEY='$(openssl rand -base64 48)'
EOF

# Copy Template (assuming it exists)
cp -r site-template/* "$SITE_DIR/" 2>/dev/null || true
cp site-template/Dockerfile "$SITE_DIR/" 2>/dev/null || true

# Set Permissions
# ... (Original user creation logic) ...

echo ">>> Site Created: $SITE_NAME ($DOMAIN_NAME)"
echo "    Primary Node: $CURRENT_NODE"
echo "    Replica Mode: $REPLICA_MODE (Active)"
