import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_constants.dart';

class DeliveryApiService {
  static const String baseUrl = AppConstants.apiBaseUrl;

  // Marquer la livraison comme effectuée (livreur)
  Future<Map<String, dynamic>> markDeliveryCompleted(String deliveryId, String token) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/deliveries/$deliveryId/status'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'status': 'delivered',
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': data['message'] ?? 'Livraison marquée comme effectuée',
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Erreur lors de la mise à jour',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Erreur de connexion au serveur',
      };
    }
  }

  // Récupérer l'historique des livraisons (client ou livreur)
  Future<Map<String, dynamic>> getDeliveries({
    String? status,
    String? role,
    int limit = 20,
    String? token,
  }) async {
    try {
      if (token == null || token.isEmpty) {
        return {'success': false, 'deliveries': []};
      }

      final queryParams = <String, String>{};
      queryParams['limit'] = limit.toString();
      if (status != null) queryParams['status'] = status;
      if (role != null) queryParams['role'] = role;

      final uri = Uri.parse('$baseUrl/deliveries').replace(queryParameters: queryParams);
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
          'deliveries': data['deliveries'] ?? data,
        };
      } else {
        return {'success': false, 'deliveries': []};
      }
    } catch (e) {
      print('Erreur getDeliveries: $e');
      return {'success': false, 'deliveries': []};
    }
  }

  // Récupérer une livraison spécifique
  Future<Map<String, dynamic>> getDelivery(String deliveryId, String token) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/deliveries/$deliveryId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'delivery': data['delivery'] ?? data,
        };
      } else {
        return {'success': false, 'message': 'Livraison non trouvée'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Erreur de connexion'};
    }
  }

  // Mettre à jour la position GPS du livreur
  Future<Map<String, dynamic>> updateDeliveryLocation({
    required String deliveryId,
    required double latitude,
    required double longitude,
    required String token,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/deliveries/$deliveryId/location'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'current_latitude': latitude,
          'current_longitude': longitude,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': data['message'] ?? 'Position mise à jour',
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Erreur lors de la mise à jour',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Erreur de connexion au serveur',
      };
    }
  }

  // Récupérer la position du livreur
  Future<Map<String, dynamic>> getDeliveryLocation(String deliveryId, String token) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/deliveries/$deliveryId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final delivery = data['delivery'];
        return {
          'success': true,
          'latitude': delivery['current_latitude'],
          'longitude': delivery['current_longitude'],
          'updated_at': delivery['updated_at'],
        };
      } else {
        return {
          'success': false,
          'message': 'Position non trouvée',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Erreur de connexion',
      };
    }
  }

  // Récupérer les messages d'une livraison
  Future<Map<String, dynamic>> getDeliveryMessages(int deliveryId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/chat/delivery/$deliveryId/messages'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'messages': data['messages'] ?? data,
        };
      } else {
        return {'success': false, 'messages': []};
      }
    } catch (e) {
      print('Erreur getDeliveryMessages: $e');
      return {'success': false, 'messages': []};
    }
  }

  // Envoyer un message dans le chat livraison
  Future<Map<String, dynamic>> sendDeliveryMessage(int deliveryId, String content, String token) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/chat/send'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'delivery_id': deliveryId,
          'content': content,
          'type': 'text',
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          'success': true,
          'message': data['message'] ?? data,
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
        'message': 'Erreur de connexion au serveur',
      };
    }
  }
}
