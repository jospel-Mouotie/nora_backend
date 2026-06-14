import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:nora/views/admin/admin_dashboard_page.dart';
import 'package:nora/views/delivery_driver/driver_dashboard_page.dart';
import '../config/app_colors.dart';


// ==================== MODULE 1 - STRUCTURE & NAVIGATION ====================
import '../views/splash_screen.dart';
import '../views/home/home_page.dart';
import '../views/categories/categories_page.dart';
import '../views/cart/cart_page.dart';
import '../views/profile/profile_page.dart';
import '../views/videos/video_feed_page.dart';

// ==================== MODULE 2 - AUTHENTIFICATION ====================
import '../views/auth/login_page.dart';
import '../views/auth/register_page.dart';
import '../views/auth/forgot_password_page.dart';
import '../views/auth/email_verification_page.dart';

// ==================== MODULE 3 - ONBOARDING ====================
import '../views/onboarding/onboarding_page.dart';

// ==================== MODULE 4 - CENTRES D'INTÉRÊT ====================
import '../views/onboarding/interests_page.dart';

// ==================== MODULE 5 & 6 - HOME & CATÉGORIES ====================
import '../views/home/search_page.dart';
import '../views/categories/category_products_page.dart';

// ==================== MODULE 7 - PRODUITS ====================
import '../views/product/product_detail_page.dart';
import '../views/product/product_reviews_page.dart';

// ==================== MODULE 8 - BOUTIQUES ====================
import '../views/shop/shop_detail_page.dart';

// ==================== MODULE 10 - COMMANDES ====================
import '../views/orders/checkout_page.dart';
import '../views/orders/order_success_page.dart';
import '../views/orders/order_detail_page.dart';
import '../views/orders/order_history_page.dart';

// ==================== MODULE 11 - VIDÉOS ====================
import '../views/videos/video_player_page.dart';
import '../views/videos/video_upload_page.dart';

// =================== MODULE 12 - MB COINS ====================
import '../views/mb_coins/mb_coins_page.dart';
import '../views/mb_coins/transactions_page.dart';
import '../views/mb_coins/rewards_page.dart';
import '../views/mb_coins/withdraw_page.dart';

// ==================== MODULE 13 - BOUTIQUE MB ====================
import '../views/mb_shop/mb_shop_page.dart';
import '../views/mb_shop/mb_item_detail_page.dart';
import '../views/mb_shop/mb_purchases_page.dart';

// ==================== MODULE 14 - LIVRAISON ====================
import '../views/delivery/delivery_tracking_page.dart';
import '../views/delivery/scan_qr_page.dart';
import '../views/chat/chat_delivery_page.dart';

// ==================== MODULE 15 - CHAT ADMIN ====================
import '../views/chat/chat_admin_list_page.dart';
import '../views/chat/chat_admin_conversation_page.dart';

// ==================== MODULE 16 - PROFIL ====================
import '../views/profile/edit_profile_page.dart';

// ==================== MODULE 17 - PARAMÈTRES ====================
import '../views/settings/settings_page.dart';
import '../views/settings/notifications_page.dart';

// ==================== MODULE 18 - PUBLICITÉS ====================
import '../views/ads/ads_list_page.dart';
import '../views/ads/ad_detail_page.dart';
import '../views/ads/create_ad_page.dart';
import '../views/ads/ads_all_page.dart';

// ==================== MODULE 22 - PROMOTIONS ====================
import '../views/promotions/promotions_all_page.dart';

// ==================== MODULE 19 - DASHBOARD COMMERÇANT ====================
import '../views/merchant/merchant_dashboard_page.dart';
import '../views/merchant/merchant_shop_page.dart';
import '../views/merchant/merchant_products_page.dart';
import '../views/merchant/merchant_videos_page.dart';
import '../views/merchant/merchant_orders_page.dart';
import '../views/merchant/merchant_stats_page.dart';
import '../views/merchant/add_product_page.dart';

// ==================== MODULE 20 - DASHBOARD LIVREUR ====================
import '../views/delivery_driver/driver_missions_page.dart';
import '../views/delivery_driver/driver_earnings_page.dart';

