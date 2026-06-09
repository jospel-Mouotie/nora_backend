# 1. Image de base stable et ultra-légère
FROM php:8.2-fpm-alpine

# 2. Installation des dépendances système (uniquement le strict nécessaire)
RUN apk add --no-cache \
    nginx \
    libpng-dev \
    libzip-dev \
    oniguruma-dev \
    mysql-client

# Installation des extensions PHP requises pour Laravel et MySQL
RUN docker-php-ext-install pdo_mysql gd zip

# 3. Installer Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# 4. Dossier de travail
WORKDIR /var/www

# 5. Copier le projet backend
COPY . .

# 6. Supprimer le .env local pour utiliser les variables de Render
RUN rm -f .env

# 7. Installation des dépendances PHP de production (sans les packages de dev)
RUN composer install --no-dev --optimize-autoloader

# 8. GESTION DES PERMISSIONS
RUN chown -R www-data:www-data /var/www \
    && chmod -R 775 /var/www/storage /var/www/bootstrap/cache

# 9. Configuration Serveur (Nginx) et Script d'entrée
COPY docker/nginx.conf /etc/nginx/http.d/default.conf
COPY docker/entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

EXPOSE 80

ENTRYPOINT ["entrypoint.sh"]