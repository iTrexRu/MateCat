# Use official PHP 8.1 image with Apache
FROM php:8.1-apache

# Install system dependencies and PHP extensions
RUN apt-get update && apt-get install -y \
    libcurl4-openssl-dev \
    libxml2-dev \
    libzip-dev \
    libgd-dev \
    libonig-dev \
    zlib1g-dev \
    libpng-dev \
    libicu-dev \
    unzip \
    git \
    && docker-php-ext-install \
    curl \
    dom \
    pdo \
    pdo_mysql \
    zip \
    gd \
    mbstring \
    intl \
    xml \
    simplexml \
    pcntl \
    && docker-php-ext-enable \
    curl \
    dom \
    pdo \
    pdo_mysql \
    zip \
    gd \
    mbstring \
    intl \
    xml \
    simplexml \
    pcntl \
    && a2enmod rewrite

# Install Composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# Set working directory
WORKDIR /var/www/html

# Copy application code
COPY
