import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../config/app_constants.dart';
import 'notification_service.dart';
import 'storage_service.dart';

/// Handler pour les messages en background (doit être en top-level)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('📩 Background message: ${message.messageId}');
  debugPrint('📩 Title: ${message.notification?.title}');
  debugPrint('📩 Body: ${message.notification?.body}');
  debugPrint('📩 Data: ${message.data}');
}

class FcmService {
  static final FcmService _instance = FcmService._internal();
  factory FcmService() => _instance;
  FcmService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  String? _fcmToken;
  bool _isInitialized = false;

  String? get fcmToken => _fcmToken;

  // Callback pour la navigation — injecté depuis main.dart ou dans build()
  static void Function(String action, Map<String, dynamic> data)? onNotificationTap;

  /// Initialiser FCM et gérer les notifications
  Future<void> initialize() async {
    if (_isInitialized) {
      debugPrint('⚠️ FCM déjà initialisé');
      return;
    }

    try {
      // Demander la permission
      final settings = await _firebaseMessaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        debugPrint('✅ Permission notifications accordée');
      } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
        debugPrint('⚠️ Permission notifications provisoire');
      } else {
        debugPrint('❌ Permission notifications refusée');
        return;
      }

      // Obtenir le token FCM
      _fcmToken = await _firebaseMessaging.getToken();
      debugPrint('📱 FCM Token: $_fcmToken');

      if (_fcmToken != null) {
        await _sendTokenToBackend(_fcmToken!);
      }

