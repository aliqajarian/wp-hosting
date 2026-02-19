#!/bin/bash

# ==========================================
# DELETE SITE SCRIPT
# ==========================================
# Safely removes site containers, files, and dashboard entries.

SITE_NAME=$1
BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SITE_DIR="$BASE_DIR/sites/$SITE_NAME"

if [ -z "$SITE_NAME" ]; then
    echo "Usage: $0 <site_name>"
    exit 1
fi

echo -e "\033[0;31m!!! WARNING: You are about to PERMANENTLY DELETE site: $SITE_NAME !!!\033[0m"
read -p "Are you absolutely sure? [y/N]: " CONFIRM
if [[ ! $CONFIRM =~ ^[Yy]$ ]]; then
    echo "Deletion cancelled."
    exit 0
fi

# 1. Stop and remove containers
if [ -d "$SITE_DIR" ]; then
    echo ">>> Stopping and removing containers..."
    cd "$SITE_DIR" && docker compose down -v
fi

# 2. Remove directory
echo ">>> Removing site files..."
rm -rf "$SITE_DIR"

# 3. Remove from Dashboard (Homepage)
HOMEPAGE_FILE="$BASE_DIR/shared/homepage/services.yaml"
if [ -f "$HOMEPAGE_FILE" ]; then
    echo ">>> Cleaning up dashboard entry..."
    # Simple logic: remove the block starting with the site name
    # This is a bit tricky with sed, we'll use a temp file
    sed -i "/- $SITE_NAME:/,+7d" "$HOMEPAGE_FILE"
fi

echo -e "\033[0;32m✅ SUCCESS: Site $SITE_NAME has been deleted.\033[0m"