// ==================== MODULE 21 - DASHBOARD ADMIN ====================
import '../views/admin/admin_users_page.dart';
import '../views/admin/admin_shops_page.dart';
import '../views/admin/admin_orders_page.dart';
import '../views/admin/admin_validations_page.dart';
import '../views/admin/admin_categories_page.dart';

import 'package:flutter/services.dart';

// ==================== EXTENSION SAFE POP ====================
extension SafePopExtension on BuildContext {
  void safePop() {
    if (Navigator.of(this).canPop()) {
      pop();
    } else {
      go('/home');
    }
  }
}

// ==================== APP BACK BUTTON DISPATCHER ====================
class AppBackButtonDispatcher extends RootBackButtonDispatcher {
  AppBackButtonDispatcher();

  @override
  Future<bool> didPopRoute() async {
    final router = AppRoutes.router;
    
    // 1. Si GoRouter peut effectuer un retour en arrière classique
    if (router.canPop()) {
      router.pop();
      return true; // Événement géré, l'application reste ouverte
    }

    // 2. Si GoRouter ne peut pas pop (pile de navigation vide)
    final BuildContext? context = router.routerDelegate.navigatorKey.currentContext;
    final String location = router.routerDelegate.currentConfiguration.uri.path;

    // Si on est sur l'une des pages racines
    if (location == AppRoutes.home || 
        location == AppRoutes.splash || 
        location == AppRoutes.login || 
        location == AppRoutes.register || 
        location == AppRoutes.onboarding) {
      
      if (context != null) {
        // Demander confirmation à l'aide d'un dialogue premium avant de quitter
        final exitApp = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Row(
              children: [
                Icon(Icons.exit_to_app, color: AppColors.primary),
                SizedBox(width: 8),
                Text('Quitter l\'application'),
              ],
            ),
            content: const Text('Voulez-vous vraiment quitter NORA Marketplace ?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text(
                  'Annuler',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('Quitter'),
              ),
            ],
          ),
        );

        if (exitApp == true) {
          await SystemNavigator.pop();
        }
      }
      return true; // Empêche la fermeture immédiate de l'application
    } 
    // Pour n'importe quelle autre page, on redirige vers l'accueil au lieu de quitter l'application
    else {
      router.go(AppRoutes.home);
      return true; // Événement géré
    }
  }
}


// ==================== CLASS APP ROUTES ====================
class AppRoutes {

  // ==================== CONSTANTES DES ROUTES ====================

  // Module 1 - Structure & Navigation
  static const String splash = '/';
  static const String home = '/home';
  static const String categories = '/categories';
  static const String reels = '/reels';
  static const String cart = '/cart';
  static const String profile = '/profile';

  // Module 2 - Authentification
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';
  static const String verifyEmail = '/verify-email';
  static const String resetPassword = '/reset-password';

  // Module 3 - Onboarding
  static const String onboarding = '/onboarding';

  // Module 4 - Centres d'intérêt
  static const String interests = '/interests';

  // Module 5 & 6 - Home & Catégories
  static const String search = '/search';
  static const String categoryProducts = '/category-products';
  static const String productDetail = '/product';
  static const String productReviews = '/product-reviews';
  static const String shopDetail = '/shop';

  // Module 10 - Commandes
  static const String checkout = '/checkout';
  static const String orderSuccess = '/order-success';
  static const String orderDetail = '/order-detail';
  static const String orderHistory = '/order-history';

  // Module 11 - Vidéos
  static const String videoPlayer = '/video-player';
  static const String videoUpload = '/video-upload';

  // Module 22 - Promotions
  static const String promotionsAll = '/promotions/all';

  // Module 12 - MB Coins
  static const String mbCoins = '/mb-coins';
  static const String mbCoinsTransactions = '/mb-coins/transactions';
  static const String mbCoinsRewards = '/mb-coins/rewards';
  static const String mbCoinsWithdraw = '/mb-coins/withdraw';

