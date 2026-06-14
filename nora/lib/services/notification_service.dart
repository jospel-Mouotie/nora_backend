import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  // Canaux de notifications
  static const String _orderChannelId = 'nora_orders';
  static const String _chatChannelId = 'nora_chat';
  static const String _shopChannelId = 'nora_shop';
  static const String _generalChannelId = 'nora_general';

  Future<void> initialize() async {
    if (_isInitialized) return;

    const initAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initIOS = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: initAndroid,
      iOS: initIOS,
    );

    await _localNotifications.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: (details) {
        _handleNotificationTap(details.payload);
      },
    );

    // Créer les canaux Android
    await _createAndroidChannels();

    _isInitialized = true;
  }

  Future<void> _createAndroidChannels() async {
    final androidPlugin = _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin == null) return;

    await androidPlugin.createNotificationChannel(
      const AndroidNotificationChannel(
        _orderChannelId,
        'Commandes',
        description: 'Notifications pour vos commandes',
        importance: Importance.high,
        playSound: true,
      ),
    );

    await androidPlugin.createNotificationChannel(
      const AndroidNotificationChannel(
        _chatChannelId,
        'Messages',
        description: 'Notifications pour vos messages',
        importance: Importance.max,
        playSound: true,
      ),
    );

    await androidPlugin.createNotificationChannel(
      const AndroidNotificationChannel(
        _shopChannelId,
        'Boutiques',
        description: 'Notifications concernant vos boutiques',
        importance: Importance.high,
        playSound: true,
      ),
    );

    await androidPlugin.createNotificationChannel(
      const AndroidNotificationChannel(
        _generalChannelId,
        'Nora Notifications',
        description: 'Notifications générales',
        importance: Importance.defaultImportance,
        playSound: true,
      ),
    );
  }

  void _handleNotificationTap(String? payload) {
    if (payload == null) return;
    // La navigation est gérée par FcmService.onNotificationTap
  }

  // ==========================================
  // NOTIFICATIONS COMMANDES
  // ==========================================

  Future<void> showOrderNotification({
    required String orderId,
    required String status,
    String? title,
    String? body,
    String? payload,
  }) async {
    String notifTitle = title ?? 'Commande #$orderId';
    String notifBody = body ?? _getOrderStatusMessage(status);

    await _showNotification(
      id: _generateId('order_$orderId'),
      title: notifTitle,
      body: notifBody,
      channelId: _orderChannelId,
      channelName: 'Commandes',
      payload: payload ?? 'order_$orderId',
      icon: 'ic_order',
    );
  }

  String _getOrderStatusMessage(String status) {
    switch (status) {
      case 'confirmed':
        return '✅ Votre commande a été confirmée';
      case 'preparing':
        return '👨‍🍳 Votre commande est en cours de préparation';
      case 'ready':
        return '📦 Votre commande est prête à être livrée';
      case 'in_delivery':
        return '🚚 Votre commande est en cours de livraison';
      case 'delivered':
        return '🎉 Votre commande a été livrée avec succès !';
      case 'cancelled':
        return '❌ Votre commande a été annulée';
      case 'new_order':
        return '🛒 Nouvelle commande reçue !';
      default:
        return 'Le statut de votre commande a changé';
    }
  }

  // ==========================================
  // NOTIFICATIONS CHAT
  // ==========================================

  Future<void> showChatNotification({
    required String senderName,
    required String message,
    String? payload,
  }) async {
    await _showNotification(
      id: _generateId('chat_$senderName'),
      title: '💬 $senderName',
      body: message,
      channelId: _chatChannelId,
      channelName: 'Messages',
      payload: payload ?? 'chat',
      icon: 'ic_chat',
    );
  }

  // ==========================================
  // NOTIFICATIONS BOUTIQUE
  // ==========================================

  Future<void> showShopNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    await _showNotification(
      id: _generateId('shop_$title'),
      title: title,
      body: body,
      channelId: _shopChannelId,
      channelName: 'Boutiques',
      payload: payload ?? 'shop',
      icon: 'ic_shop',
    );
  }

  Future<void> showShopApprovedNotification(String shopName) async {
    await showShopNotification(
      title: '✅ Boutique validée !',
      body: 'Votre boutique "$shopName" a été approuvée par l\'administrateur.',
      payload: 'shop_approved',
    );
  }

  Future<void> showShopRejectedNotification(String shopName) async {
    await showShopNotification(
      title: '❌ Boutique refusée',
      body: 'Votre boutique "$shopName" n\'a pas été approuvée. Contactez le support.',
      payload: 'shop_rejected',
    );
  }

  Future<void> showShopCertifiedNotification(String shopName) async {
    await showShopNotification(
      title: '🏆 Boutique certifiée !',
      body: 'Félicitations ! Votre boutique "$shopName" est maintenant certifiée.',
      payload: 'shop_certified',
    );
  }

  // ==========================================
  // NOTIFICATIONS PRODUIT / VIDÉO (FOLLOWERS)
  // ==========================================

  Future<void> showNewProductNotification({
    required String shopName,
    required String productName,
    String? productId,
  }) async {
    await _showNotification(
      id: _generateId('product_${productId ?? productName}'),
      title: '🛍️ Nouveau produit - $shopName',
      body: '"$productName" vient d\'être ajouté à la boutique.',
      channelId: _generalChannelId,
      channelName: 'Nora Notifications',
      payload: productId != null ? 'product_$productId' : 'home',
    );
  }

  Future<void> showNewVideoNotification({
    required String shopName,
    required String videoTitle,
    String? videoId,
  }) async {
    await _showNotification(
      id: _generateId('video_${videoId ?? videoTitle}'),
      title: '🎬 Nouveau reel - $shopName',
      body: '"$videoTitle" est maintenant disponible.',
      channelId: _generalChannelId,
      channelName: 'Nora Notifications',
      payload: videoId != null ? 'video_$videoId' : 'reels',
    );
  }

  // ==========================================
  // NOTIFICATIONS ADMIN
  // ==========================================

  Future<void> showAdminNewShopNotification({
    required String shopName,
    required String ownerName,
  }) async {
    await _showNotification(
      id: _generateId('admin_shop_$shopName'),
      title: '🏪 Nouvelle boutique à valider',
      body: '$ownerName a créé la boutique "$shopName". En attente de validation.',
      channelId: _shopChannelId,
      channelName: 'Boutiques',
      payload: 'admin_validations',
    );
  }

  Future<void> showAdminNewOrderNotification({
    required String orderNumber,
    required double amount,
  }) async {
    await showOrderNotification(
      orderId: orderNumber,
      status: 'new_order',
      title: '🛒 Nouvelle commande #$orderNumber',
      body: 'Montant: ${amount.toStringAsFixed(0)} FCFA — À traiter.',
    );
  }

  // ==========================================
  // NOTIFICATIONS LIVRAISON
  // ==========================================

  Future<void> showDeliveryNotification({
    required String deliveryId,
    required String status,
    String? driverName,
  }) async {
    String title = '🚚 Livraison #$deliveryId';
    String body;

    switch (status) {
      case 'assigned':
        body = driverName != null
            ? 'Votre livraison est assignée à $driverName'
            : 'Un livreur a été assigné à votre commande';
        break;
      case 'in_progress':
        body = driverName != null
            ? '$driverName est en route vers vous'
            : 'Votre livreur est en route';
        break;
      case 'arrived':
        body = 'Votre livreur est arrivé à destination';
        break;
      case 'delivered':
        body = '✅ Livraison effectuée avec succès !';
        break;
      default:
        body = 'Le statut de votre livraison a changé';
    }

    await _showNotification(
      id: _generateId('delivery_$deliveryId'),
      title: title,
      body: body,
      channelId: _orderChannelId,
      channelName: 'Commandes',
      payload: 'delivery_$deliveryId',
    );
  }

  // ==========================================
  // NOTIFICATIONS PROMOTION
  // ==========================================

  Future<void> showPromotionNotification({
    required String title,
    required String description,
    String? productId,
  }) async {
    await _showNotification(
      id: _generateId('promo_$title'),
      title: '🎉 $title',
      body: description,
      channelId: _generalChannelId,
      channelName: 'Nora Notifications',
      payload: productId != null ? 'product_$productId' : 'promotions',
    );
  }

  // ==========================================
  // NOTIFICATION STOCK BAS (MARCHAND)
  // ==========================================

  Future<void> showLowStockNotification({
    required String productName,
    required int remainingStock,
    String? productId,
  }) async {
    await _showNotification(
      id: _generateId('stock_$productName'),
      title: '⚠️ Stock faible — $productName',
      body: 'Il reste seulement $remainingStock unité(s) en stock.',
      channelId: _shopChannelId,
      channelName: 'Boutiques',
      payload: productId != null ? 'product_$productId' : 'merchant_products',
    );
  }

  // ==========================================
  // MÉTHODES GÉNÉRIQUES
  // ==========================================

  /// Afficher une notification simple
  Future<void> showSimpleNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    await _showNotification(
      id: _generateId(title),
      title: title,
      body: body,
      channelId: _generalChannelId,
      channelName: 'Nora Notifications',
      payload: payload,
    );
  }

  /// Afficher une notification avec un ID personnalisé
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    await _showNotification(
      id: id,
      title: title,
      body: body,
      channelId: _generalChannelId,
      channelName: 'Nora Notifications',
      payload: payload,
    );
  }

  // ==========================================
  // MÉTHODE INTERNE
  // ==========================================

  Future<void> _showNotification({
    required int id,
    required String title,
    required String body,
    required String channelId,
    required String channelName,
    String? payload,
    String? icon,
  }) async {
    final androidDetails = AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: 'Notifications Nora Marketplace',
      importance: channelId == _chatChannelId
          ? Importance.max
          : Importance.high,
      priority: Priority.high,
      showWhen: true,
      icon: icon,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: details,
      payload: payload,
    );
  }

  int _generateId(String key) {
    // Retourne un entier positif pour l'ID de notification
    return (key.hashCode & 0x7fffffff) % 100000;
  }

  /// Annuler une notification spécifique
  Future<void> cancelNotification(int id) async {
    await _localNotifications.cancel(id: id);
  }

  /// Annuler toutes les notifications
  Future<void> cancelAllNotifications() async {
    await _localNotifications.cancelAll();
  }

  /// Vérifier si les notifications sont autorisées
  Future<bool> areNotificationsEnabled() async {
    // À implémenter avec flutter_local_notifications si besoin
    return true;
  }
}