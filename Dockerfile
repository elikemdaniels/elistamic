# ---------- Stage 1: Composer ----------
FROM composer:2 AS composer

WORKDIR /app
COPY composer.json composer.lock ./
RUN composer install --no-dev --optimize-autoloader --no-interaction --prefer-dist

# ---------- Stage 2: Node ----------
FROM node:22 AS node

WORKDIR /app
COPY package.json package-lock.json ./
RUN npm ci

# ---------- Stage 3: App ----------
FROM dunglas/frankenphp:php8.4

# Install system libs for GD
RUN apt-get update && apt-get install -y \
    libjpeg-dev \
    libpng-dev \
    libwebp-dev \
    libfreetype6-dev \
    && rm -rf /var/lib/apt/lists/*

# Install PHP extensions
RUN install-php-extensions \
    gd exif intl bcmath \
    pdo_mysql \
    ctype curl dom fileinfo filter hash mbstring openssl pcre session tokenizer xml

WORKDIR /app

# Copy vendor from composer stage
COPY --from=composer /app/vendor ./vendor
COPY --from=composer /app/composer.json ./composer.json
COPY --from=composer /app/composer.lock ./composer.lock

# Copy node_modules from node stage
COPY --from=node /app/node_modules ./node_modules

# Copy rest of app
COPY . .

# Build frontend
RUN npm run build

# Fix permissions
RUN mkdir -p storage/framework/{sessions,views,cache,testing} \
    storage/logs bootstrap/cache \
    && chmod -R 775 storage bootstrap/cache

# Optimize Laravel
RUN php artisan config:cache \
 && php artisan route:cache \
 && php artisan view:cache

ENV PORT=8080
EXPOSE 8080

CMD ["frankenphp", "run", "--port=8080"]