  // Module 13 - Boutique MB
  static const String mbShop = '/mb-shop';
  static const String mbShopItem = '/mb-shop/item';
  static const String mbPurchases = '/mb-purchases';

  // Module 14 - Livraison
  static const String orderTracking = '/order-tracking';
  static const String scanQr = '/delivery/scan-qr';
  static const String chatDelivery = '/chat-delivery';

  // Module 15 - Chat Admin
  static const String chatAdmin = '/chat-admin';
  static const String chatAdminConversation = '/chat-admin/conversation';

  // Module 16 - Profil
  static const String editProfile = '/edit-profile';

  // Module 17 - Paramètres
  static const String settings = '/settings';
  static const String notifications = '/notifications';
  static const String privacy = '/privacy';

  // Module 18 - Publicités
  static const String adsList = '/ads/list';
  static const String adDetail = '/ads/:id';
  static const String createAd = '/ads/create';
  static const String adsAll = '/ads/all';

  // Module 19 - Dashboard Commerçant
  static const String merchantDashboard = '/merchant/dashboard';
  static const String merchantShop = '/merchant/shop';
  static const String merchantProducts = '/merchant/products';
  static const String merchantVideos = '/merchant/videos';
  static const String merchantOrders = '/merchant/orders';
  static const String merchantStats = '/merchant/stats';
  static const String addProduct = '/merchant/add-product';

  // Module 20 - Dashboard Livreur
  static const String driverDashboard = '/driver/dashboard';
  static const String driverMissions = '/driver/missions';
  static const String driverEarnings = '/driver/earnings';
  static const String driverHistory = '/driver/history';

  // Module 21 - Dashboard Admin
  static const String adminDashboard = '/admin/dashboard';
  static const String adminUsers = '/admin/users';
  static const String adminShops = '/admin/shops';
  static const String adminOrders = '/admin/orders';
  static const String adminValidations = '/admin/validations';
  static const String adminCategories = '/admin/categories';

