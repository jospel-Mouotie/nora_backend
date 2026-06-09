# Instructions pour Exécuter les Seeders

## 🚀 Commandes pour remplir la base de données

### Étape 1 : Exécuter le seeder principal
```bash
php artisan db:seed --class=DatabaseSeeder
```

### Étape 2 : Exécuter les seeders individuellement (optionnel)
```bash
# Utilisateurs
php artisan db:seed --class=UserSeeder

# Catégories
php artisan db:seed --class=CategorySeeder

# Boutiques
php artisan db:seed --class=ShopSeeder

# Produits
php artisan db:seed --class=ProductSeeder
```

### Étape 3 : Rafraîchir la base de données (si nécessaire)
```bash
# Vider et recréer toutes les tables
php artisan migrate:fresh --seed

# Ou juste vider les tables et re-seeder
php artisan db:wipe
php artisan db:seed
```

---

## 📊 Données qui seront créées

### 👤 Utilisateurs (4 comptes)
- **Admin Nora** (admin@nora.com / password)
- **Jean Commerçant** (jean@shop.com / password)
- **Marie Cliente** (marie@client.com / password)
- **Paul Livreur** (paul@delivery.com / password)
- **Sophie Grossiste** (sophie@grosiste.com / password)

### 🏪 Boutiques (4 boutiques)
- **Fashion Store** (certifiée)
- **Tech Hub** (non certifiée)
- **Beauty Corner** (certifiée)
- **Grossiste Pro** (certifiée)

### 📱 Produits (10 produits)
- **Mode** : T-shirt Premium, Jean Fashion, Robe Élégante
- **Électronique** : Smartphone Pro, Écouteurs Bluetooth, Laptop Ultra
- **Beauté** : Crème Hydratante, Sérum Anti-âge, Masque Visage
- **Alimentation** : Riz Premium, Huile de Palme

### 🎯 Catégories (10 catégories)
- Mode, Électronique, Beauté, Sports, Maison, Alimentation, Livres, Jeux, Santé, Automobile, Art

### 🎥 Vidéos (3 vidéos)
- Collection Printemps (Fashion Store)
- Unboxing Smartphone Pro (Tech Hub)
- Look du Jour (Marie Cliente)

### 💰 Centres d'Intérêt (3 intérêts pour Marie)
- Mode (niveau 5 : Passionné)
- Beauté (niveau 4 : Très intéressé)
- Électronique (niveau 3 : Intéressé)

### 📊 Habitudes Utilisateur (3 habitudes pour Marie)
- Vue du T-shirt Premium
- Recherche "robe soirée"
- Achat du T-shirt Premium

### 🛒 MB Coins System
- **Récompenses** : Bonus inscription, premier achat
- **Boutique MB** : Bon réduction 10%, Livraison gratuite

### 🏪 Interactions Boutiques
- **Abonnements** : Marie suit Fashion Store et Beauty Corner
- **Likes** : Marie aime Tech Hub

### 📦 Commandes et Livraisons
- **Commande** : Marie a acheté le T-shirt Premium
- **Livraison** : Paul a livré la commande

### 💬 Chat Admin
- **Conversation** : Marie a posé une question sur sa commande
- **Réponse** : Admin a répondu que la commande est livrée

### 📢 Publicités
- **Campagne** : Campagne Printemps (Fashion Store)
- **Bannière** : Collection Printemps -30%

---

## 🔧 Vérification après exécution

### Vérifier les données créées
```bash
# Vérifier les utilisateurs
php artisan tinker
User::count(); // Devrait retourner 4

# Vérifier les produits
Product::count(); // Devrait retourner 10

# Vérifier les catégories
Category::count(); // Devrait retourner 10

# Vérifier les centres d'intérêt
UserInterest::count(); // Devrait retourner 3
```

### Test API avec les données
```bash
# Test connexion admin
curl -X POST http://localhost:8000/api/login \
  -H "Content-Type: application/json" \
  -d '{"email": "admin@nora.com", "password": "password"}'

# Test produits recommandés
curl -X GET http://localhost:8000/api/products/recommended \
  -H "Authorization: Bearer VOTRE_TOKEN"
```

---

## 🚨 Dépannage

### Erreur "Class not found"
```bash
# Régénérer les autoloaders
composer dump-autoload

# Vérifier les namespaces
ls database/seeders/
```

### Erreur de contraintes étrangères
```bash
# Désactiver les contraintes temporairement
php artisan db:seed --class=DatabaseSeeder

# Réactiver après le seeder
php artisan migrate
```

### Erreur "Table doesn't exist"
```bash
# Exécuter les migrations d'abord
php artisan migrate

# Puis exécuter les seeders
php artisan db:seed --class=DatabaseSeeder
```

---

## 📱 Utilisation avec le Frontend React Native

Une fois les seeders exécutés, vous pouvez utiliser ces données pour tester :

### 1. Connexion
- **Admin** : admin@nora.com / password
- **Client** : marie@client.com / password
- **Commerçant** : jean@shop.com / password
- **Livreur** : paul@delivery.com / password

### 2. Test des centres d'intérêt
- L'utilisateur Marie a déjà 3 centres d'intérêt configurés
- Parfait pour tester l'écran de sélection et les recommandations

### 3. Test des produits recommandés
- Les produits de Mode et Beauté devraient apparaître en premier pour Marie
- Basé sur ses centres d'intérêt (Mode niveau 5, Beauté niveau 4)

### 4. Test des habitudes
- Les vues et achats de Marie sont déjà enregistrés
- Parfait pour tester le tracking et les recommandations personnalisées

### 5. Test des vidéos et interactions
- **7 vidéos** disponibles avec contenu varié (mode, tech, beauté)
- **1970 vues** totales générées automatiquement
- **194 likes** créés par les utilisateurs
- **10 commentaires** avec interactions réalistes
- **Tags et catégories** pour les recommandations vidéo
- **Durées de visionnage** pour l'analyse comportementale

---

Exécutez ces commandes pour avoir une base de données complète et prête pour le développement ! 🎯
