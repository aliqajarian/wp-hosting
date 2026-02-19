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

ARG IONCUBE_MIRROR="https://downloads.ioncube.com/loader_downloads/ioncube_loaders_lin_x86-64.tar.gz"
ARG WPCLI_MIRROR="https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar"

# 3. Install IonCube Loader
RUN curl -sL --connect-timeout 20 --max-time 300 --retry 5 -o /tmp/ioncube.tar.gz "$IONCUBE_MIRROR" && \
    tar -xzf /tmp/ioncube.tar.gz -C /tmp/ && \
    cp /tmp/ioncube/ioncube_loader_lin_$(php -r 'echo PHP_MAJOR_VERSION . "." . PHP_MINOR_VERSION;')*.so $(php -r "echo ini_get('extension_dir');")/ioncube_loader_lin_$(php -r 'echo PHP_MAJOR_VERSION . "." . PHP_MINOR_VERSION;').so && \
    echo "zend_extension=ioncube_loader_lin_$(php -r 'echo PHP_MAJOR_VERSION . "." . PHP_MINOR_VERSION;').so" > /usr/local/etc/php/conf.d/00-ioncube.ini && \
    rm -rf /tmp/ioncube /tmp/ioncube.tar.gz

# 4. Install WP-CLI
RUN curl -sL --connect-timeout 20 --max-time 300 --retry 5 -o /usr/local/bin/wp "$WPCLI_MIRROR" && \
    chmod +x /usr/local/bin/wp

# 5. PHP.ini Optimizations
RUN { \
    echo 'upload_max_filesize = 128M'; \
    echo 'post_max_size = 128M'; \
    echo 'memory_limit = 512M'; \
    echo 'max_execution_time = 300'; \
    } > /usr/local/etc/php/conf.d/wp-recommended.ini

RUN a2enmod rewrite headers expires

# 6. Custom Entrypoint: Install Persian language on first boot
COPY wp-init.sh /usr/local/bin/wp-init.sh
RUN chmod +x /usr/local/bin/wp-init.sh

ENTRYPOINT ["wp-init.sh"]
