# Structure des Modules React Native - Nora Marketplace

## 📱 Architecture Générale

### 🏗️ Structure du Projet
```
nora-mobile/
├── src/
│   ├── components/           # Composants UI réutilisables
│   ├── screens/             # Écrans de l'application
│   ├── navigation/          # Configuration de navigation
│   ├── services/            # Services API et utilitaires
│   ├── store/               # État global (Redux/Context)
│   ├── hooks/               # Hooks personnalisés
│   ├── utils/               # Fonctions utilitaires
│   ├── constants/           # Constantes et configurations
│   ├── assets/              # Images, icônes, polices
│   └── types/               # Types TypeScript
├── android/                 # Configuration Android
├── ios/                     # Configuration iOS
├── package.json
├── babel.config.js
├── metro.config.js
└── README.md
```

---

## 🧭 Modules Principaux

### 1. 🏠 Module Home (Écran Principal)
**Fichiers :**
- `src/screens/HomeScreen.tsx`
- `src/components/Home/RecommendedProducts.tsx`
- `src/components/Home/TrendingCategories.tsx`
- `src/components/Home/FeaturedShops.tsx`
- `src/components/Home/SearchBar.tsx`

**Fonctionnalités :**
- Produits recommandés personnalisés
- Catégories tendance par intérêts
- Barre de recherche intelligente
- Boutiques mises en avant
- Tracking des interactions

**API endpoints :**
- `GET /api/products/recommended`
- `GET /api/products/trending-by-interests`
- `GET /api/user-interests/popular`
- `POST /api/user-habits/track`

---

### 2. 🛍️ Module Produits
**Fichiers :**
- `src/screens/Products/ProductListScreen.tsx`
- `src/screens/Products/ProductDetailScreen.tsx`
- `src/screens/Products/ProductSearchScreen.tsx`
- `src/components/Products/ProductCard.tsx`
- `src/components/Products/ProductImage.tsx`
- `src/components/Products/ProductVariantSelector.tsx`

**Fonctionnalités :**
- Liste des produits avec filtres
- Détails produits avec variantes
- Recherche avec suggestions
- Ajout au panier
- Produits similaires

**API endpoints :**
- `GET /api/products`
- `GET /api/products/{id}`
- `GET /api/products/{id}/similar`
- `POST /api/cart/add`
- `GET /api/products/by-category/{id}`

---

### 3. 🏪 Module Boutiques
**Fichiers :**
- `src/screens/Shops/ShopListScreen.tsx`
- `src/screens/Shops/ShopDetailScreen.tsx`
- `src/screens/Shops/ShopProductsScreen.tsx`
- `src/components/Shops/ShopCard.tsx`
- `src/components/Shops/ShopHeader.tsx`
- `src/components/Shops/ShopFollowButton.tsx`

**Fonctionnalités :**
- Liste des boutiques
- Détails boutique avec produits
- Abonnement/like boutique
- Stories boutique
- Chat avec boutique

**API endpoints :**
- `GET /api/shops`
- `GET /api/shops/{id}`
- `POST /api/shops/{id}/follow`
- `POST /api/shops/{id}/like`
- `GET /api/shops/{id}/stories`

---

### 4. 🎥 Module Vidéos (Réels)
**Fichiers :**
- `src/screens/Videos/VideoFeedScreen.tsx`
- `src/screens/Videos/VideoPlayerScreen.tsx`
- `src/screens/Videos/VideoUploadScreen.tsx`
- `src/components/Videos/VideoCard.tsx`
- `src/components/Videos/VideoPlayer.tsx`
- `src/components/Videos/VideoComments.tsx`

**Fonctionnalités :**
- Feed vidéo (réels)
- Lecture avec tracking
- Like/commentaire/partage
- Upload vidéo
- Stories vidéo

**API endpoints :**
- `GET /api/videos`
- `GET /api/videos/trending`
- `GET /api/videos/{id}`
- `POST /api/videos/{id}/like`
- `POST /api/videos/upload`

---

