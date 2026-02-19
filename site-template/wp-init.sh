#!/bin/bash
# ==========================================
# WP-HOSTING ENTRYPOINT
# ==========================================
# Installs IonCube, WP-CLI, and Persian language on first boot.
# All downloads happen at RUNTIME (not during Docker build)
# so they work regardless of network restrictions during build.

MARKER="/usr/local/etc/.wp-hosting-initialized"

if [ ! -f "$MARKER" ]; then
    echo "[WP-HOSTING] First boot — installing components..."

    # --- 1. Install IonCube Loader ---
    echo "[WP-HOSTING] Installing IonCube Loader..."
    PHP_VER=$(php -r 'echo PHP_MAJOR_VERSION . "." . PHP_MINOR_VERSION;')
    EXT_DIR=$(php -r "echo ini_get('extension_dir');")
    
    curl -sL --connect-timeout 15 --max-time 120 --retry 3 \
        -o /tmp/ioncube.tar.gz \
        "https://downloads.ioncube.com/loader_downloads/ioncube_loaders_lin_x86-64.tar.gz"
    
    if [ -f /tmp/ioncube.tar.gz ] && [ -s /tmp/ioncube.tar.gz ]; then
        tar -xzf /tmp/ioncube.tar.gz -C /tmp/
        cp /tmp/ioncube/ioncube_loader_lin_${PHP_VER}*.so "${EXT_DIR}/ioncube_loader_lin_${PHP_VER}.so" 2>/dev/null
        echo "zend_extension=ioncube_loader_lin_${PHP_VER}.so" > /usr/local/etc/php/conf.d/00-ioncube.ini
        rm -rf /tmp/ioncube /tmp/ioncube.tar.gz
        echo "[WP-HOSTING] IonCube installed!"
    else
        echo "[WP-HOSTING] IonCube download failed (will retry next restart)"
        rm -f /tmp/ioncube.tar.gz
    fi

    # --- 2. Install WP-CLI ---
    echo "[WP-HOSTING] Installing WP-CLI..."
    curl -sL --connect-timeout 15 --max-time 60 --retry 3 \
        -o /usr/local/bin/wp \
        "https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar"
    
    if [ -f /usr/local/bin/wp ] && [ -s /usr/local/bin/wp ]; then
        chmod +x /usr/local/bin/wp
        echo "[WP-HOSTING] WP-CLI installed!"
    else
        echo "[WP-HOSTING] WP-CLI download failed (will retry next restart)"
        rm -f /usr/local/bin/wp
    fi

    # Mark as initialized (only if both succeeded)
    if [ -f /usr/local/bin/wp ] && [ -f "${EXT_DIR}/ioncube_loader_lin_${PHP_VER}.so" ]; then
        touch "$MARKER"
        echo "[WP-HOSTING] All components installed successfully!"
    fi
fi

# --- 3. Install Persian language (needs WordPress + DB to be ready) ---
if [ ! -f /var/www/html/.lang-installed ] && [ -f /usr/local/bin/wp ]; then
    (
        # Run in background so it doesn't block Apache startup
        sleep 15
        if [ -f /var/www/html/wp-includes/version.php ]; then
            echo "[WP-HOSTING] Installing Persian language pack..."
            wp language core install fa_IR --allow-root 2>/dev/null
            wp site switch-language fa_IR --allow-root 2>/dev/null
            if [ $? -eq 0 ]; then
                touch /var/www/html/.lang-installed
                echo "[WP-HOSTING] Persian language installed!"
            fi
        fi
    ) &
fi

# Hand off to the original WordPress entrypoint
exec docker-entrypoint.sh apache2-foreground
