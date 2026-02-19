#!/bin/bash

# ==========================================
# LOCALIZE GOOGLE FONTS
# ==========================================
# Downloads Google Fonts (WOFF2) and CSS to the active theme's fonts/ folder.
# Rewrites CSS to use local paths. No external requests at runtime.
#
# Usage: ./localize-font.sh <site-name> "<google-fonts-css-url>"
# Example: ./localize-font.sh client1 "https://fonts.googleapis.com/css2?family=Vazirmatn:wght@100..900&display=swap"

SITE_NAME=$1
FONT_URL=$2

if [ -z "$SITE_NAME" ] || [ -z "$FONT_URL" ]; then
    echo "Usage: $0 <site-name> \"<google-fonts-css-url>\""
    echo "Example: $0 client1 \"https://fonts.googleapis.com/css2?family=Vazirmatn:wght@400;700&display=swap\""
    exit 1
fi

CONTAINER="${SITE_NAME}_wp"

# Verify container is running
if ! docker ps --format '{{.Names}}' | grep -q "^${CONTAINER}$"; then
    echo "[ERROR] Container '$CONTAINER' is not running."
    echo "Start it first: cd sites/$SITE_NAME && docker compose up -d"
    exit 1
fi

echo ">>> Localizing Fonts for $SITE_NAME..."

# --- Step 1: Find the active theme directory ---
echo "--> Detecting active theme..."
ACTIVE_THEME=$(docker exec -u root "$CONTAINER" bash -c "
    if [ -f /var/www/html/wp-includes/version.php ]; then
        # Try to get theme from database via wp-cli
        THEME=\$(wp theme list --status=active --field=name --allow-root 2>/dev/null | head -1)
        if [ -n \"\$THEME\" ]; then
            echo \"\$THEME\"
        else
            # Fallback: find first non-default theme
            ls /var/www/html/wp-content/themes/ | grep -v twenty | head -1
        fi
    fi
")

if [ -z "$ACTIVE_THEME" ]; then
    echo "[WARN] Could not auto-detect theme. Listing available themes:"
    docker exec "$CONTAINER" ls /var/www/html/wp-content/themes/
    read -p "Enter theme folder name: " ACTIVE_THEME
fi

THEME_DIR="/var/www/html/wp-content/themes/$ACTIVE_THEME"
FONT_DIR="$THEME_DIR/fonts"
echo "--> Using theme: $ACTIVE_THEME"
echo "--> Font directory: $FONT_DIR"

# --- Step 2: Create the download script and execute inside the container ---
echo "--> Downloading fonts inside container..."

docker exec -u root "$CONTAINER" bash -c "
set -e

FONT_DIR='$FONT_DIR'
FONT_URL='$FONT_URL'

mkdir -p \"\$FONT_DIR\"

# 1. Download the CSS file (with Chrome User-Agent to get WOFF2 format)
echo '    Fetching CSS from Google Fonts...'
if command -v wget &>/dev/null; then
    wget -q -U 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36' \
        -O \"\$FONT_DIR/google-fonts-original.css\" \"\$FONT_URL\"
elif command -v curl &>/dev/null; then
    curl -s -A 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36' \
        -o \"\$FONT_DIR/google-fonts-original.css\" \"\$FONT_URL\"
else
    echo '[ERROR] Neither wget nor curl found in container!'
    exit 1
fi

if [ ! -s \"\$FONT_DIR/google-fonts-original.css\" ]; then
    echo '[ERROR] Failed to download CSS from Google Fonts.'
    exit 1
fi

echo '    CSS downloaded successfully.'

# 2. Extract all font file URLs and download them
echo '    Downloading WOFF2 font files...'
counter=0
cp \"\$FONT_DIR/google-fonts-original.css\" \"\$FONT_DIR/fonts.css\"

# Extract all url(...) entries that point to font files
grep -oP 'url\(\Khttps://[^)]+' \"\$FONT_DIR/google-fonts-original.css\" | while read -r url; do
    counter=\$((counter + 1))
    
    # Determine file extension from URL
    ext='woff2'
    if echo \"\$url\" | grep -q '\.woff\b'; then ext='woff'; fi
    if echo \"\$url\" | grep -q '\.ttf'; then ext='ttf'; fi
    
    filename=\"font_\${counter}.\${ext}\"
    
    # Download the font file
    if command -v wget &>/dev/null; then
        wget -q -O \"\$FONT_DIR/\$filename\" \"\$url\"
    else
        curl -s -o \"\$FONT_DIR/\$filename\" \"\$url\"
    fi
    
    # Replace the remote URL with local path in the CSS
    # Using | as sed delimiter since URLs contain /
    escaped_url=\$(echo \"\$url\" | sed 's|[&/\]|\\\\&|g')
    sed -i \"s|\$escaped_url|./\$filename|g\" \"\$FONT_DIR/fonts.css\"
    
    echo \"    [\$counter] Downloaded: \$filename\"
done

# Fix permissions so the web user (1001) can use these files
chown -R 1001:1001 \"\$FONT_DIR\"

# Cleanup the original
rm -f \"\$FONT_DIR/google-fonts-original.css\"

echo '    All font files downloaded!'
echo ''
echo '    === FILES ==='
ls -la \"\$FONT_DIR/\"
"

if [ $? -ne 0 ]; then
    echo "[ERROR] Font download failed."
    exit 1
fi

# --- Step 3: Create the WordPress enqueue snippet ---
echo ""
echo "==========================================="
echo "  ✅ FONTS LOCALIZED SUCCESSFULLY!"
echo "==========================================="
echo ""
echo "Font files saved to: $FONT_DIR/"
echo ""
echo "--- NEXT STEPS ---"
echo ""
echo "OPTION A: Add to theme's style.css (simplest):"
echo "  Add this line at the TOP of your theme's style.css:"
echo "  @import url('./fonts/fonts.css');"
echo ""
echo "OPTION B: Enqueue via functions.php (recommended):"
echo "  Add this to your theme's functions.php:"
echo ""
cat <<'SNIPPET'
  // Load Local Fonts (instead of Google Fonts)
  function enqueue_local_fonts() {
      wp_enqueue_style(
          'local-fonts',
          get_template_directory_uri() . '/fonts/fonts.css',
          array(),
          '1.0'
      );
  }
  add_action('wp_enqueue_scripts', 'enqueue_local_fonts');
SNIPPET
echo ""
echo "OPTION C: Use a plugin like 'OMGF (Optimize My Google Fonts)'"
echo "  to auto-host Google Fonts locally."
echo ""
echo "--- IMPORTANT ---"
echo "After adding the fonts, you should also DEQUEUE the remote"
echo "Google Fonts request to avoid double-loading. Check your theme"
echo "or Elementor settings for Google Fonts and set it to 'None'."
echo ""
