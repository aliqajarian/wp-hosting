#!/bin/bash

# ==========================================
# LOCALIZE GOOGLE FONTS
# ==========================================
# Downloads Google Fonts and CSS to the local theme folder.
# Usage: ./localize-font.sh <site-name> <google-fonts-css-url>

SITE_NAME=$1
FONT_URL=$2

if [ -z "$SITE_NAME" ] || [ -z "$FONT_URL" ]; then
    echo "Usage: $0 <site-name> \"<google-fonts-css-url>\""
    echo "Example: $0 client1 \"https://fonts.googleapis.com/css2?family=Vazirmatn:wght@400;700&display=swap\""
    exit 1
fi

SITE_DIR="/opt/wp-hosting/sites/$SITE_NAME"
THEME_PATH="html/wp-content/themes"

# Find the active theme (assume the first one found or 'my-theme')
# We need to run inside the builder container to have correct permissions/tools
CONTAINER="${SITE_NAME}_builder"

echo ">>> Localizing Fonts for $SITE_NAME..."

# Create a temporary script inside the container to handle the download logic
# This ensures we use the container's curl/wget and file system context
cat <<EOF > /tmp/download_logic.sh
#!/bin/sh
# Navigate to theme dir (assumed /app mapped to active theme)
cd /app

mkdir -p fonts
echo "--> Fetching CSS from Google..."

# 1. Download the CSS
# We need a user agent string or Google might reject/give WOFF1
wget -U "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/90.0.4430.93 Safari/537.36" -O fonts/fonts.css "$FONT_URL"

if [ ! -f "fonts/fonts.css" ]; then
    echo "Error: Failed to download CSS."
    exit 1
fi

echo "--> Downloading WOFF2 files..."

# 2. Extract URLs and Download
# Simple parser to find https://...woff2
# Alpine grep might differ, so we use a simple loop with sed/awk if needed.
# Converting CSS to use local paths as we go.

# Read line by line
temp_css=""
counter=1

while IFS= read -r line; do
    # Check if line contains a url
    if echo "\$line" | grep -q "url(https://"; then
        # Extract URL
        url=\$(echo "\$line" | sed -n 's/.*url(\(https:\/\/[^)]*\)).*/\1/p')
        filename="font_\$counter.woff2"
        
        # Download file
        wget -q -O "fonts/\$filename" "\$url"
        
        # Replace URL in line with local path
        line=\$(echo "\$line" | sed "s|https://[^)]*|./\$filename|")
        
        counter=\$((counter+1))
    fi
    echo "\$line" >> fonts/local-fonts.css
done < fonts/fonts.css

# Cleanup
mv fonts/local-fonts.css fonts/fonts.css
rm /tmp/download_logic.sh

echo "--> Success! Font Files saved to /app/fonts/"
echo "--> Import 'fonts/fonts.css' in your Tailwind CSS or style.css"
EOF

# Copy logic to container (via docker cp logic or just catting it into a file inside)
# Since we can't easily docker cp TO a container without source file, we'll pipe it.
# Actually, 'docker exec -i' reading from stdin to a file is easiest.

# 1. Write script to container
cat /tmp/download_logic.sh | docker exec -i "$CONTAINER" sh -c 'cat > /tmp/run_dl.sh && chmod +x /tmp/run_dl.sh'

# 2. Run it
docker exec "$CONTAINER" /tmp/run_dl.sh

echo ">>> Done. Add '@import \"./fonts/fonts.css\";' to your theme's style.css"
