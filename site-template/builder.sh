#!/bin/sh
# ------------------------------------------------------------------------------
# WP-HOSTING BUILDER SCRIPT (POSIX COMPLIANT)
# ------------------------------------------------------------------------------

# 1. Harvest per-page configs
if [ -f "/var/www/html/config-harvester.js" ]; then
    echo "🔍 Harvesting per-page Tailwind configs..."
    node /var/www/html/config-harvester.js || echo "❌ Harvester failed."
fi

# 2. Find Theme Directory
THEME_DIR=$(find /var/www/html/wp-content/themes -maxdepth 1 -mindepth 1 -type d | head -n 1)
if [ -z "$THEME_DIR" ]; then
    OUTPUT_PATH="/var/www/html/output.css"
else
    OUTPUT_PATH="$THEME_DIR/output.css"
fi

# 3. Search for Tailwind CLI
TAILWIND_CLI=""
if [ -f "/shared/node_modules/.bin/tailwindcss" ]; then
    TAILWIND_CLI="/shared/node_modules/.bin/tailwindcss"
elif [ -f "/shared/node_modules/tailwindcss/lib/cli.js" ]; then
    TAILWIND_CLI="/shared/node_modules/tailwindcss/lib/cli.js"
elif [ -f "/shared/node_modules/tailwindcss/bin/tailwindcss" ]; then
    TAILWIND_CLI="/shared/node_modules/tailwindcss/bin/tailwindcss"
fi

if [ -f "/var/www/html/input.css" ]; then
    if [ -n "$TAILWIND_CLI" ]; then
        echo "🚀 Starting Tailwind watcher (Offline Mode)..."
        echo "   Target: $OUTPUT_PATH"
        
        # Determine how to run it
        case "$TAILWIND_CLI" in
            *.js) node "$TAILWIND_CLI" -i /var/www/html/input.css -o "$OUTPUT_PATH" --watch --poll ;;
            *) "$TAILWIND_CLI" -i /var/www/html/input.css -o "$OUTPUT_PATH" --watch --poll ;;
        esac
    else
        echo "❌ ERROR: tailwind cli not found in /shared/node_modules"
        echo "Please run 'npm install tailwindcss' in /opt/wp-hosting/shared"
        tail -f /dev/null
    fi
else
    echo "⚠️ No input.css found in /var/www/html/"
    tail -f /dev/null
fi
