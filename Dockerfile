# ---------- Base PHP Image ----------
FROM dunglas/frankenphp:php8.4

# Install required PHP extensions
RUN install-php-extensions \
    ctype curl dom fileinfo filter hash mbstring openssl pcre pdo session tokenizer xml \
    gd exif intl bcmath

# Set working directory
WORKDIR /app

# ---------- Install Composer Dependencies ----------
COPY composer.json composer.lock ./
RUN composer install --no-dev --optimize-autoloader --no-interaction --prefer-dist

# ---------- Install Node Dependencies ----------
COPY package.json package-lock.json ./
RUN npm ci

# ---------- Copy Application ----------
COPY . .

# ---------- Build Frontend ----------
RUN npm run build

# ---------- Laravel Optimization ----------
RUN mkdir -p storage/framework/{sessions,views,cache,testing} \
    storage/logs bootstrap/cache \
    && chmod -R 775 storage bootstrap/cache

RUN php artisan config:cache \
 && php artisan route:cache \
 && php artisan view:cache

# ---------- Expose Railway Port ----------
ENV PORT=8080
EXPOSE 8080

# ---------- Start Server ----------
CMD ["frankenphp", "run", "--port=8080"]
