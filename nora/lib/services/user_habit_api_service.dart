// lib/services/user_habit_api_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_constants.dart';

class UserHabitApiService {
  static const String baseUrl = AppConstants.apiBaseUrl;

  /// Enregistrer une action utilisateur
  Future<Map<String, dynamic>> trackAction({
    required String token,
    required String actionType, // view, search, click, purchase, like, share, bookmark
    required String entityType, // product, shop, category, video
    required String entityId,
    Map<String, dynamic>? metadata,
    Map<String, dynamic>? context,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/user-habits/track'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'action_type': actionType,
          'entity_type': entityType,
          'entity_id': entityId,
          'metadata': metadata,
          'context': context,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'message': data['message'] ?? 'Action enregistrée',
        };
      } else {
        final data = jsonDecode(response.body);
        return {
          'success': false,
          'message': data['message'] ?? 'Erreur',
        };
      }
    } catch (e) {
      print('❌ Erreur trackAction: $e');
      return {'success': false, 'message': 'Erreur de connexion'};
    }
  }

  /// Obtenir les produits recommandés (basés sur les habitudes)
  Future<Map<String, dynamic>> getRecommendedProductsByHabits({
    required String token,
    int limit = 10,
    int days = 30,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/user-habits/recommended-products?limit=$limit&days=$days'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        List products = [];
        
        if (data['recommended_products'] is List) {
          products = data['recommended_products'];
        }
        
        return {
          'success': true,
          'products': products,
          'recommendation_type': data['recommendation_type'] ?? 'habits',
        };
      } else {
        return {'success': false, 'products': []};
      }
    } catch (e) {
      print('❌ Erreur getRecommendedProductsByHabits: $e');
      return {'success': false, 'products': []};
    }
  }

  /// Obtenir l'historique des vues
  Future<Map<String, dynamic>> getViewHistory({
    required String token,
    int limit = 50,
    String? entityType,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/user-habits/view-history?limit=$limit')
          .replace(queryParameters: entityType != null ? {'entity_type': entityType} : {});
      
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'view_history': data['view_history'] ?? [],
        };
      } else {
        return {'success': false, 'view_history': []};
      }
    } catch (e) {
      print('❌ Erreur getViewHistory: $e');
      return {'success': false, 'view_history': []};
    }
  }

  /// Obtenir les statistiques des habitudes
  Future<Map<String, dynamic>> getHabitsStats(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/user-habits/stats'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'stats': data['stats'] ?? {},
        };
      } else {
        return {'success': false, 'stats': {}};
      }
    } catch (e) {
      print('❌ Erreur getHabitsStats: $e');
      return {'success': false, 'stats': {}};
    }
  }

  /// Effacer l'historique
  Future<Map<String, dynamic>> clearHistory({
    required String token,
    int? days,
    String? actionType,
    String? entityType,
  }) async {
    try {
      final body = <String, dynamic>{};
      if (days != null) body['days'] = days;
      if (actionType != null) body['action_type'] = actionType;
      if (entityType != null) body['entity_type'] = entityType;

      final response = await http.post(
        Uri.parse('$baseUrl/user-habits/clear'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'message': data['message'] ?? 'Historique effacé',
          'deleted_count': data['deleted_count'] ?? 0,
        };
      } else {
        return {'success': false, 'message': 'Erreur'};
      }
    } catch (e) {
      print('❌ Erreur clearHistory: $e');
      return {'success': false, 'message': 'Erreur de connexion'};
    }
  }
}