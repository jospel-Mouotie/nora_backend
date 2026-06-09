# 🎯 Structure Complète du Projet Flutter Nora

## 📱 Architecture Flutter

### **🏗️ Structure des Dossiers**
```
nora/
├── lib/                           # 📦 Code source principal
│   ├── main.dart                   # 🚀 Point d'entrée
│   ├── app/                        # 📱 Application principale
│   │   ├── app.dart                 # 🏠 Widget racine
│   │   ├── core/                   # 🔧 Noyau de l'application
│   │   │   ├── constants/          # 📋 Constantes
│   │   │   │   ├── api_constants.dart
│   │   │   │   ├── app_constants.dart
│   │   │   │   └── route_constants.dart
│   │   │   ├── themes/             # 🎨 Thèmes et couleurs
│   │   │   │   ├── app_theme.dart
│   │   │   │   ├── app_colors.dart
│   │   │   │   ├── app_text_styles.dart
│   │   │   │   └── app_dimensions.dart
│   │   │   ├── utils/              # 🛠️ Utilitaires
│   │   │   │   ├── logger.dart
│   │   │   │   ├── validators.dart
│   │   │   │   ├── helpers.dart
│   │   │   │   └── extensions.dart
│   │   │   ├── network/            # 🌐 Réseau et API
│   │   │   │   ├── api_client.dart
│   │   │   │   ├── api_interceptors.dart
│   │   │   │   ├── network_info.dart
│   │   │   │   └── dio_client.dart
│   │   │   └── storage/           # 💾 Stockage local
│   │   │       ├── secure_storage.dart
│   │   │       ├── shared_prefs.dart
│   │   │       └── storage_keys.dart
│   │   ├── data/                  # 📊 Gestion des données
│   │   │   ├── models/             # 🏷️ Modèles de données
│   │   │   │   ├── user_model.dart
│   │   │   │   ├── product_model.dart
│   │   │   │   ├── shop_model.dart
│   │   │   │   ├── video_model.dart
│   │   │   │   ├── order_model.dart
│   │   │   │   ├── mb_coins_model.dart
│   │   │   │   └── interest_model.dart
│   │   │   ├── repositories/        # 🗄️ Repository pattern
│   │   │   │   ├── auth_repository.dart
│   │   │   │   ├── product_repository.dart
│   │   │   │   ├── shop_repository.dart
│   │   │   │   ├── video_repository.dart
│   │   │   │   └── mb_coins_repository.dart
│   │   │   └── datasources/        # 🔌 Sources de données
│   │   │       ├── local/           # 📱 Stockage local
│   │   │       │   ├── auth_local_datasource.dart
│   │   │       │   ├── product_local_datasource.dart
│   │   │       │   └── user_local_datasource.dart
│   │   │       └── remote/          # 🌐 API distante
│   │   │           ├── auth_remote_datasource.dart
│   │   │           ├── product_remote_datasource.dart
│   │   │           └── user_remote_datasource.dart
│   │   ├── domain/                # 🎯 Logique métier
│   │   │   ├── entities/          # 🏷️ Entités du domaine
│   │   │   │   ├── user_entity.dart
│   │   │   │   ├── product_entity.dart
│   │   │   │   ├── shop_entity.dart
│   │   │   │   └── interest_entity.dart
│   │   │   ├── usecases/          # ⚡ Cas d'utilisation
│   │   │   │   ├── auth/
│   │   │   │   │   ├── login_usecase.dart
│   │   │   │   │   ├── register_usecase.dart
│   │   │   │   │   └── logout_usecase.dart
│   │   │   │   ├── product/
│   │   │   │   │   ├── get_products_usecase.dart
│   │   │   │   │   ├── search_products_usecase.dart
│   │   │   │   │   └── get_product_details_usecase.dart
│   │   │   │   └── user/
│   │   │   │       ├── get_user_interests_usecase.dart
│   │   │   │       └── update_user_interests_usecase.dart
│   │   │   └── repositories/      # 🗄️ Interfaces repositories
│   │   │       ├── auth_repository_interface.dart
│   │   │       ├── product_repository_interface.dart
│   │   │       └── user_repository_interface.dart
│   │   └── presentation/         # 🎨 Interface utilisateur
│   │       ├── providers/          # 🏪 State management
│   │       │   ├── auth_provider.dart
│   │       │   ├── product_provider.dart
│   │       │   ├── user_provider.dart
│   │       │   └── mb_coins_provider.dart
│   │       ├── pages/              # 📱 Écrans principaux
│   │       │   ├── auth/
│   │       │   │   ├── login_page.dart
│   │       │   │   ├── register_page.dart
│   │       │   │   └── forgot_password_page.dart
│   │       │   ├── onboarding/
│   │       │   │   ├── onboarding_page.dart
│   │       │   │   ├── slide_1_page.dart
│   │       │   │   ├── slide_2_page.dart
│   │       │   │   ├── slide_3_page.dart
│   │       │   │   └── slide_4_page.dart
│   │       │   ├── interests/
│   │       │   │   ├── interests_selection_page.dart
│   │       │   │   ├── interests_detail_page.dart
│   │       │   │   └── interests_confirmation_page.dart
│   │       │   ├── home/
│   │       │   │   ├── home_page.dart
│   │       │   │   ├── search_page.dart
│   │       │   │   └── categories_page.dart
│   │       │   ├── products/
│   │       │   │   ├── product_list_page.dart
│   │       │   │   ├── product_detail_page.dart
│   │       │   │   ├── product_search_page.dart
│   │       │   │   └── product_filter_page.dart
│   │       │   ├── shops/
│   │       │   │   ├── shop_list_page.dart
│   │       │   │   ├── shop_detail_page.dart
│   │       │   │   └── shop_profile_page.dart
│   │       │   ├── videos/
│   │       │   │   ├── video_feed_page.dart
│   │       │   │   ├── video_player_page.dart
│   │       │   │   ├── video_upload_page.dart
│   │       │   │   └── video_comments_page.dart
│   │       │   ├── mb_coins/
│   │       │   │   ├── mb_coins_page.dart
│   │       │   │   ├── mb_coins_history_page.dart
│   │       │   │   ├── mb_shop_page.dart
│   │       │   │   └── mb_rewards_page.dart
│   │       │   ├── cart/
│   │       │   │   ├── cart_page.dart
│   │       │   │   ├── checkout_page.dart
│   │       │   │   └── payment_page.dart
│   │       │   ├── orders/
│   │       │   │   ├── order_list_page.dart
│   │       │   │   ├── order_detail_page.dart
│   │       │   │   └── order_tracking_page.dart
│   │       │   ├── delivery/
│   │       │   │   ├── delivery_tracking_page.dart
│   │       │   │   ├── delivery_status_page.dart
│   │       │   │   └── delivery_chat_page.dart
│   │       │   ├── chat/
│   │       │   │   ├── chat_list_page.dart
│   │       │   │   ├── chat_page.dart
│   │       │   │   └── admin_chat_page.dart
│   │       │   └── profile/
│   │       │       ├── profile_page.dart
│   │       │       ├── edit_profile_page.dart
│   │       │       ├── settings_page.dart
│   │       │       └── security_page.dart
│   │       ├── widgets/            # 🧩 Composants réutilisables
│   │       │   ├── common/           # Composants génériques
│   │       │   │   ├── custom_button.dart
│   │       │   │   ├── custom_text_field.dart
│   │       │   │   ├── custom_app_bar.dart
│   │       │   │   ├── loading_widget.dart
│   │       │   │   ├── error_widget.dart
│   │       │   │   ├── empty_state_widget.dart
│   │       │   │   └── network_image_widget.dart
│   │       │   ├── auth/             # Composants auth
│   │       │   │   ├── login_form.dart
│   │       │   │   ├── register_form.dart
│   │       │   │   └── forgot_password_form.dart
│   │       │   ├── onboarding/       # Composants onboarding
│   │       │   │   ├── onboarding_slide.dart
│   │       │   │   ├── slide_indicators.dart
│   │       │   │   └── animated_button.dart
│   │       │   ├── interests/        # Composants intérêts
│   │       │   │   ├── category_grid.dart
│   │       │   │   ├── priority_slider.dart
│   │       │   │   ├── category_card.dart
│   │       │   │   └── selected_categories_list.dart
│   │       │   ├── home/             # Composants home
│   │       │   │   ├── product_card.dart
│   │       │   │   ├── category_carousel.dart
│   │       │   │   ├── featured_shops.dart
│   │       │   │   ├── search_bar.dart
│   │       │   │   └── video_feed.dart
│   │       │   ├── products/         # Composants produits
│   │       │   │   ├── product_image.dart
│   │       │   │   ├── product_info.dart
│   │       │   │   ├── product_reviews.dart
│   │       │   │   ├── filter_modal.dart
│   │       │   │   └── comparison_table.dart
│   │       │   ├── shops/            # Composants boutiques
│   │       │   │   ├── shop_card.dart
│   │       │   │   ├── shop_header.dart
│   │       │   │   ├── shop_products.dart
│   │       │   │   ├── follow_button.dart
│   │       │   │   └── shop_story.dart
│   │       │   ├── videos/           # Composants vidéos
│   │       │   │   ├── video_card.dart
│   │       │   │   ├── video_player.dart
│   │       │   │   ├── video_controls.dart
│   │       │   │   ├── video_comments.dart
│   │       │   │   └── video_upload.dart
│   │       │   ├── mb_coins/         # Composants MB Coins
│   │       │   │   ├── balance_card.dart
│   │       │   │   ├── transaction_item.dart
│   │       │   │   ├── reward_card.dart
│   │       │   │   ├── shop_item.dart
│   │       │   │   └── coin_transfer.dart
│   │       │   ├── cart/             # Composants panier
│   │       │   │   ├── cart_item.dart
│   │       │   │   ├── cart_summary.dart
│   │       │   │   ├── checkout_step.dart
│   │       │   │   ├── payment_method.dart
│   │       │   │   └── order_card.dart
│   │       │   ├── delivery/         # Composants livraison
│   │       │   │   ├── delivery_map.dart
│   │       │   │   ├── delivery_status.dart
│   │       │   │   ├── delivery_instructions.dart
│   │       │   │   └── driver_info.dart
│   │       │   ├── chat/             # Composants chat
│   │       │   │   ├── message_bubble.dart
│   │       │   │   ├── message_input.dart
│   │       │   │   ├── chat_header.dart
│   │       │   │   ├── message_status.dart
│   │       │   │   └── typing_indicator.dart
│   │       │   └── profile/          # Composants profil
│   │       │       ├── profile_header.dart
│   │       │       ├── profile_info.dart
│   │       │       ├── settings_item.dart
│   │       │       ├── security_options.dart
│   │       │       └── preferences_form.dart
│   │       └── routes/            # 🧭 Navigation
│   │           ├── app_router.dart
│   │           ├── route_names.dart
│   │           ├── route_generator.dart
│   │           └── navigation_service.dart
│   └── generated/                  # 🔧 Code généré
│       ├── intl/                 # 🌐 Internationalisation
│       └── assets.g.dart         # 🎨 Assets générés
├── assets/                         # 🎨 Ressources
│   ├── images/                 # 🖼️ Images
│   │   ├── onboarding/
│   │   │   ├── slide1.png
│   │   │   ├── slide2.png
│   │   │   ├── slide3.png
│   │   │   └── slide4.png
│   │   ├── logos/
│   │   │   ├── nora_logo.png
│   │   │   └── nora_icon.png
│   │   ├── products/
│   │   │   ├── placeholders/
│   │   │   └── categories/
│   │   ├── shops/
│   │   │   ├── placeholders/
│   │   │   └── banners/
│   │   └── ui/
│   │       ├── backgrounds/
│   │       ├── patterns/
│   │       └── icons/
│   ├── icons/                  # 🎯 Icônes
│   │   ├── app_icon.png
│   │   ├── app_icon_ios.png
│   │   └── app_icon_android.png
│   └── fonts/                  # 🔤 Polices
│       ├── nora_font.ttf
│       └── nora_font_bold.ttf
├── test/                           # 🧪 Tests
│   ├── unit/                   # Tests unitaires
│   ├── widget/                  # Tests de widgets
│   └── integration/             # Tests d'intégration
├── pubspec.yaml                    # 📦 Dépendances
├── analysis_options.yaml            # 🔍 Analyse du code
└── README.md                       # 📚 Documentation
```

