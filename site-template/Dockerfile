# ==========================================
# WP-HOSTING CUSTOM WORDPRESS (OLS VERSION)
# ==========================================
FROM litespeedtech/openlitespeed:1.7.19-lsphp82

# Set LiteSpeed Home environment
ENV LSWS_HOME=/usr/local/lsws

# Use Mirror if provided (Optimizes for restricted environments like Iran)
ARG MIRROR
RUN if [ -n "$MIRROR" ]; then \
    sed -i "s/archive.ubuntu.com/$MIRROR/g" /etc/apt/sources.list && \
    sed -i "s/security.ubuntu.com/$MIRROR/g" /etc/apt/sources.list; \
    fi

# Install available PHP extensions for OLS and utilities
RUN apt-get update && apt-get install -y \
    lsphp82-curl \
    lsphp82-imagick \
    lsphp82-intl \
    lsphp82-mysql \
    lsphp82-opcache \
    lsphp82-redis \
    curl \
    wget \
    unzip \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Backup default configuration (to restore if bind mounts are empty)
RUN cp -rp /usr/local/lsws/conf /usr/local/lsws/conf.backup && \
    cp -rp /usr/local/lsws/admin/conf /usr/local/lsws/admin/conf.backup

# Fix PHP path for WP-CLI
RUN ln -sf /usr/local/lsws/lsphp82/bin/php /usr/local/bin/php

# Increase PHP memory limit globally (fixes WP-CLI extraction OOM at 128M default)
# In PHP, the LAST occurrence of a setting in php.ini wins, so appending guarantees 1024M
RUN echo "memory_limit = 1024M" >> /usr/local/lsws/lsphp82/etc/php/8.2/litespeed/php.ini && \
    echo "memory_limit = 1024M" > /usr/local/lsws/lsphp82/etc/php/8.2/mods-available/99-memory.ini

# Copy our custom initialization script (strip Windows line endings)
COPY wp-init.sh /usr/local/bin/wp-init.sh
RUN sed -i 's/\r$//' /usr/local/bin/wp-init.sh && chmod +x /usr/local/bin/wp-init.sh

# Set the entrypoint to our script
ENTRYPOINT ["/usr/local/bin/wp-init.sh"]
