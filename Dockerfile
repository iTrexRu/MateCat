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
    && a2enmod rewrite

# Install Composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# Set working directory
WORKDIR /var/www/html

# Copy application code
COPY . .

# Install PHP dependencies
RUN composer install --no-dev --optimize-autoloader

# Configure Apache to use public/ directory
RUN echo "<Directory /var/www/html/public>\n\
    Options Indexes FollowSymLinks\n\
    AllowOverride All\n\
    Require all granted\n\
</Directory>" > /etc/apache2/conf-available/matecat.conf \
&& a2enconf matecat \
&& sed -i 's|DocumentRoot /var/www/html|DocumentRoot /var/www/html/public|' /etc/apache2/sites-available/000-default.conf

# Expose port (Railway assigns a dynamic port, but we define it for clarity)
EXPOSE $PORT

# Start Apache
CMD ["apache2-foreground"]
