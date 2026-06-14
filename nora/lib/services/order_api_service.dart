import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_constants.dart';

class OrderApiService {
  static const String baseUrl = AppConstants.apiBaseUrl;

  // Créer une commande
  Future<Map<String, dynamic>> createOrder({
    required String deliveryAddress,
    String? notes,
    required String token,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/orders'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'delivery_address': deliveryAddress,
          'notes': notes,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          'success': true,
          'order': data['order'],
        };
      } else {
        return {'success': false, 'message': data['message'] ?? 'Erreur lors de la création'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Erreur de connexion'};
    }
  }

  // Lister les commandes
  Future<Map<String, dynamic>> getOrders({String? status, int limit = 20, required String token}) async {
    try {
      final queryParams = <String, String>{};
      queryParams['limit'] = limit.toString();
      if (status != null) queryParams['status'] = status;

      final uri = Uri.parse('$baseUrl/orders').replace(queryParameters: queryParams);
      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'orders': data['orders'] ?? data,
        };
      } else {
        return {'success': false, 'orders': []};
      }
    } catch (e) {
      print('Erreur getOrders: $e');
      return {'success': false, 'orders': []};
    }
  }

  // Détails d'une commande
  Future<Map<String, dynamic>> getOrder(String orderId, String token) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/orders/$orderId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'order': data['order'] ?? data,
        };
      } else {
        return {'success': false, 'message': 'Commande non trouvée'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Erreur de connexion'};
    }
  }

  // ========== QR CODE & PIN ==========

  // Vérifier un QR code
  Future<Map<String, dynamic>> verifyQrCode(String qrCode, String token) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/orders/verify-qr/$qrCode'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'order': data['order'],
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'QR code invalide',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Erreur de connexion au serveur',
      };
    }
  }

  // Marquer un QR code comme utilisé
  Future<Map<String, dynamic>> useQrCode(String qrCode, String token) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/orders/use-qr/$qrCode'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': data['message'] ?? 'QR code utilisé',
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Erreur lors de l\'utilisation du QR code',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Erreur de connexion au serveur',
      };
    }
  }

  // Vérifier un PIN
  Future<Map<String, dynamic>> verifyPin(String pin, String token) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/orders/verify-pin/$pin'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'order': data['order'],
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'PIN invalide',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Erreur de connexion au serveur',
      };
    }
  }

  // Mettre à jour le statut d'une commande
  Future<Map<String, dynamic>> updateOrderStatus(String orderId, String status, String token) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/orders/$orderId/status'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'status': status,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'order': data['order'],
          'message': data['message'] ?? 'Statut mis à jour',
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Erreur lors de la mise à jour du statut',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Erreur de connexion au serveur',
      };
    }
  }

  // Confirmer une commande (admin)
  Future<Map<String, dynamic>> confirmOrder(String orderId, String token) async {
    return updateOrderStatus(orderId, 'confirmed', token);
  }

  // Commencer la préparation (boutique)
  Future<Map<String, dynamic>> startPreparing(String orderId, String token) async {
    return updateOrderStatus(orderId, 'preparing', token);
  }

  // Marquer comme prête (boutique)
  Future<Map<String, dynamic>> markAsReady(String orderId, String token) async {
    return updateOrderStatus(orderId, 'ready', token);
  }

  // Marquer comme livrée (livreur/admin)
  Future<Map<String, dynamic>> markAsDelivered(String orderId, String token) async {
    return updateOrderStatus(orderId, 'delivered', token);
  }

  // Envoyer à la boutique (admin)
  Future<Map<String, dynamic>> sendToShop(String orderId, String token) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/admin/orders/$orderId/send-to-shop'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'order': data['order'],
          'message': data['message'] ?? 'Envoyée à la boutique',
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Erreur lors de l\'envoi',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Erreur de connexion',
      };
    }
  }

  // Annuler une commande
  Future<Map<String, dynamic>> cancelOrder(String orderId, String token) async {
    return updateOrderStatus(orderId, 'cancelled', token);
  }

  // Récupérer les commandes en attente (admin uniquement)
  Future<Map<String, dynamic>> getPendingOrders({String token = ''}) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/admin/orders/pending'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'orders': data['data'] ?? data,
        };
      } else {
        return {'success': false, 'orders': []};
      }
    } catch (e) {
      print('Erreur getPendingOrders: $e');
      return {'success': false, 'orders': []};
    }
  }

  // Assigner une commande à une boutique (admin uniquement)
  Future<Map<String, dynamic>> assignToShop(String orderId, int shopId, String token) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/admin/orders/$orderId/assign-shop'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'shop_id': shopId,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'order': data['order'],
          'message': data['message'] ?? 'Commande assignée',
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Erreur lors de l\'assignation',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Erreur de connexion',
      };
    }
  }

  // Récupérer les commandes d'une boutique (propriétaire boutique uniquement)
  Future<Map<String, dynamic>> getShopOrders({String token = ''}) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/my-shop-orders'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'orders': data['data'] ?? data,
        };
      } else {
        return {'success': false, 'orders': []};
      }
    } catch (e) {
      print('Erreur getShopOrders: $e');
      return {'success': false, 'orders': []};
    }
  }
}