### 5. 🛒 Module Panier & Commandes
**Fichiers :**
- `src/screens/Cart/CartScreen.tsx`
- `src/screens/Orders/OrderListScreen.tsx`
- `src/screens/Orders/OrderDetailScreen.tsx`
- `src/screens/Orders/CheckoutScreen.tsx`
- `src/components/Cart/CartItem.tsx`
- `src/components/Orders/OrderStatus.tsx`

**Fonctionnalités :**
- Gestion du panier
- Processus de commande
- Suivi des commandes
- Code PIN et QR code
- Historique des achats

**API endpoints :**
- `GET /api/cart`
- `POST /api/cart/add`
- `POST /api/orders`
- `GET /api/orders/{id}/qr-code`
- `GET /api/orders/{id}/pin`

---

### 6. 🚚 Module Livraison
**Fichiers :**
- `src/screens/Delivery/DeliveryTrackingScreen.tsx`
- `src/screens/Delivery/DeliveryChatScreen.tsx`
- `src/components/Delivery/MapView.tsx`
- `src/components/Delivery/DeliveryStatus.tsx`
- `src/components/Delivery/QRCodeScanner.tsx`

**Fonctionnalités :**
- Suivi GPS en temps réel
- Chat client-livreur
- Scan QR code
- Validation livraison
- Notifications

**API endpoints :**
- `GET /api/deliveries/{id}`
- `PUT /api/deliveries/{id}/location`
- `GET /api/chat/delivery/{id}`
- `POST /api/chat/delivery/{id}/send`
- `POST /api/delivery/scan-qr`

---

### 7. 💰 Module MB Coins
**Fichiers :**
- `src/screens/MBCoins/BalanceScreen.tsx`
- `src/screens/MBCoins/TransactionHistoryScreen.tsx`
- `src/screens/MBCoins/WithdrawScreen.tsx`
- `src/screens/MBCoins/MBShopScreen.tsx`
- `src/components/MBCoins/CoinBalance.tsx`
- `src/components/MBCoins/TransactionItem.tsx`

**Fonctionnalités :**
- Solde MB Coins
- Historique des transactions
- Retrait d'argent
- Boutique MB Coins
- Gains automatiques

**API endpoints :**
- `GET /api/mb-coins/balance`
- `GET /api/mb-coins/transactions`
- `POST /api/mb-coins/withdraw`
- `GET /api/mb-shops`
- `GET /api/mb-rewards`

---

### 8. 🎯 Module Centres d'Intérêt
**Fichiers :**
- `src/screens/Interests/OnboardingScreen.tsx`
- `src/screens/Interests/InterestSelectionScreen.tsx`
- `src/screens/Interests/RecommendedCategoriesScreen.tsx`
- `src/components/Interests/CategorySelector.tsx`
- `src/components/Interests/PrioritySelector.tsx`

**Fonctionnalités :**
- Onboarding sélection intérêts
- Modification des préférences
- Catégories recommandées
- Niveaux de priorité

**API endpoints :**
- `POST /api/user-interests/select-multiple`
- `GET /api/user-interests/recommended-categories`
- `GET /api/user-interests/available-categories`
- `PUT /api/user-interests/{id}`
- `GET /api/user-interests/stats`

---

### 9. 💬 Module Chat & Support
**Fichiers :**
- `src/screens/Chat/AdminChatScreen.tsx`
- `src/screens/Chat/DeliveryChatScreen.tsx`
- `src/components/Chat/MessageList.tsx`
- `src/components/Chat/MessageInput.tsx`
- `src/components/Chat/ChatBubble.tsx`

**Fonctionnalités :**
- Chat avec admin
- Chat avec livreur
- Notifications messages
- Historique des conversations
- Transfert de conversation

**API endpoints :**
- `GET /api/admin-chat`
- `POST /api/admin-chat/send`
- `GET /api/chat/delivery/{id}`
- `POST /api/chat/delivery/{id}/send`
- `GET /api/admin-chat/unread-count`

---

