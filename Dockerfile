FROM php:7.3-cli

LABEL authors="Vage Zakaryan vagezakaryan@mail.ru, Eugeny Guchek eugeny.guchek@llsoft.by, Stanislav Petkevich stanislav.petkevich@llsoft.by"

# Install required system packages
RUN apt-get update && \
    apt-get -y install \
            git \
            zlib1g-dev \
            libssl-dev \
            libzip-dev \
            unzip \
            libmagickwand-dev \
            imagemagick \
        --no-install-recommends && \
        pecl install imagick && docker-php-ext-enable imagick && \
        apt-get clean && \
        rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Install php extensions
RUN docker-php-ext-install \
    bcmath \
    zip \
    pdo \
    gd \
    pdo_mysql

# Install pecl extensions
RUN pecl install \
        mongodb \
        apcu \
        xdebug-2.7.2 && \
    docker-php-ext-enable \
        apcu.so \
        mongodb.so \
        xdebug

# Configure php
RUN echo "date.timezone = UTC" >> /usr/local/etc/php/php.ini

# Install composer
ENV COMPOSER_ALLOW_SUPERUSER=1
RUN curl -sS https://getcomposer.org/installer | php -- \
        --filename=composer \
        --install-dir=/usr/local/bin
RUN composer global require --optimize-autoloader \
        "hirak/prestissimo"

RUN curl -LsS http://codeception.com/codecept.phar -o /usr/local/bin/codecept
RUN chmod a+x /usr/local/bin/codecept

# Prepare application
WORKDIR /repo

# Install vendor
COPY ./composer.json /repo/composer.json
RUN composer install --prefer-dist --no-interaction --optimize-autoloader --apcu-autoloader

# Add source-code
COPY . /repo

ENV PATH /repo:${PATH}
ENTRYPOINT ["codecept"]

# Prepare host-volume working directory
RUN mkdir /project
WORKDIR /project