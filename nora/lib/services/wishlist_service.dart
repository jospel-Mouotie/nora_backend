import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_constants.dart';

class WishlistService {
  static final WishlistService _instance = WishlistService._internal();
  factory WishlistService() => _instance;
  WishlistService._internal();

  final String _baseUrl = AppConstants.apiBaseUrl;

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<Map<String, dynamic>> getWishlist() async {
    final token = await _getToken();
    if (token == null) {
      return {'success': false, 'message': 'Non authentifié'};
    }

    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/wishlist'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {'success': true, 'wishlist': data['wishlist'] ?? []};
      } else {
        return {'success': false, 'message': 'Erreur lors du chargement'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Erreur de connexion'};
    }
  }

  Future<Map<String, dynamic>> addToWishlist(int productId) async {
    final token = await _getToken();
    if (token == null) {
      return {'success': false, 'message': 'Non authentifié'};
    }

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/wishlist/add'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'product_id': productId}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return {'success': true, 'message': data['message'] ?? 'Ajouté aux favoris'};
      } else {
        return {'success': false, 'message': 'Erreur lors de l\'ajout'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Erreur de connexion'};
    }
  }

  Future<Map<String, dynamic>> removeFromWishlist(int productId) async {
    final token = await _getToken();
    if (token == null) {
      return {'success': false, 'message': 'Non authentifié'};
    }

    try {
      final response = await http.delete(
        Uri.parse('$_baseUrl/wishlist/remove/$productId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {'success': true, 'message': data['message'] ?? 'Retiré des favoris'};
      } else {
        return {'success': false, 'message': 'Erreur lors de la suppression'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Erreur de connexion'};
    }
  }

  Future<bool> isInWishlist(int productId) async {
    final result = await getWishlist();
    if (!result['success']) return false;

    final wishlist = result['wishlist'] as List;
    return wishlist.any((item) => item['product_id'] == productId);
  }
}
