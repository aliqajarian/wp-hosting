# ==========================================
# WP-HOSTING CUSTOM WORDPRESS
# ==========================================
FROM wordpress:latest

# Install system dependencies for SOAP
RUN apt-get update && apt-get install -y \
    libxml2-dev \
    && docker-php-ext-install soap \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Copy our custom initialization script
COPY wp-init.sh /usr/local/bin/wp-init.sh
RUN chmod +x /usr/local/bin/wp-init.sh

# Set the entrypoint to our script
ENTRYPOINT ["/usr/local/bin/wp-init.sh"]
