import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_constants.dart';

/// Service dédié aux fonctionnalités d'administration globale
class AdminApiService {
  static const String baseUrl = AppConstants.apiBaseUrl;

  /// Récupérer les statistiques globales du dashboard admin
  Future<Map<String, dynamic>> getAdminStats(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/dashboard'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // Le backend retourne general_stats, order_stats, etc.
        final general = data['general_stats'] ?? {};
        final orders = data['order_stats'] ?? {};
        final shops = data['shop_stats'] ?? {};

        return {
          'success': true,
          'stats': {
            'total_users': general['total_users'] ?? 0,
            'active_users': general['active_users'] ?? 0,
            'new_users_period': general['new_users_period'] ?? 0,
            'total_shops': general['total_shops'] ?? 0,
            'active_shops': general['active_shops'] ?? 0,
            'certified_shops': data['certified_shops'] ?? 0,
            'pending_shops': general['pending_shops'] ?? 0,
            'total_products': general['total_products'] ?? 0,
            'total_orders': general['total_orders'] ?? 0,
            'pending_orders': orders['pending_orders'] ?? general['pending_orders'] ?? 0,
            'completed_orders': orders['completed_orders'] ?? 0,
            'total_revenue': orders['total_revenue'] ?? 0,
            'revenue_period': orders['revenue_period'] ?? 0,
            'total_videos': data['video_stats']?['total_videos'] ?? 0,
          },
          'recent_activity': data['recent_activity'] ?? {},
          'growth_charts': data['growth_charts'] ?? {},
        };
      } else {
        return {'success': false, 'stats': null};
      }
    } catch (e) {
      print('❌ Erreur getAdminStats: $e');
      return {'success': false, 'stats': null};
    }
  }

  /// Récupérer les stats spécifiques boutiques (endpoint dédié)
  Future<Map<String, dynamic>> getShopStats(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/dashboard/shops'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'stats': data['shop_stats'] ?? data,
        };
      }
      return {'success': false, 'stats': null};
    } catch (e) {
      print('❌ Erreur getShopStats: $e');
      return {'success': false, 'stats': null};
    }
  }

  /// Récupérer les utilisateurs (admin)
  Future<Map<String, dynamic>> getUsers(String token, {int page = 1, String? search, String? role}) async {
    try {
      final params = <String, String>{'page': page.toString()};
      if (search != null && search.isNotEmpty) params['search'] = search;
      if (role != null && role.isNotEmpty) params['role'] = role;

      final uri = Uri.parse('$baseUrl/admin/users').replace(queryParameters: params);
      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'users': data['users'] ?? data['data'] ?? [],
          'total': data['total'] ?? 0,
        };
      }
      return {'success': false, 'users': []};
    } catch (e) {
      print('❌ Erreur getUsers: $e');
      return {'success': false, 'users': []};
    }
  }

  /// Mettre à jour le statut d'un utilisateur
  Future<Map<String, dynamic>> updateUserStatus(int userId, bool isActive, String token) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/admin/users/$userId/status'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
        body: jsonEncode({'is_active': isActive}),
      );

      if (response.statusCode == 200) {
        return {'success': true};
      }
      return {'success': false, 'message': 'Erreur lors de la mise à jour'};
    } catch (e) {
      return {'success': false, 'message': 'Erreur de connexion'};
    }
  }

  /// Récupérer toutes les boutiques (admin)
  Future<Map<String, dynamic>> getAllShops(String token, {String? status, int page = 1}) async {
    try {
      final params = <String, String>{'page': page.toString()};
      if (status != null) params['status'] = status;

      final uri = Uri.parse('$baseUrl/shops').replace(queryParameters: params);
      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final shops = data is List ? data : (data['shops'] ?? data['data'] ?? []);
        return {'success': true, 'shops': shops};
      }
      return {'success': false, 'shops': []};
    } catch (e) {
      print('❌ Erreur getAllShops: $e');
      return {'success': false, 'shops': []};
    }
  }

  /// Récupérer toutes les commandes (admin)
  Future<Map<String, dynamic>> getAllOrders(String token, {String? status, int page = 1}) async {
    try {
      final params = <String, String>{'page': page.toString()};
      if (status != null) params['status'] = status;

      final uri = Uri.parse('$baseUrl/orders').replace(queryParameters: params);
      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'orders': data['orders'] ?? data['data'] ?? [],
          'total': data['total'] ?? 0,
        };
      }
      return {'success': false, 'orders': []};
    } catch (e) {
      print('❌ Erreur getAllOrders: $e');
      return {'success': false, 'orders': []};
    }
  }

  /// Certifier / décertifier une boutique (admin)
  Future<Map<String, dynamic>> toggleShopCertification(int shopId, String token) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/admin/shops/$shopId/toggle-certification'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'message': data['message'] ?? 'Certification mise à jour',
          'is_certified': data['is_certified'] ?? false,
        };
      }
      return {'success': false, 'message': 'Erreur lors de la mise à jour'};
    } catch (e) {
      return {'success': false, 'message': 'Erreur de connexion'};
    }
  }

  /// Déconnecter l'utilisateur (invalide le token côté serveur)
  Future<Map<String, dynamic>> logout(String token) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/logout'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return {'success': true, 'message': 'Déconnecté avec succès'};
      }
      return {'success': false, 'message': 'Erreur lors de la déconnexion'};
    } catch (e) {
      print('❌ Erreur logout: $e');
      return {'success': false, 'message': 'Erreur de connexion'};
    }
  }
}
