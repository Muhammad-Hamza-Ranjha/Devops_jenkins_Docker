# ---------- Stage 1: build front-end assets (Vite) ----------
FROM node:20 AS assets
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
RUN npm run build

# ---------- Stage 2: PHP + Apache (presentation + application tier) ----------
FROM php:8.3-apache

# System packages and PHP extensions
RUN apt-get update && apt-get install -y \
        git unzip libzip-dev libpng-dev libonig-dev libxml2-dev \
    && docker-php-ext-install pdo_mysql mbstring zip gd bcmath \
    && a2enmod rewrite \
    && rm -rf /var/lib/apt/lists/*

# Point Apache to Laravel's public folder
ENV APACHE_DOCUMENT_ROOT=/var/www/html/public
RUN sed -ri -e 's!/var/www/html!${APACHE_DOCUMENT_ROOT}!g' \
        /etc/apache2/sites-available/*.conf \
        /etc/apache2/apache2.conf \
        /etc/apache2/conf-available/*.conf

# Composer
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

WORKDIR /var/www/html

# Application code
COPY . .

# Built front-end assets from stage 1
COPY --from=assets /app/public/build /var/www/html/public/build

# PHP dependencies
RUN composer install --no-dev --optimize-autoloader --no-interaction

# Permissions for Laravel writable folders
RUN chown -R www-data:www-data storage bootstrap/cache \
    && chmod -R 775 storage bootstrap/cache

# Entrypoint (creates .env, generates key, waits for DB, runs migrations)
COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

EXPOSE 80
ENTRYPOINT ["docker-entrypoint.sh"]
