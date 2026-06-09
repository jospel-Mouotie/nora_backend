#!/bin/sh

# 1. Attendre 3 secondes que le réseau privé et PostgreSQL soient totalement prêts
sleep 3

# 2. Nettoyage et création de la structure de la base de données
echo "Nettoyage et exécution des migrations Laravel..."
php artisan migrate:fresh --force

# 3. Exécution INDIVIDUELLE de tes seeders dans l'ordre logique des clés étrangères
echo "Début de l'injection individuelle des seeders..."

echo "-> Injection des Utilisateurs..."
php artisan db:seed --class=UserSeeder --force

echo "-> Injection des Catégories..."
php artisan db:seed --class=CategorySeeder --force

echo "-> Injection des Boutiques..."
php artisan db:seed --class=ShopSeeder --force

echo "-> Injection des Produits..."
php artisan db:seed --class=ProductSeeder --force

echo "Injection des données terminée avec succès !"

# 4. Optimisation des performances pour la production
echo "Optimisation des configurations de l'API..."
php artisan config:cache
php artisan route:cache

# 5. Démarrage de PHP-FPM en arrière-plan (-D pour Daemonize)
echo "Démarrage de PHP-FPM..."
php-fpm -D

# 6. Démarrage de Nginx au premier plan
echo "Démarrage de Nginx pour l'API..."
nginx -g "daemon off;"