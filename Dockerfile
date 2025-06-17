FROM ubuntu:20.04

# Отключаем интерактивные запросы при установке пакетов
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=UTC

# Добавляем репозиторий для PHP 8.1
RUN apt-get update && apt-get install -y software-properties-common \
    && add-apt-repository ppa:ondrej/php \
    && apt-get update

# Устанавливаем системные зависимости с PHP 8.1
RUN apt-get install -y \
    apache2 \
    php8.1 \
    php8.1-fpm \
    libapache2-mod-php8.1 \
    php8.1-mysql \
    php8.1-curl \
    php8.1-xml \
    php8.1-mbstring \
    php8.1-redis \
    php8.1-zip \
    php8.1-gd \
    php8.1-dev \
    php8.1-intl \
    php8.1-bcmath \
    mysql-client \
    redis-tools \
    curl \
    git \
    wget \
    unzip \
    supervisor \
    && rm -rf /var/lib/apt/lists/*

# Включаем Apache модули
RUN a2enmod rewrite ssl headers expires deflate filter php8.1

# Устанавливаем Node.js
RUN curl -fsSL https://deb.nodesource.com/setup_16.x | bash - \
    && apt-get install -y nodejs

# Устанавливаем Composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# Создаем рабочую директорию
WORKDIR /var/www/html

# Копируем код проекта
COPY . .

# Устанавливаем PHP зависимости
RUN composer install --no-dev --optimize-autoloader

# Устанавливаем Node.js зависимости (если есть package.json)
RUN if [ -f package.json ]; then npm install --production; fi

# Настраиваем права доступа
RUN chown -R www-data:www-data /var/www/html \
    && chmod -R 755 /var/www/html

# Копируем конфигурацию Apache
COPY docker/apache-config.conf /etc/apache2/sites-available/000-default.conf

# Создаем конфигурацию supervisor
RUN echo '[supervisord]\n\
nodaemon=true\n\
\n\
[program:apache2]\n\
command=/usr/sbin/apache2ctl -D FOREGROUND\n\
stdout_logfile=/dev/stdout\n\
stdout_logfile_maxbytes=0\n\
stderr_logfile=/dev/stderr\n\
stderr_logfile_maxbytes=0' > /etc/supervisor/conf.d/supervisord.conf

EXPOSE 80

CMD ["/usr/bin/supervisord"]
