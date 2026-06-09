#!/bin/sh

# Attendre que la base de données MySQL distante réponde
sleep 3

echo "Exécution des migrations Laravel..."
php artisan migrate --force

echo "Optimisation des configurations de l'API..."
php artisan config:cache
php artisan route:cache


echo "Démarrage de Nginx pour l'API..."
nginx -g "daemon off;"