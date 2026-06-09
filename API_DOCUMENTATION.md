# API Documentation - Nora Marketplace Platform

## Table des matières

1. [Authentification](#authentification)
2. [Utilisateurs](#utilisateurs)
3. [Boutiques](#boutiques)
4. [Catégories](#catégories)
5. [Produits](#produits)
6. [Panier](#panier)
7. [Commandes](#commandes)
8. [Livraisons](#livraisons)
9. [Chat Client-Livreur](#chat-client-livreur)
10. [Vidéos (Réels)](#vidéos-réels)
11. [MB Coins](#mb-coins)
12. [Récompenses MB](#récompenses-mb)
13. [Boutique MB](#boutique-mb)
14. [Publicités](#publicités)
15. [Chat Admin](#chat-admin)
16. [Dashboard Admin](#dashboard-admin)

---

## Informations générales

- **URL de base**: `http://localhost:8000/api`
- **Authentification**: Bearer Token (Sanctum)
- **Format des réponses**: JSON
- **Headers requis**:
  - `Content-Type: application/json`
  - `Authorization: Bearer {token}` (pour les routes protégées)

---

## Authentification

### Inscription
```http
POST /api/register
```

**Body:**
```json
{
  "name": "John Doe",
  "email": "john@example.com",
  "password": "password123",
  "password_confirmation": "password123",
  "role": "customer"
}
```

**Réponse:**
```json
{
  "message": "Utilisateur créé avec succès",
  "user": {
    "id": 1,
    "name": "John Doe",
    "email": "john@example.com",
    "role": "customer",
    "created_at": "2026-05-12T14:30:00.000000Z"
  },
  "token": "1|abc123..."
}
```

### Connexion
```http
POST /api/login
```

**Body:**
```json
{
  "email": "john@example.com",
  "password": "password123"
}
```

**Réponse:**
```json
{
  "message": "Connexion réussie",
  "user": {
    "id": 1,
    "name": "John Doe",
    "email": "john@example.com",
    "role": "customer"
  },
  "token": "1|abc123..."
}
```

### Déconnexion
```http
POST /api/logout
```

**Headers:** `Authorization: Bearer {token}`

**Réponse:**
```json
{
  "message": "Déconnexion réussie"
}
```

---

## Utilisateurs

### Profil utilisateur
```http
GET /api/user
```

**Réponse:**
```json
{
  "id": 1,
  "name": "John Doe",
  "email": "john@example.com",
  "role": "customer",
  "phone": "+33612345678",
  "address": "123 Rue de la Paix",
  "city": "Paris",
  "postal_code": "75001",
  "country": "France",
  "profile_picture": "http://localhost:8000/storage/profiles/user1.jpg",
  "created_at": "2026-05-12T14:30:00.000000Z",
  "total_orders": 5,
  "total_spent": 250.50
}
```

### Mettre à jour le profil
```http
PUT /api/user
```

**Body:**
```json
{
  "name": "John Updated",
  "phone": "+33687654321",
  "address": "456 Avenue des Champs",
  "city": "Paris",
  "postal_code": "75008"
}
```

### Mettre à jour la photo de profil
```http
POST /api/user/profile-picture
```

**Body:** `multipart/form-data` avec `profile_picture` (file)

---

## Boutiques

### Lister les boutiques
```http
GET /api/shops
```

**Query params:**
- `limit`: nombre de résultats (défaut: 20)
- `search`: recherche par nom
- `category_id`: filtrer par catégorie
- `city`: filtrer par ville

**Réponse:**
```json
{
  "shops": [
    {
      "id": 1,
      "name": "Boutique Mode",
      "description": "Vêtements tendance",
      "logo": "http://localhost:8000/storage/logos/shop1.jpg",
      "banner": "http://localhost:8000/storage/banners/shop1.jpg",
      "address": "123 Rue Fashion",
      "city": "Paris",
      "postal_code": "75001",
      "phone": "+33612345678",
      "email": "contact@boutique-mode.com",
      "website": "https://boutique-mode.com",
      "status": "active",
      "certifiee": true,
      "rating": 4.5,
      "total_products": 50,
      "followers_count": 120,
      "is_following": false,
      "is_liked": true,
      "created_at": "2026-05-12T14:30:00.000000Z"
    }
  ]
}
```

### Créer une boutique
```http
POST /api/shops
```

**Body:**
```json
{
  "name": "Ma Boutique",
  "description": "Description de ma boutique",
  "address": "123 Rue Principale",
  "city": "Paris",
  "postal_code": "75001",
  "phone": "+33612345678",
  "email": "contact@ma-boutique.com",
  "category_id": 1
}
```

### Détails d'une boutique
```http
GET /api/shops/{id}
```

### Mettre à jour une boutique
```http
PUT /api/shops/{id}
```

### Supprimer une boutique
```http
DELETE /api/shops/{id}
```

### Suivre une boutique
```http
POST /api/shops/{id}/follow
```

### Ne plus suivre une boutique
```http
DELETE /api/shops/{id}/follow
```

### Liker une boutique
```http
POST /api/shops/{id}/like
```

### Ne plus liker une boutique
```http
DELETE /api/shops/{id}/like
```

---

## Catégories

### Lister les catégories
```http
GET /api/categories
```

**Réponse:**
```json
{
  "categories": [
    {
      "id": 1,
      "name": "Mode",
      "description": "Vêtements et accessoires",
      "icon": "fas fa-tshirt",
      "image": "http://localhost:8000/storage/categories/mode.jpg",
      "parent_id": null,
      "is_active": true,
      "sort_order": 1,
      "products_count": 150,
      "subcategories": [
        {
          "id": 2,
          "name": "Hommes",
          "parent_id": 1,
          "products_count": 75
        }
      ]
    }
  ]
}
```

---

## Produits

### Lister les produits
```http
GET /api/products
```

**Query params:**
- `limit`: nombre de résultats
- `search`: recherche
- `category_id`: catégorie
- `shop_id`: boutique
- `min_price`: prix minimum
- `max_price`: prix maximum
- `sort`: tri (price_asc, price_desc, name_asc, name_desc, created_desc)

**Réponse:**
```json
{
  "products": [
    {
      "id": 1,
      "name": "T-shirt Premium",
      "description": "T-shirt en coton bio",
      "price": 29.99,
      "compare_price": 39.99,
      "sku": "TSHIRT-001",
      "stock": 50,
      "images": [
        "http://localhost:8000/storage/products/tshirt1.jpg",
        "http://localhost:8000/storage/products/tshirt2.jpg"
      ],
      "category_id": 1,
      "shop_id": 1,
      "is_active": true,
      "is_promotion": true,
      "promotion_price": 24.99,
      "rating": 4.5,
      "reviews_count": 12,
      "sales_count": 45,
      "created_at": "2026-05-12T14:30:00.000000Z",
      "shop": {
        "id": 1,
        "name": "Boutique Mode"
      },
      "category": {
        "id": 1,
        "name": "Mode"
      },
      "variants": [
        {
          "id": 1,
          "size": "M",
          "color": "Bleu",
          "stock": 15,
          "price": 29.99
        }
      ]
    }
  ]
}
```

### Créer un produit
```http
POST /api/products
```

**Body:**
```json
{
  "name": "Nouveau Produit",
  "description": "Description du produit",
  "price": 49.99,
  "sku": "PROD-001",
  "stock": 100,
  "category_id": 1,
  "images": ["image1.jpg", "image2.jpg"],
  "variants": [
    {
      "size": "S",
      "color": "Rouge",
      "stock": 25,
      "price": 49.99
    }
  ]
}
```

### Détails d'un produit
```http
GET /api/products/{id}
```

### Mettre à jour un produit
```http
PUT /api/products/{id}
```

### Supprimer un produit
```http
DELETE /api/products/{id}
```

### Produits par catégorie
```http
GET /api/products/by-category/{categoryId}
```

### Produits par boutique
```http
GET /api/products/by-shop/{shopId}
```

### Produits en promotion
```http
GET /api/products/promotions
```

### Activer une promotion
```http
POST /api/products/{id}/activate-promotion
```

**Body:**
```json
{
  "promotion_price": 19.99,
  "starts_at": "2026-05-12T00:00:00Z",
  "ends_at": "2026-05-19T23:59:59Z"
}
```

---

## Panier

### Voir le panier
```http
GET /api/cart
```

**Réponse:**
```json
{
  "items": [
    {
      "id": 1,
      "quantity": 2,
      "price": 29.99,
      "total": 59.98,
      "product": {
        "id": 1,
        "name": "T-shirt Premium",
        "images": ["http://localhost:8000/storage/products/tshirt1.jpg"]
      },
      "variant": {
        "id": 1,
        "size": "M",
        "color": "Bleu"
      }
    }
  ],
  "total_items": 2,
  "total_amount": 59.98
}
```

### Ajouter au panier
```http
POST /api/cart/add
```

**Body:**
```json
{
  "product_id": 1,
  "quantity": 2,
  "variant_id": 1
}
```

### Mettre à jour la quantité
```http
PUT /api/cart/update/{itemId}
```

**Body:**
```json
{
  "quantity": 3
}
```

### Supprimer du panier
```http
DELETE /api/cart/remove/{itemId}
```

### Vider le panier
```http
DELETE /api/cart/clear
```

---

## Commandes

### Créer une commande
```http
POST /api/orders
```

**Body:**
```json
{
  "delivery_address": {
    "address": "123 Rue de la Paix",
    "city": "Paris",
    "postal_code": "75001",
    "country": "France",
    "phone": "+33612345678"
  },
  "payment_method": "cash",
  "notes": "Livraison après 18h"
}
```

**Réponse:**
```json
{
  "message": "Commande créée avec succès",
  "order": {
    "id": 1,
    "order_number": "ORD-20260512-001",
    "status": "pending",
    "total_amount": 59.98,
    "delivery_fee": 5.00,
    "items": [...],
    "delivery_address": {...},
    "created_at": "2026-05-12T14:30:00.000000Z",
    "qr_code": "http://localhost:8000/storage/qrcodes/order1.png"
  }
}
```

### Lister les commandes
```http
GET /api/orders
```

**Query params:**
- `status`: pending, confirmed, preparing, ready, in_delivery, delivered, cancelled
- `limit`: nombre de résultats

### Détails d'une commande
```http
GET /api/orders/{id}
```

### Mettre à jour le statut
```http
PUT /api/orders/{id}/status
```

**Body:**
```json
{
  "status": "confirmed"
}
```

### Annuler une commande
```http
POST /api/orders/{id}/cancel
```

---

## Livraisons

### Créer une livraison
```http
POST /api/deliveries
```

**Body:**
```json
{
  "order_id": 1,
  "delivery_person_id": 2,
  "pickup_address": {
    "address": "123 Rue de la Boutique",
    "city": "Paris",
    "latitude": 48.8566,
    "longitude": 2.3522
  },
  "delivery_address": {
    "address": "456 Rue du Client",
    "city": "Paris",
    "latitude": 48.8584,
    "longitude": 2.2945
  }
}
```

### Lister les livraisons
```http
GET /api/deliveries
```

### Détails d'une livraison
```http
GET /api/deliveries/{id}
```

### Mettre à jour la position
```http
PUT /api/deliveries/{id}/location
```

**Body:**
```json
{
  "current_latitude": 48.8570,
  "current_longitude": 2.3500
}
```

### Mettre à jour le statut
```http
PUT /api/deliveries/{id}/status
```

**Body:**
```json
{
  "status": "picked_up"
}
```

---

## Chat Client-Livreur

### Messages d'une livraison
```http
GET /api/chat/delivery/{deliveryId}
```

**Réponse:**
```json
{
  "messages": [
    {
      "id": 1,
      "content": "Votre commande est en route",
      "type": "text",
      "sender_id": 2,
      "sender_type": "delivery_person",
      "is_read": true,
      "created_at": "2026-05-12T14:30:00.000000Z",
      "formatted_time": "il y a 5 minutes"
    }
  ]
}
```

### Envoyer un message
```http
POST /api/chat/delivery/{deliveryId}/send
```

**Body:**
```json
{
  "content": "Merci pour la livraison rapide !",
  "type": "text"
}
```

### Marquer comme lu
```http
PUT /api/chat/delivery/{deliveryId}/read
```

### Nombre de messages non lus
```http
GET /api/chat/unread-count
```

---

## Vidéos (Réels)

### Lister les vidéos
```http
GET /api/videos
```

**Query params:**
- `limit`: nombre de résultats
- `category`: catégorie
- `shop_id`: boutique

**Réponse:**
```json
{
  "videos": [
    {
      "id": 1,
      "title": "Nouvelle collection été",
      "description": "Découvrez nos nouveaux vêtements",
      "video_path": "videos/summer_collection.mp4",
      "thumbnail": "thumbnails/summer_collection.jpg",
      "duration": 30,
      "file_size": 5242880,
      "format": "mp4",
      "status": "public",
      "view_count": 150,
      "likes_count": 45,
      "comments_count": 12,
      "is_public": true,
      "allow_comments": true,
      "allow_downloads": false,
      "created_at": "2026-05-12T14:30:00.000000Z",
      "user": {
        "id": 1,
        "name": "John Doe",
        "profile_picture": "profiles/user1.jpg"
      },
      "shop": {
        "id": 1,
        "name": "Boutique Mode"
      }
    }
  ]
}
```

### Upload d'une vidéo
```http
POST /api/videos/upload
```

**Body:** `multipart/form-data`
- `video`: fichier vidéo
- `thumbnail`: image miniature
- `title`: titre
- `description`: description
- `shop_id`: ID boutique (optionnel)

### Vidéos tendances
```http
GET /api/videos/trending
```

### Mes vidéos
```http
GET /api/videos/my
```

### Détails d'une vidéo
```http
GET /api/videos/{id}
```

### Stream d'une vidéo
```http
GET /api/videos/{id}/stream
```

### Enregistrer une vue
```http
POST /api/videos/{id}/view
```

**Body:**
```json
{
  "duration": 15.5
}
```

### Liker/Unliker une vidéo
```http
POST /api/videos/{id}/like
```

### Commentaires d'une vidéo
```http
GET /api/videos/{id}/comments
```

### Ajouter un commentaire
```http
POST /api/videos/{id}/comments
```

**Body:**
```json
{
  "content": "Super vidéo !",
  "parent_id": null
}
```

### Statistiques d'une vidéo
```http
GET /api/videos/{id}/stats
```

---

## MB Coins

### Solde MB Coins
```http
GET /api/mb-coins/balance
```

**Réponse:**
```json
{
  "balance": 250.50,
  "formatted_balance": "250,50 MB",
  "total_earned": 500.00,
  "total_spent": 249.50,
  "total_withdrawn": 0.00,
  "last_earned_at": "2026-05-12T14:30:00.000000Z",
  "last_spent_at": "2026-05-11T10:15:00.000000Z"
}
```

### Historique des transactions
```http
GET /api/mb-coins/transactions
```

**Query params:**
- `type`: credit, debit, withdrawal, refund
- `start_date`: date de début
- `end_date`: date de fin
- `limit`: nombre de résultats

**Réponse:**
```json
{
  "transactions": [
    {
      "id": 1,
      "amount": 5.00,
      "type": "credit",
      "description": "Vue de vidéo",
      "source": "video_view",
      "source_id": 1,
      "balance_after": 250.50,
      "formatted_amount": "+5,00 MB",
      "type_label": "Crédit",
      "created_at": "2026-05-12T14:30:00.000000Z"
    }
  ],
  "summary": {
    "total_credits": 500.00,
    "total_debits": 249.50,
    "total_withdrawals": 0.00
  }
}
```

### Demander un retrait
```http
POST /api/mb-coins/withdraw
```

**Body:**
```json
{
  "amount": 100.00,
  "method": "bank_transfer",
  "details": {
    "account_name": "John Doe",
    "account_number": "FR7630006000011234567890189",
    "bank_name": "BNP Paribas"
  }
}
```

### Statistiques MB Coins
```http
GET /api/mb-coins/stats
```

**Query params:**
- `period`: période en jours (défaut: 30)

### Activité récente
```http
GET /api/mb-coins/recent-activity
```

### Classement des utilisateurs
```http
GET /api/mb-coins/leaderboard
```

**Query params:**
- `period`: all, week, month, year

---

## Récompenses MB

### Lister les récompenses
```http
GET /api/mb-rewards
```

**Query params:**
- `status`: available, claimed, expired
- `type`: daily_bonus, video_view, video_like, comment, referral, achievement, special
- `limit`: nombre de résultats

**Réponse:**
```json
{
  "rewards": [
    {
      "id": 1,
      "title": "Bonus Quotidien",
      "description": "Bonus quotidien pour votre activité",
      "type": "daily_bonus",
      "amount": 5.00,
      "formatted_amount": "5,00 MB",
      "type_label": "Bonus Quotidien",
      "is_claimed": false,
      "is_available": true,
      "expires_at": "2026-05-19T23:59:59Z",
      "created_at": "2026-05-12T14:30:00.000000Z"
    }
  ],
  "summary": {
    "total_available": 3,
    "total_claimed": 12,
    "total_expired": 1
  }
}
```

### Réclamer une récompense
```http
POST /api/mb-rewards/{id}/claim
```

**Réponse:**
```json
{
  "message": "Récompense réclamée avec succès",
  "reward": {
    "id": 1,
    "is_claimed": true,
    "claimed_at": "2026-05-12T14:30:00.000000Z"
  },
  "new_balance": "255,50 MB"
}
```

### Récompenses disponibles
```http
GET /api/mb-rewards/available
```

### Statistiques des récompenses
```http
GET /api/mb-rewards/stats
```

---

## Boutique MB

### Lister les boutiques MB
```http
GET /api/mb-shops
```

**Réponse:**
```json
{
  "shops": [
    {
      "id": 1,
      "name": "Boutique Premium",
      "description": "Articles exclusifs",
      "logo": "mb-shop-logos/shop1.jpg",
      "banner": "mb-shop-banners/shop1.jpg",
      "status": "active",
      "is_featured": true,
      "total_items": 25,
      "active_items": 20,
      "low_stock_items": 2,
      "created_at": "2026-05-12T14:30:00.000000Z"
    }
  ]
}
```

### Articles d'une boutique MB
```http
GET /api/mb-shops/{shopId}/items
```

**Query params:**
- `category`: catégorie
- `type`: digital, physical, voucher, subscription
- `featured`: true/false
- `min_price`: prix minimum
- `max_price`: prix maximum
- `in_stock`: true/false

**Réponse:**
```json
{
  "items": [
    {
      "id": 1,
      "name": "Badge Premium",
      "description": "Badge exclusif pour votre profil",
      "price_mb_coins": 50.00,
      "formatted_price": "50,00 MB",
      "type": "digital",
      "type_label": "Produit Digital",
      "category": "Badges",
      "stock": 999,
      "is_active": true,
      "is_featured": true,
      "is_available": true,
      "image_url": "http://localhost:8000/storage/mb-items/badge1.jpg",
      "created_at": "2026-05-12T14:30:00.000000Z",
      "can_purchase": true,
      "user_purchase_count": 0
    }
  ],
  "categories": ["Badges", "Avatars", "Thèmes"]
}
```

### Détails d'un article
```http
GET /api/mb-shop-items/{id}
```

### Acheter un article
```http
POST /api/mb-shop-items/{id}/purchase
```

**Body:**
```json
{
  "quantity": 1,
  "delivery_address": {
    "address": "123 Rue de la Paix",
    "city": "Paris",
    "postal_code": "75001",
    "country": "France"
  }
}
```

### Mes achats MB
```http
GET /api/mb-shop-purchases
```

**Query params:**
- `status`: pending, completed, cancelled, refunded
- `shop_id`: boutique
- `type`: type d'article

### Articles tendances
```http
GET /api/mb-shop-items/trending
```

### Articles promotionnels
```http
GET /api/mb-shop-items/promotional
```

### Recherche d'articles
```http
GET /api/mb-shop-items/search
```

**Query params:**
- `query`: terme de recherche
- `category`: catégorie
- `type`: type d'article
- `min_price`: prix minimum
- `max_price`: prix maximum

---

## Publicités

### Lister les publicités
```http
GET /api/ads
```

**Query params:**
- `shop_id`: boutique
- `campaign_id`: campagne
- `type`: banner, video, carousel, popup
- `position`: top, sidebar, bottom, popup, in_feed
- `status`: active, paused, expired

**Réponse:**
```json
{
  "ads": [
    {
      "id": 1,
      "title": "Promotion Été",
      "description": "-30% sur toute la collection",
      "image_url": "http://localhost:8000/storage/ads/promo1.jpg",
      "link_url": "https://example.com/promo",
      "type": "banner",
      "type_label": "Bannière",
      "position": "top",
      "position_label": "En haut",
      "status": "active",
      "status_label": "Active",
      "budget": 1000.00,
      "spent_amount": 250.50,
      "remaining_budget": 749.50,
      "impressions_count": 5000,
      "clicks_count": 150,
      "conversions_count": 25,
      "click_through_rate": 3.0,
      "conversion_rate": 16.67,
      "is_running": true,
      "created_at": "2026-05-12T14:30:00.000000Z",
      "shop": {
        "id": 1,
        "name": "Boutique Mode"
      }
    }
  ]
}
```

### Créer une publicité
```http
POST /api/ads
```

**Body:** `multipart/form-data`
- `title`: titre
- `description`: description
- `image`: fichier image
- `link_url`: URL de destination
- `type`: type de publicité
- `position`: position
- `budget`: budget total
- `cost_per_click`: coût par clic
- `cost_per_impression`: coût par impression
- `max_impressions`: max impressions
- `max_clicks`: max clics
- `starts_at`: date de début
- `ends_at`: date de fin

### Détails d'une publicité
```http
GET /api/ads/{id}
```

### Mettre à jour une publicité
```http
PUT /api/ads/{id}
```

### Supprimer une publicité
```http
DELETE /api/ads/{id}
```

### Démarrer une publicité
```http
POST /api/ads/{id}/start
```

### Mettre en pause une publicité
```http
POST /api/ads/{id}/pause
```

### Publicités actives (pour affichage)
```http
GET /api/ads/active
```

**Query params:**
- `position`: position spécifique
- `type`: type spécifique

### Enregistrer une impression
```http
POST /api/ads/{id}/impression
```

### Enregistrer un clic
```http
POST /api/ads/{id}/click
```

### Enregistrer une conversion
```http
POST /api/ads/{id}/conversion
```

**Body:**
```json
{
  "conversion_value": 50.00,
  "conversion_data": {
    "product_id": 1,
    "order_id": 123
  }
}
```

### Statistiques d'une publicité
```http
GET /api/ads/{id}/stats
```

### Publicités ciblées
```http
GET /api/ads/targeted
```

---

## Chat Admin

### Messages du chat admin
```http
GET /api/admin-chat
```

**Query params:**
- `user_id`: utilisateur spécifique
- `admin_id`: admin spécifique
- `unread_only`: messages non lus seulement
- `sender_type`: user/admin

**Réponse:**
```json
{
  "messages": [
    {
      "id": 1,
      "content": "Bonjour, j'ai un problème avec ma commande",
      "type": "text",
      "sender_type": "user",
      "is_from_user": true,
      "is_read": false,
      "created_at": "2026-05-12T14:30:00.000000Z",
      "formatted_time": "il y a 5 minutes",
      "user": {
        "id": 1,
        "name": "John Doe",
        "email": "john@example.com"
      },
      "admin": null
    }
  ]
}
```

### Conversation avec un utilisateur
```http
GET /api/admin-chat/conversation/{userId}
```

### Envoyer un message
```http
POST /api/admin-chat/send
```

**Body:** `multipart/form-data`
- `user_id`: ID utilisateur
- `content`: contenu du message
- `attachment`: fichier (optionnel)
- `type`: type de message

### Marquer comme lu
```http
PUT /api/admin-chat/mark-read
```

**Body:**
```json
{
  "message_ids": [1, 2, 3]
}
```

### Marquer tous comme lu
```http
PUT /api/admin-chat/mark-all-read/{userId}
```

### Nombre de messages non lus
```http
GET /api/admin-chat/unread-count
```

### Conversations récentes
```http
GET /api/admin-chat/recent-conversations
```

**Réponse:**
```json
{
  "conversations": [
    {
      "user": {
        "id": 1,
        "name": "John Doe",
        "email": "john@example.com"
      },
      "last_message_at": "2026-05-12T14:30:00.000000Z",
      "message_count": 5,
      "unread_count": 2
    }
  ]
}
```

### Supprimer un message
```http
DELETE /api/admin-chat/{id}
```

### Transférer une conversation
```http
POST /api/admin-chat/transfer/{userId}
```

**Body:**
```json
{
  "admin_id": 2
}
```

---

## Dashboard Admin

### Dashboard principal
```http
GET /api/dashboard
```

**Query params:**
- `period`: période en jours (défaut: 7)

**Réponse:**
```json
{
  "general_stats": {
    "total_users": 1500,
    "total_shops": 250,
    "total_products": 5000,
    "total_orders": 12000,
    "active_users": 450,
    "active_shops": 180,
    "new_users_period": 25,
    "new_shops_period": 8
  },
  "order_stats": {
    "total_revenue": 125000.50,
    "revenue_period": 8500.00,
    "orders_period": 150,
    "average_order_value": 56.67,
    "pending_orders": 12,
    "completed_orders": 118,
    "orders_by_status": [
      {"status": "pending", "count": 12},
      {"status": "completed", "count": 118}
    ]
  },
  "video_stats": {
    "total_videos": 850,
    "videos_period": 25,
    "public_videos": 720,
    "total_views": 15000,
    "views_period": 1200,
    "total_likes": 3500,
    "likes_period": 280,
    "trending_videos": [...]
  },
  "mb_coin_stats": {
    "total_mb_coins": 15000.50,
    "total_earned": 25000.00,
    "total_spent": 9999.50,
    "active_users": 800,
    "shop_revenue": 2500.00
  },
  "growth_charts": {
    "users_growth": [...],
    "orders_growth": [...],
    "revenue_growth": [...]
  },
  "recent_activity": {
    "recent_users": [...],
    "recent_orders": [...],
    "recent_videos": [...]
  }
}
```

### Statistiques détaillées
```http
GET /api/dashboard/detailed-stats
```

### Statistiques utilisateurs
```http
GET /api/dashboard/users
```

### Statistiques boutiques
```http
GET /api/dashboard/shops
```

### Statistiques commandes
```http
GET /api/dashboard/orders
```

### Statistiques vidéos
```http
GET /api/dashboard/videos
```

### Statistiques MB Coins
```http
GET /api/dashboard/mb-coins
```

### Statistiques système
```http
GET /api/dashboard/system
```

---

## Codes d'erreur

| Code | Message | Description |
|------|---------|-------------|
| 200 | OK | Requête réussie |
| 201 | Created | Ressource créée |
| 400 | Bad Request | Requête invalide |
| 401 | Unauthorized | Non authentifié |
| 403 | Forbidden | Accès refusé |
| 404 | Not Found | Ressource non trouvée |
| 422 | Unprocessable Entity | Erreur de validation |
| 500 | Internal Server Error | Erreur serveur |

---

## Centres d'intérêt Utilisateurs

### Lister les centres d'intérêt
```http
GET /api/user-interests
```

**Query params:**
- `is_active`: true/false
- `priority_level`: 1-5

**Réponse:**
```json
{
  "interests": [
    {
      "id": 1,
      "user_id": 1,
      "category_id": 1,
      "priority_level": 5,
      "is_active": true,
      "selected_at": "2026-05-12T14:30:00.000000Z",
      "priority_label": "Passionné",
      "category": {
        "id": 1,
        "name": "Mode",
        "icon": "fas fa-tshirt"
      }
    }
  ]
}
```

### Ajouter un centre d'intérêt
```http
POST /api/user-interests
```

**Body:**
```json
{
  "category_id": 1,
  "priority_level": 4,
  "metadata": {
    "preferences": ["casual", "formal"]
  }
}
```

### Sélectionner plusieurs catégories (onboarding)
```http
POST /api/user-interests/select-multiple
```

**Body:**
```json
{
  "categories": [
    {
      "category_id": 1,
      "priority_level": 5
    },
    {
      "category_id": 2,
      "priority_level": 3
    }
  ]
}
```

### Obtenir les catégories recommandées
```http
GET /api/user-interests/recommended-categories
```

**Réponse:**
```json
{
  "recommended_categories": [
    {
      "id": 3,
      "name": "Électronique",
      "products_count": 150,
      "interest_count": 25
    }
  ],
  "limit": 10
}
```

### Obtenir les catégories populaires
```http
GET /api/user-interests/popular?limit=20
```

### Statistiques des centres d'intérêt
```http
GET /api/user-interests/stats
```

**Réponse:**
```json
{
  "stats": {
    "total_interests": 5,
    "active_interests": 5,
    "high_priority_interests": 2,
    "medium_priority_interests": 2,
    "low_priority_interests": 1,
    "top_interests": [...],
    "recent_selections": [...]
  }
}
```

---

## Suivi des Habitudes Utilisateurs

### Enregistrer une action
```http
POST /api/user-habits/track
```

**Body:**
```json
{
  "action_type": "view",
  "entity_type": "product",
  "entity_id": "123",
  "metadata": {
    "source": "search_results",
    "position": 3
  },
  "context": {
    "page": "home",
    "section": "recommended"
  }
}
```

### Historique des vues
```http
GET /api/user-habits/view-history?limit=50&entity_type=product
```

### Catégories les plus consultées
```http
GET /api/user-habits/most-viewed-categories?limit=10&days=30
```

**Réponse:**
```json
{
  "most_viewed_categories": [
    {
      "category": {
        "id": 1,
        "name": "Mode"
      },
      "view_count": 45
    }
  ],
  "limit": 10,
  "days": 30
}
```

### Produits les plus consultés
```http
GET /api/user-habits/most-viewed-products?limit=20&days=30
```

### Historique des recherches
```http
GET /api/user-habits/search-history?limit=20&days=30
```

### Historique des achats
```http
GET /api/user-habits/purchase-history?limit=20&days=90
```

### Pattern d'activité
```http
GET /api/user-habits/activity-pattern?days=7
```

### Produits recommandés
```http
GET /api/user-habits/recommended-products?limit=10&days=30
```

### Boutiques recommandées
```http
GET /api/user-habits/recommended-shops?limit=10&days=30
```

### Vidéos recommandées
```http
GET /api/user-habits/recommended-videos?limit=10&days=30
```

### Statistiques des habitudes
```http
GET /api/user-habits/stats
```

**Réponse:**
```json
{
  "stats": {
    "total_actions": 150,
    "views_count": 80,
    "searches_count": 25,
    "purchases_count": 12,
    "clicks_count": 30,
    "likes_count": 8,
    "shares_count": 3,
    "bookmarks_count": 5,
    "most_viewed_categories": [...],
    "most_viewed_products": [...],
    "recent_activity": [...],
    "activity_pattern": [...]
  }
}
```

---

## Produits Recommandés (Page d'Accueil Personnalisée)

### Obtenir les produits recommandés
```http
GET /api/products/recommended?limit=20&days=30
```

**Réponse:**
```json
{
  "recommended_products": [
    {
      "id": 1,
      "name": "T-shirt Premium",
      "price": 29.99,
      "category": {
        "id": 1,
        "name": "Mode"
      },
      "shop": {
        "id": 1,
        "name": "Boutique Mode"
      },
      "view_count": 150,
      "sales_count": 45
    }
  ],
  "user_interests": [...],
  "limit": 20,
  "days": 30,
  "recommendation_type": "personalized"
}
```

### Produits tendance par intérêts
```http
GET /api/products/trending-by-interests?limit=15
```

### Produits similaires
```http
GET /api/products/{id}/similar?limit=10
```

**Réponse:**
```json
{
  "similar_products": [...],
  "original_product": {...},
  "limit": 10
}
```

---

## Notes importantes

1. **Authentification**: Toutes les routes (sauf `/register` et `/login`) nécessitent un token Bearer
2. **Pagination**: La plupart des listes supportent la pagination avec `limit` et `page`
3. **Fichiers**: Les uploads utilisent `multipart/form-data`
4. **Dates**: Format ISO 8601 (YYYY-MM-DDTHH:mm:ss.sssZ)
5. **Montants**: Format décimal avec 2 chiffres après la virgule
6. **Recherche**: La recherche est insensible à la casse
7. **Tri**: Options de tri disponibles selon les endpoints

---

## Exemple d'utilisation avec curl

### Inscription
```bash
curl -X POST http://localhost:8000/api/register \
  -H "Content-Type: application/json" \
  -d '{
    "name": "John Doe",
    "email": "john@example.com",
    "password": "password123",
    "password_confirmation": "password123",
    "role": "customer"
  }'
```

### Connexion
```bash
curl -X POST http://localhost:8000/api/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "john@example.com",
    "password": "password123"
  }'
```

### Lister les produits (authentifié)
```bash
curl -X GET http://localhost:8000/api/products \
  -H "Authorization: Bearer YOUR_TOKEN_HERE"
```

### Créer une boutique (authentifié)
```bash
curl -X POST http://localhost:8000/api/shops \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN_HERE" \
  -d '{
    "name": "Ma Boutique",
    "description": "Description de ma boutique",
    "address": "123 Rue Principale",
    "city": "Paris",
    "postal_code": "75001"
  }'
```

---

## Postman Collection

Une collection Postman complète est disponible avec tous les endpoints préconfigurés. Importez le fichier `Nora-API.postman_collection.json` pour commencer rapidement.

---

*Documentation générée automatiquement le 12 mai 2026*