  // ==================== CONFIGURATION DU ROUTER ====================
  static final GoRouter router = GoRouter(
    initialLocation: splash,
    routes: [

      // ==================== MODULE 1 - STRUCTURE & NAVIGATION ====================
      GoRoute(
        path: splash,
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: home,
        name: 'home',
        builder: (context, state) => const HomePage(),
      ),
      GoRoute(
        path: categories,
        name: 'categories',
        builder: (context, state) => const CategoriesPage(),
      ),
      GoRoute(
        path: reels,
        name: 'reels',
        builder: (context, state) {
          final videoId = state.uri.queryParameters['videoId'];
          return VideoFeedPage(videoId: videoId);
        },
      ),
      GoRoute(
        path: cart,
        name: 'cart',
        builder: (context, state) => const CartPage(),
      ),
      GoRoute(
        path: profile,
        name: 'profile',
        builder: (context, state) => const ProfilePage(),
      ),

      // ==================== MODULE 2 - AUTHENTIFICATION ====================
      GoRoute(
        path: login,
        name: 'login',
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: register,
        name: 'register',
        builder: (context, state) => const RegisterPage(),
      ),
      GoRoute(
        path: forgotPassword,
        name: 'forgotPassword',
        builder: (context, state) => const ForgotPasswordPage(),
      ),
      GoRoute(
        path: '/email-verification',
        name: 'emailVerification',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return EmailVerificationPage(
            email: extra?['email'] ?? '',
            name: extra?['name'] ?? '',
          );
        },
      ),
      GoRoute(
        path: verifyEmail,
        name: 'verifyEmail',
        builder: (context, state) => const Scaffold(
          body: Center(child: Text('Vérification email - À venir')),
        ),
      ),
      GoRoute(
        path: resetPassword,
        name: 'resetPassword',
        builder: (context, state) {
          final email = state.uri.queryParameters['email'] ?? '';
          return Scaffold(
            body: Center(child: Text('Reset Password pour: $email - À venir')),
          );
        },
      ),

      // ==================== MODULE 3 - ONBOARDING ====================
      GoRoute(
        path: onboarding,
        name: 'onboarding',
        builder: (context, state) => const OnboardingPage(),
      ),

      // ==================== MODULE 4 - CENTRES D'INTÉRÊT ====================
      GoRoute(
        path: interests,
        name: 'interests',
        builder: (context, state) => const InterestsPage(),
      ),

      // ==================== MODULE 5 & 6 - HOME & CATÉGORIES ====================
      GoRoute(
        path: search,
        name: 'search',
        builder: (context, state) => const SearchPage(),
      ),
      GoRoute(
        path: '$categoryProducts/:categoryId',
        name: 'categoryProducts',
        builder: (context, state) {
          final categoryId = int.parse(state.pathParameters['categoryId']!);
          final categoryName = state.uri.queryParameters['name'] ?? 'Catégorie';
          final subcategoryId = state.uri.queryParameters['subcategory']?.isNotEmpty == true
              ? int.parse(state.uri.queryParameters['subcategory']!)
              : null;
          final sortBy = state.uri.queryParameters['sort'] ?? 'recent';
          return CategoryProductsPage(
            categoryId: categoryId,
            categoryName: categoryName,
            subcategoryId: subcategoryId,
            sortBy: sortBy,
          );
        },
      ),

      // ==================== MODULE 7 - PRODUITS ====================
      GoRoute(
        path: '$productDetail/:productId',
        name: 'productDetail',
        builder: (context, state) {
          final productId = int.parse(state.pathParameters['productId']!);
          return ProductDetailPage(productId: productId);
        },
      ),
      GoRoute(
        path: '$productReviews/:productId',
        name: 'productReviews',
        builder: (context, state) {
          final productId = int.parse(state.pathParameters['productId']!);
          return ProductReviewsPage(productId: productId);
        },
      ),

      // ==================== MODULE 8 - BOUTIQUES ====================
      GoRoute(
        path: '$shopDetail/:shopId',
        name: 'shopDetail',
        builder: (context, state) {
          final shopId = int.parse(state.pathParameters['shopId']!);
          return ShopDetailPage(shopId: shopId);
        },
      ),

      // ==================== MODULE 10 - COMMANDES ====================
      GoRoute(
        path: checkout,
        name: 'checkout',
        builder: (context, state) => const CheckoutPage(),
      ),
      GoRoute(
        path: orderSuccess,
        name: 'orderSuccess',
        builder: (context, state) {
          final orderId = state.uri.queryParameters['orderId'] ?? '';
          return OrderSuccessPage(orderId: orderId);
        },
      ),
      GoRoute(
        path: '$orderDetail/:orderId',
        name: 'orderDetail',
        builder: (context, state) {
          final orderId = state.pathParameters['orderId']!;
          return OrderDetailPage(orderId: orderId);
        },
      ),
      GoRoute(
        path: orderHistory,
        name: 'orderHistory',
        builder: (context, state) => const OrderHistoryPage(),
      ),

      // ==================== MODULE 11 - VIDÉOS ====================
      GoRoute(
        path: '$videoPlayer/:videoId',
        name: 'videoPlayer',
        builder: (context, state) {
          final videoId = int.parse(state.pathParameters['videoId']!);
          return VideoPlayerPage(videoId: videoId);
        },
      ),
      GoRoute(
        path: videoUpload,
        name: 'videoUpload',
        builder: (context, state) => const VideoUploadPage(),
      ),

      // ==================== MODULE 12 - MB COINS ====================
      GoRoute(
        path: mbCoins,
        name: 'mbCoins',
        builder: (context, state) => const MbCoinsPage(),
      ),
      GoRoute(
        path: mbCoinsTransactions,
        name: 'mbCoinsTransactions',
        builder: (context, state) => const TransactionsPage(),
      ),
      GoRoute(
        path: mbCoinsRewards,
        name: 'mbCoinsRewards',
        builder: (context, state) => const RewardsPage(),
      ),
      GoRoute(
        path: mbCoinsWithdraw,
        name: 'mbCoinsWithdraw',
        builder: (context, state) => const WithdrawPage(),
      ),

      // ==================== MODULE 13 - BOUTIQUE MB ====================
      GoRoute(
        path: mbShop,
        name: 'mbShop',
        builder: (context, state) => const MbShopPage(),
      ),
      GoRoute(
        path: '$mbShopItem/:itemId',
        name: 'mbShopItem',
        builder: (context, state) {
          final itemId = int.parse(state.pathParameters['itemId']!);
          return MbItemDetailPage(itemId: itemId);
        },
      ),
      GoRoute(
        path: mbPurchases,
        name: 'mbPurchases',
        builder: (context, state) => const MbPurchasesPage(),
      ),

      // ==================== MODULE 14 - LIVRAISON ====================
      GoRoute(
        path: '$orderTracking/:deliveryId',
        name: 'orderTracking',
        builder: (context, state) {
          final deliveryId = int.parse(state.pathParameters['deliveryId']!);
          return DeliveryTrackingPage(deliveryId: deliveryId);
        },
      ),
      GoRoute(
        path: scanQr,
        name: 'scanQr',
        builder: (context, state) => const ScanQrPage(),
      ),
      GoRoute(
        path: '$chatDelivery/:deliveryId',
        name: 'chatDelivery',
        builder: (context, state) {
          final deliveryId = int.parse(state.pathParameters['deliveryId']!);
          return ChatDeliveryPage(deliveryId: deliveryId);
        },
      ),

      // ==================== MODULE 15 - CHAT ADMIN ====================
      GoRoute(
        path: chatAdmin,
        name: 'chatAdmin',
        builder: (context, state) => const ChatAdminListPage(),
      ),
      GoRoute(
        path: '$chatAdminConversation/:userId',
        name: 'chatAdminConversation',
        builder: (context, state) {
          final userId = int.parse(state.pathParameters['userId']!);
          return ChatAdminConversationPage(userId: userId);
        },
      ),

      // ==================== MODULE 16 - PROFIL ====================
      GoRoute(
        path: editProfile,
        name: 'editProfile',
        builder: (context, state) => const EditProfilePage(),
      ),

      // ==================== MODULE 17 - PARAMÈTRES ====================
      GoRoute(
        path: settings,
        name: 'settings',
        builder: (context, state) => const SettingsPage(),
      ),
      GoRoute(
        path: notifications,
        name: 'notifications',
        builder: (context, state) => const NotificationsPage(),
      ),
      GoRoute(
        path: privacy,
        name: 'privacy',
        builder: (context, state) => const Scaffold(
          body: Center(child: Text('Page Confidentialité - À venir')),
        ),
      ),

      // ==================== MODULE 18 - PUBLICITÉS ====================
      GoRoute(
        path: adsList,
        name: 'adsList',
        builder: (context, state) => const AdsListPage(),
      ),
      GoRoute(
        path: '$adDetail/:adId',
        name: 'adDetail',
        builder: (context, state) {
          final adId = int.parse(state.pathParameters['adId']!);
          return AdDetailPage(adId: adId);
        },
      ),
      GoRoute(
        path: createAd,
        name: 'createAd',
        builder: (context, state) => const CreateAdPage(),
      ),
      GoRoute(
        path: adsAll,
        name: 'adsAll',
        builder: (context, state) => const AdsAllPage(),
      ),
      GoRoute(
        path: promotionsAll,
        name: 'promotionsAll',
        builder: (context, state) => const PromotionsAllPage(),
      ),

      // ==================== MODULE 19 - DASHBOARD COMMERÇANT ====================
      GoRoute(
        path: merchantDashboard,
        name: 'merchantDashboard',
        builder: (context, state) => const MerchantDashboardPage(),
      ),
      GoRoute(
        path: merchantShop,
        name: 'merchantShop',
        builder: (context, state) => const MerchantShopPage(),
      ),
      GoRoute(
        path: merchantProducts,
        name: 'merchantProducts',
        builder: (context, state) => const MerchantProductsPage(),
      ),
      GoRoute(
        path: merchantVideos,
        name: 'merchantVideos',
        builder: (context, state) => const MerchantVideosPage(),
      ),
      GoRoute(
        path: merchantOrders,
        name: 'merchantOrders',
        builder: (context, state) => const MerchantOrdersPage(),
      ),
      GoRoute(
        path: merchantStats,
        name: 'merchantStats',
        builder: (context, state) => const MerchantStatsPage(),
      ),
      GoRoute(
        path: addProduct,
        name: 'addProduct',
        builder: (context, state) => const AddProductPage(),
      ),

      // ==================== MODULE 20 - DASHBOARD LIVREUR ====================
      GoRoute(
        path: driverDashboard,
        name: 'driverDashboard',
        builder: (context, state) => const DriverDashboardPage(),
      ),
      GoRoute(
        path: driverMissions,
        name: 'driverMissions',
        builder: (context, state) => const DriverMissionsPage(),
      ),
      GoRoute(
        path: driverEarnings,
        name: 'driverEarnings',
        builder: (context, state) => const DriverEarningsPage(),
      ),
      GoRoute(
        path: driverHistory,
        name: 'driverHistory',
        builder: (context, state) => const Scaffold(
          body: Center(child: Text('Historique livreur - À venir')),
        ),
      ),

      // ==================== MODULE 21 - DASHBOARD ADMIN ====================
      GoRoute(
        path: adminDashboard,
        name: 'adminDashboard',
        builder: (context, state) => const AdminDashboardPage(),
      ),
      GoRoute(
        path: adminUsers,
        name: 'adminUsers',
        builder: (context, state) => const AdminUsersPage(),
      ),
      GoRoute(
        path: adminShops,
        name: 'adminShops',
        builder: (context, state) => const AdminShopsPage(),
      ),
      GoRoute(
        path: adminOrders,
        name: 'adminOrders',
        builder: (context, state) => const AdminOrdersPage(),
      ),
      GoRoute(
        path: adminValidations,
        name: 'adminValidations',
        builder: (context, state) => const AdminValidationsPage(),
      ),
      GoRoute(
        path: adminCategories,
        name: 'adminCategories',
        builder: (context, state) => const AdminCategoriesPage(),
      ),
    ],