---

## 🎯 Architecture en Couches (Clean Architecture)

### **📱 Presentation Layer**
- **Pages**: Écrans de l'application
- **Widgets**: Composants UI réutilisables
- **Providers**: State management (Provider pattern)
- **Routes**: Navigation et routing

### **🎯 Domain Layer**
- **Entities**: Objets métier purs
- **UseCases**: Logique métier (Clean Architecture)
- **Repositories**: Interfaces de données

### **📊 Data Layer**
- **Models**: Modèles de données (JSON/API)
- **Repositories**: Implémentation des interfaces
- **DataSources**: API et stockage local

### **🔧 Core Layer**
- **Constants**: URLs, clés API, etc.
- **Themes**: Couleurs, styles, dimensions
- **Utils**: Helpers, validators, extensions
- **Network**: Client HTTP, interceptors
- **Storage**: SharedPreferences, SecureStorage

---

## 🎨 Thème et Couleurs

### **🌈 Palette de Couleurs**
```dart
class AppColors {
  // Couleurs principales
  static const Color primary = Color(0xFF10B981);      // Vert émeraude
  static const Color primaryDark = Color(0xFF059669);  // Vert émeraude foncé
  static const Color primaryLight = Color(0xFF34D399);  // Vert émeraude clair
  
  // Couleurs secondaires
  static const Color secondary = Color(0xFFF97316);     // Orange vif
  static const Color secondaryDark = Color(0xFFEA580C); // Orange foncé
  static const Color secondaryLight = Color(0xFFFB923C); // Orange clair
  
  // Couleurs neutres
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);
  static const Color gray = Color(0xFF6B7280);
  static const Color grayLight = Color(0xFFF3F4F6);
  static const Color grayDark = Color(0xFF374151);
  
  // Couleurs de fond
  static const Color background = Color(0xFFFFFFFF);
  static const Color surface = Color(0xFFF9FAFB);
}
```

