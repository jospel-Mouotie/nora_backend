#!/bin/sh

# 1. Attendre 3 secondes que le réseau privé et PostgreSQL soient totalement prêts
sleep 3

# 2. Nettoyage complet et exécution des migrations
echo "Nettoyage et exécution des migrations Laravel..."
php artisan migrate:fresh --force

# 3. Optimisation des performances pour la production
echo "Optimisation des configurations de l'API..."
php artisan config:cache
php artisan route:cache

# 4. Démarrage de PHP-FPM en arrière-plan (-D pour Daemonize)
echo "Démarrage de PHP-FPM..."
php-fpm -D

# 5. Démarrage de Nginx au premier plan (garde le conteneur Docker actif)
echo "Démarrage de Nginx pour l'API..."
nginx -g "daemon off;"