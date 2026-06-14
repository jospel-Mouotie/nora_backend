// lib/widgets/tracking_behavior.dart
import 'dart:async';
import 'package:flutter/material.dart';
import '../services/user_habit_api_service.dart';
import '../services/storage_service.dart';

/// Mixin pour le tracking des actions utilisateur
/// À utiliser dans n'importe quel widget StatefulWidget
mixin ProductTrackingMixin {
  late final UserHabitApiService _habitService;
  
  void _initProductTracking() {
    _habitService = UserHabitApiService();
  }
  
  /// Tracker la vue d'un produit
  Future<void> trackProductView({
    required int productId,
    required String source,
    String? section,
    Map<String, dynamic>? additionalContext,
  }) async {
    _initProductTracking();
    final token = await StorageService().getToken();
    if (token != null) {
      await _habitService.trackAction(
        token: token,
        actionType: 'view',
        entityType: 'product',
        entityId: productId.toString(),
        context: {
          'source': source,
          'section': section,
          'timestamp': DateTime.now().toIso8601String(),
          ...?additionalContext,
        },
      );
      debugPrint('📊 [TRACKING] Vue produit: $productId depuis $source${section != null ? ' ($section)' : ''}');
    }
  }
  
  /// Tracker le clic sur un produit
  Future<void> trackProductClick({
    required int productId,
    required String source,
    String? section,
    Map<String, dynamic>? additionalContext,
  }) async {
    _initProductTracking();
    final token = await StorageService().getToken();
    if (token != null) {
      await _habitService.trackAction(
        token: token,
        actionType: 'click',
        entityType: 'product',
        entityId: productId.toString(),
        context: {
          'source': source,
          'section': section,
          'timestamp': DateTime.now().toIso8601String(),
          ...?additionalContext,
        },
      );
      debugPrint('📊 [TRACKING] Clic produit: $productId depuis $source${section != null ? ' ($section)' : ''}');
    }
  }
  
  /// Tracker l'ajout au panier
  Future<void> trackAddToCart({
    required int productId,
    required int quantity,
    String? variantId,
    required String source,
  }) async {
    _initProductTracking();
    final token = await StorageService().getToken();
    if (token != null) {
      await _habitService.trackAction(
        token: token,
        actionType: 'click',
        entityType: 'product',
        entityId: productId.toString(),
        metadata: {
          'action': 'add_to_cart',
          'quantity': quantity,
          'variant_id': variantId,
        },
        context: {
          'source': source,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
      debugPrint('📊 [TRACKING] Ajout panier: $productId (x$quantity) depuis $source');
    }
  }
  
  /// Tracker l'achat direct
  Future<void> trackBuyNow({
    required int productId,
    required int quantity,
    required String source,
  }) async {
    _initProductTracking();
    final token = await StorageService().getToken();
    if (token != null) {
      await _habitService.trackAction(
        token: token,
        actionType: 'click',
        entityType: 'product',
        entityId: productId.toString(),
        metadata: {
          'action': 'buy_now',
          'quantity': quantity,
        },
        context: {
          'source': source,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
      debugPrint('📊 [TRACKING] Achat direct: $productId (x$quantity) depuis $source');
    }
  }
}

/// Mixin pour le tracking des recherches
mixin SearchTrackingMixin {
  late final UserHabitApiService _habitService;
  
  void _initSearchTracking() {
    _habitService = UserHabitApiService();
  }
  
  /// Tracker une recherche
  Future<void> trackSearch({
    required String query,
    int? resultsCount,
    String? source,
  }) async {
    _initSearchTracking();
    final token = await StorageService().getToken();
    if (token != null) {
      await _habitService.trackAction(
        token: token,
        actionType: 'search',
        entityType: 'product',
        entityId: 'search',
        metadata: {
          'query': query,
          'results_count': resultsCount,
        },
        context: {
          'source': source ?? 'search_page',
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
      debugPrint('📊 [TRACKING] Recherche: "$query" (${resultsCount ?? 0} résultats)');
    }
  }
  
  /// Tracker un clic sur une suggestion de recherche
  Future<void> trackSearchSuggestionClick({
    required String suggestion,
    required String source,
  }) async {
    _initSearchTracking();
    final token = await StorageService().getToken();
    if (token != null) {
      await _habitService.trackAction(
        token: token,
        actionType: 'click',
        entityType: 'product',
        entityId: 'search_suggestion',
        metadata: {
          'suggestion': suggestion,
        },
        context: {
          'source': source,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
      debugPrint('📊 [TRACKING] Clic suggestion: "$suggestion" depuis $source');
    }
  }
}

/// Mixin pour le tracking des boutiques
mixin ShopTrackingMixin {
  late final UserHabitApiService _habitService;
  
  void _initShopTracking() {
    _habitService = UserHabitApiService();
  }
  
  /// Tracker la vue d'une boutique
  Future<void> trackShopView({
    required int shopId,
    required String source,
    String? section,
  }) async {
    _initShopTracking();
    final token = await StorageService().getToken();
    if (token != null) {
      await _habitService.trackAction(
        token: token,
        actionType: 'view',
        entityType: 'shop',
        entityId: shopId.toString(),
        context: {
          'source': source,
          'section': section,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
      debugPrint('📊 [TRACKING] Vue boutique: $shopId depuis $source');
    }
  }
  
  /// Tracker le follow d'une boutique
  Future<void> trackShopFollow({
    required int shopId,
    required bool isFollowing,
    required String source,
  }) async {
    _initShopTracking();
    final token = await StorageService().getToken();
    if (token != null) {
      await _habitService.trackAction(
        token: token,
        actionType: isFollowing ? 'click' : 'unfollow',
        entityType: 'shop',
        entityId: shopId.toString(),
        metadata: {
          'action': isFollowing ? 'follow' : 'unfollow',
        },
        context: {
          'source': source,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
      debugPrint('📊 [TRACKING] ${isFollowing ? 'Follow' : 'Unfollow'} boutique: $shopId depuis $source');
    }
  }
}

/// Mixin pour le tracking des catégories
mixin CategoryTrackingMixin {
  late final UserHabitApiService _habitService;
  
  void _initCategoryTracking() {
    _habitService = UserHabitApiService();
  }
  
  /// Tracker la vue d'une catégorie
  Future<void> trackCategoryView({
    required int categoryId,
    required String categoryName,
    required String source,
  }) async {
    _initCategoryTracking();
    final token = await StorageService().getToken();
    if (token != null) {
      await _habitService.trackAction(
        token: token,
        actionType: 'view',
        entityType: 'category',
        entityId: categoryId.toString(),
        metadata: {
          'category_name': categoryName,
        },
        context: {
          'source': source,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
      debugPrint('📊 [TRACKING] Vue catégorie: $categoryName (id:$categoryId) depuis $source');
    }
  }
}

/// Mixin pour le tracking des vidéos (Reels)
mixin VideoTrackingMixin {
  late final UserHabitApiService _habitService;
  
  void _initVideoTracking() {
    _habitService = UserHabitApiService();
  }
  
  /// Tracker la vue d'une vidéo
  Future<void> trackVideoView({
    required int videoId,
    required String source,
    int? watchDuration,
  }) async {
    _initVideoTracking();
    final token = await StorageService().getToken();
    if (token != null) {
      await _habitService.trackAction(
        token: token,
        actionType: 'view',
        entityType: 'video',
        entityId: videoId.toString(),
        metadata: {
          'watch_duration': watchDuration,
        },
        context: {
          'source': source,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
      debugPrint('📊 [TRACKING] Vue vidéo: $videoId depuis $source');
    }
  }
  
  /// Tracker le like sur une vidéo
  Future<void> trackVideoLike({
    required int videoId,
    required bool isLiked,
    required String source,
  }) async {
    _initVideoTracking();
    final token = await StorageService().getToken();
    if (token != null) {
      await _habitService.trackAction(
        token: token,
        actionType: isLiked ? 'like' : 'unlike',
        entityType: 'video',
        entityId: videoId.toString(),
        context: {
          'source': source,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
      debugPrint('📊 [TRACKING] ${isLiked ? 'Like' : 'Unlike'} vidéo: $videoId depuis $source');
    }
  }
  
  /// Tracker le partage d'une vidéo
  Future<void> trackVideoShare({
    required int videoId,
    required String source,
    String? platform,
  }) async {
    _initVideoTracking();
    final token = await StorageService().getToken();
    if (token != null) {
      await _habitService.trackAction(
        token: token,
        actionType: 'share',
        entityType: 'video',
        entityId: videoId.toString(),
        metadata: {
          'platform': platform,
        },
        context: {
          'source': source,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
      debugPrint('📊 [TRACKING] Partage vidéo: $videoId depuis $source');
    }
  }
}

/// Mixin pour le tracking des avis
mixin ReviewTrackingMixin {
  late final UserHabitApiService _habitService;
  
  void _initReviewTracking() {
    _habitService = UserHabitApiService();
  }
  
  /// Tracker l'ajout d'un avis
  Future<void> trackReviewAdded({
    required int productId,
    required int rating,
    required String source,
  }) async {
    _initReviewTracking();
    final token = await StorageService().getToken();
    if (token != null) {
      await _habitService.trackAction(
        token: token,
        actionType: 'review',
        entityType: 'product',
        entityId: productId.toString(),
        metadata: {
          'rating': rating,
        },
        context: {
          'source': source,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
      debugPrint('📊 [TRACKING] Avis ajouté: produit $productId (note: $rating) depuis $source');
    }
  }
}

/// Mixin combiné pour le tracking complet
/// Utilisez ce mixin si vous voulez toutes les fonctionnalités
mixin FullTrackingMixin 
    on StatefulWidget {
  // Ce mixin combine tous les mixins ci-dessus
  // Note: L'implémentation réelle nécessite d'utiliser directement les mixins individuels
}

/// Widget utilitaire pour le tracking automatique
/// Peut être utilisé comme wrapper autour d'un widget enfant
class TrackingWidget extends StatefulWidget {
  final Widget child;
  final String? pageName;
  final Map<String, dynamic>? pageContext;
  final Duration? trackDuration;
  final VoidCallback? onPageEnter;
  final VoidCallback? onPageExit;

  const TrackingWidget({
    super.key,
    required this.child,
    this.pageName,
    this.pageContext,
    this.trackDuration,
    this.onPageEnter,
    this.onPageExit,
  });

  @override
  State<TrackingWidget> createState() => _TrackingWidgetState();
}

class _TrackingWidgetState extends State<TrackingWidget> 
    with ProductTrackingMixin, SearchTrackingMixin, ShopTrackingMixin, CategoryTrackingMixin, VideoTrackingMixin, ReviewTrackingMixin {
  DateTime? _enterTime;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _enterTime = DateTime.now();
    widget.onPageEnter?.call();
    
    // Tracker l'entrée sur la page
    if (widget.pageName != null) {
      _trackPageEnter();
    }
    
    // Tracker périodiquement le temps passé
    if (widget.trackDuration != null) {
      _timer = Timer.periodic(widget.trackDuration!, (timer) {
        _trackTimeSpent();
      });
    }
  }

  Future<void> _trackPageEnter() async {
    final token = await StorageService().getToken();
    if (token != null) {
      // Optionnel: tracker l'entrée sur la page
      debugPrint('📊 [TRACKING] Page visitée: ${widget.pageName}');
    }
  }

  Future<void> _trackTimeSpent() async {
    if (_enterTime != null && widget.pageName != null) {
      final duration = DateTime.now().difference(_enterTime!).inSeconds;
      // Optionnel: tracker le temps passé
      debugPrint('📊 [TRACKING] Temps passé sur ${widget.pageName}: ${duration}s');
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    widget.onPageExit?.call();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}