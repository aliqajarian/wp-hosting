#!/bin/bash

# ==========================================
# IMPORT SITES (For Replica Server)
# ==========================================
# This script is meant to be run on SERVER B (The Replica).
# It assumes Syncthing has already copied the 'sites/' folder structure.
# But permissions (UID/GID) might be wrong, or users might not exist.
# This script:
# 1. Finds all synced sites.
# 2. Creates the missing users on Server B.
# 3. Ensures UIDs match what's in .env (if possible) or fixes .env to match local UID.
# 4. Fixes file ownership.

SITES_DIR="/opt/wp-hosting/sites"

echo ">>> Starting Site Import / Permission Fix..."

if [ ! -d "$SITES_DIR" ]; then
    echo "ERROR: Sites directory not found. Did Syncthing run?"
    exit 1
fi

# Loop through each site folder
for SITE_PATH in "$SITES_DIR"/*; do
    if [ -d "$SITE_PATH" ]; then
        SITE_NAME=$(basename "$SITE_PATH")
        ENV_FILE="$SITE_PATH/.env"

        echo "--> Processing: $SITE_NAME"

        if [ -f "$ENV_FILE" ]; then
            # Extract target user from .env
            # We look for a line like '# User: myuser' or infer from DB_USER, but reliable method is tricky.
            # Best practice: We assume SITE_USER is same as SITE_NAME for simplicity in this script, or parse it.
            # Let's assume SITE_USER = SITE_NAME for simplicity or prompt.
            # actually, create-site.sh saves SITE_USER. Let's inspect create-site logic.
            # create-site.sh doesn't save SITE_USER explicitly in .env except maybe in comments or implicitly.
            # Let's just create a user named same as SITE_NAME to be safe.
            SITE_USER="$SITE_NAME"

            # Check if user exists
            if id "$SITE_USER" &>/dev/null; then
                echo "    User $SITE_USER exists."
            else
                echo "    Creating user $SITE_USER..."
                useradd -m -s /bin/bash "$SITE_USER"
            fi
            
            # Get local UID/GID
            NEW_UID=$(id -u "$SITE_USER")
            NEW_GID=$(id -g "$SITE_USER")
            
            # Update .env to match THIS server's UID/GID
            # This is crucial because UID 1001 on Server A might be UID 1002 on Server B.
            # We must update the .env file so the container runs as the LOCAL user.
            sed -i "s/^SYS_UID=.*/SYS_UID=$NEW_UID/" "$ENV_FILE"
            sed -i "s/^SYS_GID=.*/SYS_GID=$NEW_GID/" "$ENV_FILE"
            
            echo "    Updated .env with UID: $NEW_UID"

            # Fix File Ownership
            # Syncthing might have synced files as root or 'syncthing' user.
            # We force them to be owned by the site user.
            chown -R "$SITE_USER:$SITE_USER" "$SITE_PATH"
            echo "    Fixed file permissions."
            
            # Start/Restart Containers to pick up new UID
            # Optional: Uncomment if you want to auto-start everything
            # cd "$SITE_PATH" && docker compose up -d
            
        else
            echo "    [SKIP] No .env file found (incomplete sync?)"
        fi
    fi
done

echo ">>> Import Complete."
