import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_constants.dart';

class CartApiService {
  static const String baseUrl = AppConstants.apiBaseUrl;

  // Voir le panier
  Future<Map<String, dynamic>> getCart(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/cart'),
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
          'data': data['data'],
          'items': data['data']?['items'] ?? [],
          'total_amount': data['data']?['total_amount'] ?? 0,
          'item_count': data['data']?['item_count'] ?? 0,
        };
      }
      return {'success': false};
    } catch (e) {
      return {'success': false};
    }
  }
// Ajouter au panier - VERSION QUI FONCTIONNE À COUP SÛR
Future<Map<String, dynamic>> addToCart({
  required int productId,
  required int quantity,
  int? productVariantId,
  required String token,
}) async {
  try {
    final Map<String, dynamic> body = {
      'quantity': quantity.toString(),
    };
    if (productVariantId != null) {
      body['variant_id'] = productVariantId.toString();
    } else {
      body['product_id'] = productId.toString();
    }

    print('🛒 [SERVICE] Body: $body');

    final response = await http.post(
      Uri.parse('$baseUrl/cart/add'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
      body: jsonEncode(body),
    );

    print('🛒 [SERVICE] Status Code: ${response.statusCode}');
    print('🛒 [SERVICE] Response: ${response.body}');

    final data = jsonDecode(response.body);

    if (response.statusCode == 200 && data['success'] == true) {
      return {
        'success': true,
        'message': data['message'],
        'cart_id': data['cart_id'],
        'total_amount': data['total_amount'],
        'item_count': data['item_count'],
      };
    }

    return {
      'success': false,
      'message': data['message'] ?? 'Erreur lors de l\'ajout',
    };
  } catch (e) {
    print('🛒 [SERVICE] Exception: $e');
    return {'success': false, 'message': 'Erreur de connexion'};
  }
}

  // Mettre à jour la quantité
  Future<Map<String, dynamic>> updateCartItem(int itemId, int quantity, String token) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/cart/items/$itemId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
        body: jsonEncode({'quantity': quantity}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return {'success': true, 'message': data['message']};
      }
      return {'success': false, 'message': 'Erreur lors de la mise à jour'};
    } catch (e) {
      return {'success': false, 'message': 'Erreur de connexion'};
    }
  }

  // Supprimer du panier
  Future<Map<String, dynamic>> removeCartItem(int itemId, String token) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/cart/items/$itemId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return {'success': true, 'message': data['message']};
      }
      return {'success': false, 'message': 'Erreur lors de la suppression'};
    } catch (e) {
      return {'success': false, 'message': 'Erreur de connexion'};
    }
  }

  // Vider le panier
  Future<Map<String, dynamic>> clearCart(String token) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/cart'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return {'success': true, 'message': data['message']};
      }
      return {'success': false, 'message': 'Erreur lors du vidage'};
    } catch (e) {
      return {'success': false, 'message': 'Erreur de connexion'};
    }
  }

  // Appliquer un code promotionnel
  Future<Map<String, dynamic>> applyPromotion(String code, String token) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/cart/apply-promotion'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
        body: jsonEncode({'code': code}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return {
          'success': true,
          'discount': data['discount'] ?? 0,
          'discount_type': data['discount_type'] ?? 'fixed',
          'message': data['message'] ?? 'Code promo appliqué',
        };
      }
      return {'success': false, 'message': data['message'] ?? 'Code promo invalide'};
    } catch (e) {
      return {'success': false, 'message': 'Erreur de connexion'};
    }
  }
}