      // Messages en foreground
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // Clics sur notification (app en arrière-plan)
      FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationClick);

      // App lancée depuis une notification
      final initialMessage = await _firebaseMessaging.getInitialMessage();
      if (initialMessage != null) {
        debugPrint('🚀 App lancée depuis une notification');
        // Délai pour que le router soit prêt
        await Future.delayed(const Duration(milliseconds: 500));
        _handleNotificationClick(initialMessage);
      }

      // Rafraîchissement du token
      _firebaseMessaging.onTokenRefresh.listen((newToken) {
        debugPrint('🔄 Token FCM rafraîchi: $newToken');
        _fcmToken = newToken;
        _sendTokenToBackend(newToken);
      });

      _isInitialized = true;
      debugPrint('✅ FCM initialisé avec succès');
    } catch (e) {
      debugPrint('❌ Erreur initialisation FCM: $e');
    }
  }

  /// Forcer la synchronisation du token FCM avec le serveur (utile après connexion)
  Future<void> syncToken() async {
    try {
      _fcmToken ??= await _firebaseMessaging.getToken();
      if (_fcmToken != null) {
        await _sendTokenToBackend(_fcmToken!);
      }
    } catch (e) {
      debugPrint('❌ Erreur syncToken: $e');
    }
  }

  /// Envoyer le token FCM au backend
  Future<void> _sendTokenToBackend(String token) async {
    try {
      final authToken = await StorageService().getToken();
      if (authToken == null) {
        debugPrint('⚠️ Pas de token auth, FCM token non envoyé');
        return;
      }

      final response = await http.post(
        Uri.parse('${AppConstants.apiBaseUrl}/fcm-token'),
        headers: {
          'Authorization': 'Bearer $authToken',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({'fcm_token': token}),
      );

      if (response.statusCode == 200) {
        debugPrint('✅ Token FCM enregistré sur le backend');
      } else {
        debugPrint('❌ Erreur enregistrement token: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ Erreur envoi token FCM: $e');
    }
  }

  /// Supprimer le token FCM (lors de la déconnexion)
  Future<void> removeTokenFromBackend() async {
    try {
      final authToken = await StorageService().getToken();
      if (authToken == null) return;

      final response = await http.delete(
        Uri.parse('${AppConstants.apiBaseUrl}/fcm-token'),
        headers: {
          'Authorization': 'Bearer $authToken',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        debugPrint('✅ Token FCM supprimé du backend');
      }
    } catch (e) {
      debugPrint('❌ Erreur suppression token FCM: $e');
    }
  }

  /// Gérer les messages reçus en foreground (app ouverte)
  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('📨 Message reçu en foreground: ${message.notification?.title}');

    final action = message.data['action'] ?? '';
    final notifService = NotificationService();

    if (message.notification != null) {
      // Choisir le canal selon le type de notification
      if (action.startsWith('order') || action == 'new_order') {
        notifService.showOrderNotification(
          orderId: message.data['order_id'] ?? '',
          status: message.data['status'] ?? 'update',
          title: message.notification!.title,
          body: message.notification!.body,
          payload: jsonEncode(message.data),
        );
      } else if (action == 'new_message' || action == 'open_chat') {
        notifService.showChatNotification(
          senderName: message.data['sender_name'] ?? 'Nouveau message',
          message: message.notification!.body ?? '',
          payload: jsonEncode(message.data),
        );
      } else if (action.startsWith('shop')) {
        notifService.showShopNotification(
          title: message.notification!.title ?? 'Boutique',
          body: message.notification!.body ?? '',
          payload: jsonEncode(message.data),
        );
      } else {
        notifService.showSimpleNotification(
          title: message.notification!.title ?? 'Nouvelle notification',
          body: message.notification!.body ?? '',
          payload: jsonEncode(message.data),
        );
      }
    }
  }

  /// Gérer les clics sur les notifications
  void _handleNotificationClick(RemoteMessage message) {
    debugPrint('👆 Notification cliquée - action: ${message.data['action']}');

    final action = message.data['action'] ?? '';
    final data = Map<String, dynamic>.from(message.data);

    // Appeler le callback de navigation si disponible
    if (onNotificationTap != null) {
      onNotificationTap!(action, data);
    } else {
      debugPrint('⚠️ Callback navigation non défini, action: $action');
    }
  }

  /// Naviguer selon l'action de notification
  static void navigateFromNotification(
    BuildContext context,
    String action,
    Map<String, dynamic> data,
  ) {
    // Import routes inline pour éviter les dépendances circulaires
    try {
      switch (action) {
        case 'order_details':
        case 'new_order':
        case 'order_confirmed':
        case 'order_preparing':
        case 'order_ready':
        case 'order_delivered':
        case 'order_cancelled':
          final orderId = data['order_id']?.toString();
          if (orderId != null) {
            Navigator.of(context).pushNamed('/order-detail/$orderId');
          }
          break;

        case 'shop_approved':
        case 'shop_certified':
        case 'shop_rejected':
          Navigator.of(context).pushNamed('/merchant/shop');
          break;

        case 'new_message':
        case 'open_chat':
          final deliveryId = data['delivery_id']?.toString();
          if (deliveryId != null) {
            Navigator.of(context).pushNamed('/chat-delivery/$deliveryId');
          } else {
            Navigator.of(context).pushNamed('/chat-admin');
          }
          break;

        case 'product_created':
        case 'new_product':
          final productId = data['product_id']?.toString();
          if (productId != null) {
            Navigator.of(context).pushNamed('/product/$productId');
          }
          break;

        case 'new_video':
        case 'video_created':
          final videoId = data['video_id']?.toString();
          if (videoId != null) {
            Navigator.of(context).pushNamed('/video-player/$videoId');
          }
          break;

        case 'admin_shop_pending':
          Navigator.of(context).pushNamed('/admin/validations');
          break;

        case 'low_stock':
          final productId = data['product_id']?.toString();
          if (productId != null) {
            Navigator.of(context).pushNamed('/product/$productId');
          }
          break;

        default:
          debugPrint('⚠️ Action inconnue: $action');
      }
    } catch (e) {
      debugPrint('❌ Erreur navigation notification: $e');
    }
  }

  /// S'abonner à un topic
  Future<void> subscribeToTopic(String topic) async {
    try {
      await _firebaseMessaging.subscribeToTopic(topic);
      debugPrint('✅ Abonné au topic: $topic');
    } catch (e) {
      debugPrint('❌ Erreur abonnement topic: $e');
    }
  }

  /// Se désabonner d'un topic
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _firebaseMessaging.unsubscribeFromTopic(topic);
      debugPrint('✅ Désabonné du topic: $topic');
    } catch (e) {
      debugPrint('❌ Erreur désabonnement topic: $e');
    }
  }
}
