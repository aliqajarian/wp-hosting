FROM wordpress:latest

# Install Build Dependencies (Temp)
RUN apt-get update && apt-get install -y \
    libonig-dev \
    libzip-dev \
    imagemagick \
    libmagickwand-dev \
    libgmp-dev \
    && rm -rf /var/lib/apt/lists/*

# Install PHP Extensions
# Added: bcmath, gmp, soap (WooCommerce Requirements)
# Added: redis, imagick (Performance)
RUN docker-php-ext-install \
    mysqli \
    pdo_mysql \
    zip \
    soap \
    intl \
    exif \
    opcache \
    bcmath \
    gmp

# Redis & Imagick via PECL
RUN pecl install redis && docker-php-ext-enable redis
RUN pecl install imagick && docker-php-ext-enable imagick

# PHP.ini Optimizations
RUN { \
    echo 'upload_max_filesize = 64M'; \
    echo 'post_max_size = 64M'; \
    echo 'memory_limit = 512M'; \
    echo 'max_execution_time = 300'; \
    echo 'max_input_vars = 5000'; \
    echo 'opcache.enable=1'; \
    echo 'opcache.memory_consumption=128'; \
    echo 'opcache.interned_strings_buffer=8'; \
    echo 'opcache.max_accelerated_files=10000'; \
    echo 'opcache.revalidate_freq=60'; \
    echo 'opcache.fast_shutdown=1'; \
    } > /usr/local/etc/php/conf.d/wp-recommended.ini

# Enable Apache Modules
RUN a2enmod rewrite headers expires

# Clean up apt cache
RUN apt-get clean && rm -rf /var/lib/apt/lists/*
