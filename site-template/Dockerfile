FROM wordpress:latest

# Build argument for apt mirror
ARG MIRROR="mirror.arvancloud.ir"

# Fix apt sources for Debian Trixie (Bookworm/Testing)
RUN sed -i "s/deb.debian.org/$MIRROR/g" /etc/apt/sources.list.d/debian.sources && \
    apt-get update

# 1. Use official extension installer
COPY --from=mlocati/php-extension-installer /usr/bin/install-php-extensions /usr/local/bin/

# 2. Install Extensions
RUN install-php-extensions \
    mysqli \
    pdo_mysql \
    zip \
    soap \
    intl \
    exif \
    opcache \
    bcmath \
    gmp \
    redis \
    imagick \
    memcached

# 3. PHP.ini Optimizations
RUN { \
    echo 'upload_max_filesize = 128M'; \
    echo 'post_max_size = 128M'; \
    echo 'memory_limit = 512M'; \
    echo 'max_execution_time = 300'; \
    } > /usr/local/etc/php/conf.d/wp-recommended.ini

RUN a2enmod rewrite headers expires

# 4. Custom Entrypoint (handles IonCube, WP-CLI, Persian on first boot)
COPY wp-init.sh /usr/local/bin/wp-init.sh
RUN chmod +x /usr/local/bin/wp-init.sh

ENTRYPOINT ["wp-init.sh"]
