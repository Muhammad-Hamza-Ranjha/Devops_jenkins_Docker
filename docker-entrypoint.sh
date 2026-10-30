#!/bin/bash
set -e
cd /var/www/html

[ -f .env ] || cp .env.example .env
php artisan key:generate --force

# Wait for MySQL, then run migrations
until php artisan migrate --force; do
  echo "Waiting for database..."
  sleep 3
done

php artisan config:clear
exec apache2-foreground