### 10. 👤 Module Profil & Paramètres
**Fichiers :**
- `src/screens/Profile/ProfileScreen.tsx`
- `src/screens/Profile/EditProfileScreen.tsx`
- `src/screens/Profile/SettingsScreen.tsx`
- `src/screens/Profile/InterestsScreen.tsx`
- `src/components/Profile/ProfileHeader.tsx`
- `src/components/Profile/StatsCard.tsx`

**Fonctionnalités :**
- Profil utilisateur
- Édition profil
- Paramètres application
- Centres d'intérêt
- Statistiques personnelles

**API endpoints :**
- `GET /api/user`
- `PUT /api/user`
- `POST /api/user/profile-picture`
- `GET /api/user-interests`
- `GET /api/user-habits/stats`

---

## 🧭 Navigation

### Structure de Navigation
```typescript
// Stack Navigator Principal
- Auth Stack (si non connecté)
  - LoginScreen
  - RegisterScreen
  - ForgotPasswordScreen

- Main Tab Navigator (si connecté)
  - Home Tab
    - HomeScreen
  - Search Tab
    - SearchScreen
    - CategoryScreen
  - Videos Tab
    - VideoFeedScreen
    - VideoUploadScreen
  - Cart Tab
    - CartScreen
    - OrderListScreen
  - Profile Tab
    - ProfileScreen
    - SettingsScreen

- Modal Navigators
  - ProductDetailModal
  - ShopDetailModal
  - VideoPlayerModal
  - ChatModal
```

---

## 🔧 Services et Utilitaires

### Services API
```typescript
// src/services/
├── api/
│   ├── auth.ts              # Authentification
│   ├── products.ts          # Produits
│   ├── shops.ts             # Boutiques
│   ├── videos.ts            # Vidéos
│   ├── cart.ts              # Panier
│   ├── orders.ts            # Commandes
│   ├── delivery.ts          # Livraison
│   ├── mbCoins.ts           # MB Coins
│   ├── interests.ts         # Centres d'intérêt
│   ├── habits.ts            # Habitudes
│   └── chat.ts              # Chat
├── storage/
│   ├── secureStorage.ts     # Stockage sécurisé
│   ├── asyncStorage.ts      # Stockage local
│   └── imageCache.ts        # Cache images
└── tracking/
    ├── analytics.ts         # Analytics
    ├── crashlytics.ts       # Crash reporting
    └── userHabits.ts        # Tracking habitudes
```

### Hooks Personnalisés
```typescript
// src/hooks/
├── useAuth.ts               # État authentification
├── useApi.ts               # Appels API génériques
├── useCart.ts              # État panier
├── useInterests.ts         # Centres d'intérêt
├── useHabits.ts            # Tracking habitudes
├── useRecommendations.ts   # Produits recommandés
├── useNotifications.ts     # Notifications
├── useLocation.ts          # Géolocalisation
└── useCamera.ts            # Appareil photo
```

---

## 🎨 Composants UI Réutilisables

### Composants Généraux
```typescript
// src/components/common/
├── Button/
│   ├── Button.tsx
│   ├── PrimaryButton.tsx
│   ├── SecondaryButton.tsx
│   └── IconButton.tsx
├── Input/
│   ├── TextInput.tsx
│   ├── SearchInput.tsx
│   └── PasswordInput.tsx
├── Card/
│   ├── Card.tsx
│   ├── ProductCard.tsx
│   └── ShopCard.tsx
├── Layout/
│   ├── Container.tsx
│   ├── ScreenContainer.tsx
│   └── SectionHeader.tsx
├── Loading/
│   ├── Spinner.tsx
│   ├── SkeletonLoader.tsx
│   └── PullToRefresh.tsx
└── Modal/
    ├── BottomSheet.tsx
    ├── AlertModal.tsx
    └── ImageModal.tsx
```

---

## 📊 État Global

