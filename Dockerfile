# 1. Image de base stable et ultra-légère
FROM php:8.2-fpm-alpine

# 2. Installation des dépendances système
RUN apk add --no-cache \
    nginx \
    libpng-dev \
    libzip-dev \
    oniguruma-dev \
    postgresql-dev

# 3. Installation des extensions PHP requises
RUN docker-php-ext-install pdo_pgsql gd zip

# 4. Installer Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# 5. Dossier de travail
WORKDIR /var/www

# 6. Copier le projet backend
COPY . .

# 7. Supprimer le .env local
RUN rm -f .env

# =========================================================================
# 8. CORRECTION DES DROITS (À faire AVANT composer install)
# On s'assure que les dossiers existent ET que l'utilisateur a les droits
# =========================================================================
RUN mkdir -p /var/www/storage /var/www/bootstrap/cache \
    && chown -R www-data:www-data /var/www \
    && chmod -R 775 /var/www/storage /var/www/bootstrap/cache

# 9. Installation des dépendances PHP de production (Maintenant ça va passer !)
RUN composer install --no-dev --optimize-autoloader

# 10. Configuration Serveur (Nginx) et Script d'entrée
COPY docker/nginx.conf /etc/nginx/http.d/default.conf
COPY docker/entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

EXPOSE 80

ENTRYPOINT ["entrypoint.sh"]