---

## 🚀 Modules de Développement

### **📋 15 Modules Organisés**

#### **🔥 Phase 1: Fondations**
1. **Module 1** - Authentification (login, register, forgot password)
2. **Module 2** - Onboarding (4 slides avec images)
3. **Module 3** - Centres d'Intérêt (catégories, priorités)
4. **Module 4** - Navigation Principale (bottom tabs, stack)
5. **Module 5** - Home Screen (produits recommandés)

#### **⚡ Phase 2: Core Features**
6. **Module 6** - Gestion des Produits (détails, recherche)
7. **Module 7** - Gestion des Boutiques (profil, abonnements)
8. **Module 8** - Système de Vidéos (lecture, likes)
9. **Module 9** - Panier et Commandes (paiement, suivi)

#### **🚀 Phase 3: Advanced Features**
10. **Module 10** - Livraison (tracking, statuts)
11. **Module 11** - MB Coins (solde, transactions)
12. **Module 12** - Chat et Messagerie (admin-client)
13. **Module 13** - Profil Utilisateur (paramètres, historique)
14. **Module 14** - Services API (connexion, cache)
15. **Module 15** - État Global (providers, state)

---

## 🛠️ Technologies Utilisées

### **📱 Framework & UI**
- **Flutter** 3.x (dernière version stable)
- **Material Design 3** avec personnalisation
- **Cupertino Design** pour iOS
- **Adaptive UI** responsive