    // ==================== GESTION DES ERREURS ====================
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 80, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Page non trouvée',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${state.uri}',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go(home),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              child: const Text('Retour à l\'accueil'),
            ),
          ],
        ),
      ),
    ),
  );

  // ==================== MÉTHODES UTILITAIRES ====================

  // Navigation vers les pages principales
  static void goToHome(BuildContext context) {
    context.go(home);
  }

  static void goToLogin(BuildContext context) {
    context.go(login);
  }

  static void goToRegister(BuildContext context) {
    context.go(register);
  }

  static void goToCategories(BuildContext context) {
    context.go(categories);
  }

  static void goToReels(BuildContext context) {
    context.go(reels);
  }

  static void goToCart(BuildContext context) {
    context.go(cart);
  }

  static void goToProfile(BuildContext context) {
    context.go(profile);
  }

  // Navigation vers onboarding et intérêts
  static void goToOnboarding(BuildContext context) {
    context.go(onboarding);
  }

  static void goToInterests(BuildContext context) {
    context.go(interests);
  }

  // Navigation vers recherche et catégories
  static void goToSearch(BuildContext context) {
    context.go(search);
  }

  static void goToCheckout(BuildContext context) {
    context.go(checkout);
  }

  static void goToOrderHistory(BuildContext context) {
    context.go(orderHistory);
  }

  // Navigation vers produits et boutiques
  static void goToProduct(BuildContext context, int productId) {
    context.go('$productDetail/$productId');
  }

  static void goToProductReviews(BuildContext context, int productId) {
    context.go('$productReviews/$productId');
  }

  static void goToShop(BuildContext context, int shopId) {
    context.go('$shopDetail/$shopId');
  }

  // Navigation vers vidéos
  static void goToVideoPlayer(BuildContext context, int videoId) {
    context.go('$videoPlayer/$videoId');
  }

  static void goToVideoUpload(BuildContext context) {
    context.go(videoUpload);
  }

  // Navigation vers MB Coins
  static void goToMbCoins(BuildContext context) {
    context.go(mbCoins);
  }

  static void goToMbCoinsTransactions(BuildContext context) {
    context.go(mbCoinsTransactions);
  }

  static void goToMbCoinsRewards(BuildContext context) {
    context.go(mbCoinsRewards);
  }

  static void goToMbCoinsWithdraw(BuildContext context) {
    context.go(mbCoinsWithdraw);
  }

  // Navigation vers Boutique MB
  static void goToMbShop(BuildContext context) {
    context.go(mbShop);
  }

  static void goToMbShopItem(BuildContext context, int itemId) {
    context.go('$mbShopItem/$itemId');
  }

  static void goToMbPurchases(BuildContext context) {
    context.go(mbPurchases);
  }

  // Navigation vers livraison
  static void goToOrderTracking(BuildContext context, int deliveryId) {
    context.go('$orderTracking/$deliveryId');
  }

  static void goToScanQr(BuildContext context) {
    context.go(scanQr);
  }

  static void goToChatDelivery(BuildContext context, int deliveryId) {
    context.go('$chatDelivery/$deliveryId');
  }

  // Navigation vers chat admin
  static void goToChatAdmin(BuildContext context) {
    context.go(chatAdmin);
  }

  static void goToChatAdminConversation(BuildContext context, int userId) {
    context.go('$chatAdminConversation/$userId');
  }

  // Navigation vers profil
  static void goToEditProfile(BuildContext context) {
    context.go(editProfile);
  }

  // Navigation vers paramètres
  static void goToSettings(BuildContext context) {
    context.go(settings);
  }

  static void goToNotifications(BuildContext context) {
    context.go(notifications);
  }

  // Navigation vers publicités
  static void goToAdsList(BuildContext context) {
    context.go(adsList);
  }

  static void goToCreateAd(BuildContext context) {
    context.go(createAd);
  }

  // Navigation vers dashboard commerçant
  static void goToMerchantDashboard(BuildContext context) {
    context.go(merchantDashboard);
  }

  static void goToMerchantShop(BuildContext context) {
    context.go(merchantShop);
  }

  static void goToMerchantProducts(BuildContext context) {
    context.go(merchantProducts);
  }

  static void goToMerchantVideos(BuildContext context) {
    context.go(merchantVideos);
  }

  static void goToMerchantOrders(BuildContext context) {
    context.go(merchantOrders);
  }

  static void goToMerchantStats(BuildContext context) {
    context.go(merchantStats);
  }

  // Navigation vers dashboard livreur
  static void goToDriverDashboard(BuildContext context) {
    context.go(driverDashboard);
  }

  static void goToDriverMissions(BuildContext context) {
    context.go(driverMissions);
  }

  static void goToDriverEarnings(BuildContext context) {
    context.go(driverEarnings);
  }

  // Navigation vers dashboard admin
  static void goToAdminDashboard(BuildContext context) {
    context.go(adminDashboard);
  }

  static void goToAdminUsers(BuildContext context) {
    context.go(adminUsers);
  }

  static void goToAdminShops(BuildContext context) {
    context.go(adminShops);
  }

  static void goToAdminOrders(BuildContext context) {
    context.go(adminOrders);
  }

  static void goToAdminValidations(BuildContext context) {
    context.go(adminValidations);
  }

  static void goToAdminCategories(BuildContext context) {
    context.go(adminCategories);
  }

  // Navigation vers catégories produits avec filtres
  static void goToCategoryProducts(
    BuildContext context, {
    required int categoryId,
    required String categoryName,
    int? subcategoryId,
    String sortBy = 'recent',
  }) {
    String url = '$categoryProducts/$categoryId?name=${Uri.encodeComponent(categoryName)}&sort=$sortBy';
    if (subcategoryId != null) {
      url += '&subcategory=$subcategoryId';
    }
    context.go(url);
  }

  // Retour arrière sécurisé
  static void goBack(BuildContext context) {
    context.safePop();
  }
}
