#!/bin/bash
# ==========================================
# WP-HOSTING ENTRYPOINT
# ==========================================
# Installs Persian language on first boot, then hands off to WordPress.

# Install Persian language pack on first boot
if [ ! -f /var/www/html/.lang-installed ] && [ -f /var/www/html/wp-includes/version.php ]; then
    echo "[WP-HOSTING] Installing Persian language pack..."
    # Wait for DB to be ready
    sleep 3
    wp language core install fa_IR --allow-root 2>/dev/null
    wp site switch-language fa_IR --allow-root 2>/dev/null
    if [ $? -eq 0 ]; then
        touch /var/www/html/.lang-installed
        echo "[WP-HOSTING] Persian language installed successfully!"
    else
        echo "[WP-HOSTING] Language install skipped (DB not ready yet, will retry on next restart)"
    fi
fi

# Hand off to the original WordPress entrypoint
exec docker-entrypoint.sh apache2-foreground
