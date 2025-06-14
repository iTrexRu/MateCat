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

# Set ServerName to suppress Apache FQDN warning
RUN echo "ServerName localhost" >> /etc/apache2/apache2.conf

# Set working directory
WORKDIR /var/www/html

# Copy application code
COPY . /var/www/html

# Create storage directory if it doesn't exist
RUN mkdir -p /var/www/html/storage

# Set file permissions for Apache and storage directory
RUN chown -R www-data:www-data /var/www/html \
    && chmod -R 755 /var/www/html \
    && chmod -R 775 /var/www/html/storage

# Install PHP dependencies
RUN composer install --no-dev --optimize-autoloader

# Configure Apache to use root directory and enable rewrite rules
RUN echo "<Directory /var/www/html>\n\
    Options FollowSymLinks\n\
    AllowOverride All\n\
    Require all granted\n\
    RewriteEngine On\n\
    RewriteCond %{REQUEST_FILENAME} !-f\n\
    RewriteCond %{REQUEST_FILENAME} !-d\n\
    RewriteRule ^ index.php [L]\n\
</Directory>" > /etc/apache2/conf-available/matecat.conf \
&& a2enconf matecat \
&& sed -i 's|DocumentRoot /var/www/html|DocumentRoot /var/www/html|' /etc/apache2/sites-available/000-default.conf

# Expose port (Railway assigns a dynamic port)
EXPOSE $PORT

# Start Apache
CMD ["apache2-foreground"]