### Structure Redux/Context
```typescript
// src/store/
├── slices/
│   ├── authSlice.ts         # Utilisateur connecté
│   ├── cartSlice.ts         # État panier
│   ├── productsSlice.ts     # Produits et recherche
│   ├── interestsSlice.ts    # Centres d'intérêt
│   ├── habitsSlice.ts       # Habitudes utilisateur
│   └── notificationsSlice.ts # Notifications
├── middleware/
│   ├── apiMiddleware.ts     # Appels API
│   ├── trackingMiddleware.ts # Tracking automatique
│   └── cacheMiddleware.ts    # Cache intelligent
└── store.ts                 # Configuration store
```

---

## 🔧 Configuration

### Dépendances Principales
```json
{
  "dependencies": {
    "@react-navigation/native": "^6.1.7",
    "@react-navigation/stack": "^6.3.17",
    "@react-navigation/bottom-tabs": "^6.5.8",
    "@reduxjs/toolkit": "^1.9.5",
    "react-redux": "^8.1.1",
    "axios": "^1.4.0",
    "react-native-vector-icons": "^9.2.0",
    "react-native-image-picker": "^5.6.0",
    "react-native-camera": "^4.2.1",
    "react-native-maps": "^1.7.1",
    "react-native-qrcode-scanner": "^1.5.5",
    "react-native-video": "^5.2.1",
    "react-native-gesture-handler": "^2.12.1",
    "react-native-reanimated": "^3.3.0",
    "react-native-safe-area-context": "^4.6.3"
  }
}
```

### Configuration Environment
```typescript
// src/constants/
├── api.ts                  # URLs API
├── colors.ts               # Palette de couleurs
├── dimensions.ts           # Dimensions écran
├── fonts.ts                # Polices
├── images.ts               # Images par défaut
└── config.ts               # Configuration générale
```

---

## 🚀 Ordre de Développement

### Phase 1 : Fondations
1. **Initialisation projet** React Native
2. **Configuration navigation** et structure
3. **Services API** de base
4. **Composants UI** réutilisables

### Phase 2 : Onboarding (Priorité 1)
1. **OnboardingScreen** avec 4 images de présentation
2. **Animation** entre les écrans d'onboarding
3. **Boutons de navigation** (Suivant/Sauter)
4. **Sauvegarde** de l'état d'onboarding

### Phase 3 : Centres d'Intérêt (Priorité 2)
1. **InterestSelectionScreen** avec catégories
2. **Niveaux de priorité** (1-5) pour chaque catégorie
3. **Validation** minimum 3 catégories
4. **API integration** pour sauvegarder les intérêts

### Phase 4 : Home Screen (Priorité 3)
1. **HomeScreen** avec produits recommandés personnalisés
2. **Tracking automatique** des interactions
3. **Recherche intelligente** avec suggestions
4. **Catégories tendance** basées sur les intérêts

### Phase 5 : Modules Core
1. **Produits** (liste, détail, recherche)
2. **Boutiques** (détail, abonnement)
3. **Panier** et **commandes**
4. **Livraison** et **tracking**

### Phase 6 : Modules Sociaux
1. **Vidéos** (réels, upload)
2. **Chat** (admin, livraison)
3. **MB Coins** et boutique virtuelle

### Phase 7 : Optimisations
1. **Performance** et cache
2. **Notifications** push
3. **Analytics** et tracking avancé
4. **Tests** et corrections

---

## 📱 Spécifications Techniques

### Plateformes Supportées
- **iOS** (iOS 13+)
- **Android** (API Level 21+)
- **React Native** 0.72+
- **TypeScript** 5+

### Performance Cibles
- **Temps de démarrage** < 3s
- **Navigation** fluide 60fps
- **Images** optimisées et cacheées
- **API** réponses < 2s
- **Mémoire** < 150MB

### Sécurité
- **Token JWT** stocké sécurisé
- **HTTPS** obligatoire
- **Validation** inputs côté client
- **Sanitization** données utilisateur
- **Biometric** authentification optionnelle

---

Cette structure permet un développement modulaire, maintenable et scalable tout en respectant l'architecture du backend existant ! 🚀
