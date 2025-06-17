FROM ubuntu:20.04

# Отключаем интерактивные запросы при установке пакетов
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=UTC

# Обновляем пакеты и устанавливаем все зависимости
RUN apt-get update && apt-get install -y \
    apache2 \
    php8.0 \
    php8.0-fpm \
    libapache2-mod-php8.0 \
    php8.0-mysql \
    php8.0-curl \
    php8.0-xml \
    php8.0-mbstring \
    php8.0-redis \
    php8.0-zip \
    php8.0-gd \
    php8.0-dev \
    php8.0-intl \
    php8.0-bcmath \
    php8.0-json \
    mysql-client \
    redis-tools \
    curl \
    wget \
    git \
    unzip \
    supervisor \
    software-properties-common \
    && rm -rf /var/lib/apt/lists/*

# Включаем Apache модули
RUN a2enmod rewrite ssl headers expires deflate filter

# Устанавливаем Node.js
RUN curl -fsSL https://deb.nodesource.com/setup_16.x | bash - \
    && apt-get update \
    && apt-get install -y nodejs \
    && rm -rf /var/lib/apt/lists/*

# Устанавливаем Composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# Создаем рабочую директорию
WORKDIR /var/www/html

# Копируем код проекта
COPY . .

# Копируем конфигурацию Apache
COPY config/apache-vhost.conf /etc/apache2/sites-available/000-default.conf

# Устанавливаем PHP зависимости (если composer.json существует)
RUN if [ -f composer.json ]; then composer install --no-dev --optimize-autoloader --ignore-platform-reqs; fi

# Устанавливаем Node.js зависимости (если package.json существует)  
RUN if [ -f package.json ]; then npm install --production; fi

# Настраиваем права доступа
RUN chown -R www-data:www-data /var/www/html \
    && chmod -R 755 /var/www/html

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
