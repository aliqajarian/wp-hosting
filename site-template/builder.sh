#!/bin/sh
# ------------------------------------------------------------------------------
# WP-HOSTING BUILDER SCRIPT
# Handles Tailwind & Lucide Assets
# ------------------------------------------------------------------------------

# 1. Copy Lucide Assets (if available in shared volume)
if [ -f /shared/node_modules/lucide/dist/lucide-sprite.svg ] && [ ! -f lucide-sprite.svg ]; then
    cp /shared/node_modules/lucide/dist/lucide-sprite.svg ./
    echo "✅ Lucide sprite copied."
fi

if [ -f /shared/node_modules/lucide/dist/umd/lucide.min.js ] && [ ! -f lucide.min.js ]; then
    cp /shared/node_modules/lucide/dist/umd/lucide.min.js ./
    echo "✅ Lucide JS copied."
fi

# 2. Start Tailwind Watcher (or wait if no input.css)
if [ -f input.css ]; then
    echo "🚀 Starting Tailwind watcher..."
    npx tailwindcss -i ./input.css -o ./output.css --watch --poll
else
    echo "⚠️ No input.css found. Create one to start Tailwind compilation."
    echo "Waiting for assets..."
    tail -f /dev/null
fi