### **🗄️ State Management**
- **Provider Pattern** (recommandé Flutter)
- **ChangeNotifier** pour les états réactifs
- **StateNotifier** pour la logique complexe

### **🌐 Réseau & API**
- **Dio** pour les requêtes HTTP
- **Retrofit** généré pour les endpoints
- **Interceptors** pour authentification et erreurs

### **💾 Stockage**
- **SharedPreferences** pour les préférences
- **FlutterSecureStorage** pour les tokens
- **Hive** pour les données locales (JSON)

### **🎨 Navigation**
- **GoRouter** pour le routing déclaratif
- **AutoRoute** pour la navigation générée
- **Deep Linking** support

### **🔧 Développement**
- **Dart** avec null-safety
- **Flutter Lints** pour la qualité
- **Very Good Analysis** pour le score

---

## 📱 Dépendances Principales

```yaml
dependencies:
  flutter:
    sdk: flutter
  
  # UI & Navigation
  cupertino_icons: ^1.0.6
  material_icons: ^1.0.6
  go_router: ^12.1.3
  auto_route: ^7.9.2
  
  # State Management
  provider: ^6.1.1
  flutter_riverpod: ^2.4.9
  
  # Réseau & API
  dio: ^5.3.4
  retrofit: ^4.0.3
  json_annotation: ^4.8.1
  
  # Stockage
  shared_preferences: ^2.2.2
  flutter_secure_storage: ^9.0.0
  hive: ^2.2.3
  hive_flutter: ^1.1.0
  
  # Utils
  equatable: ^2.0.5
  uuid: ^4.2.1
  intl: ^0.18.1
  image_picker: ^1.0.4
  permission_handler: ^11.0.1
  
  # UI Components
  cached_network_image: ^3.3.0
  shimmer: ^3.2.0
  lottie: ^2.7.0
  flutter_svg: ^2.0.9
  google_fonts: ^6.1.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  
  # Code Generation
  build_runner: ^2.4.7
  retrofit_generator: ^8.0.4
  json_serializable: ^6.7.1
  hive_generator: ^2.0.1
  auto_route_generator: ^7.9.2
  
  # Analyse
  flutter_lints: ^3.0.1
  very_good_analysis: ^5.1.0
```

---

## 🎯 Avantages de cette Structure

### **✅ Scalabilité**
- Architecture modulaire et extensible
- Séparation claire des responsabilités
- Code réutilisable et maintenable

### **🔧 Maintenabilité**
- Clean Architecture pour la clarté
- Tests faciles à écrire
- Documentation intégrée

### **🚀 Performance**
- State management optimisé
- Lazy loading des écrans
- Cache intelligent des données

### **📱 Qualité**
- Type safety avec Dart
- Lints et analyse automatique
- Tests complets

---

**Cette structure Flutter est prête pour un développement professionnel et évolutif !** 🚀
