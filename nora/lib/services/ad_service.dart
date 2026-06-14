import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_constants.dart';

class AdService {
  static const String baseUrl = AppConstants.apiBaseUrl;

  // Récupérer les publicités actives
  Future<Map<String, dynamic>> getActiveAds({String? position, String? type}) async {
    try {
      final queryParams = <String, String>{};
      if (position != null) queryParams['position'] = position;
      if (type != null) queryParams['type'] = type;

      final uri = Uri.parse('$baseUrl/ads/active').replace(queryParameters: queryParams);
      final response = await http.get(
        uri,
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        // Gérer différents formats de réponse
        List ads = [];
        if (data['active_ads'] is List) {
          ads = data['active_ads'];
        } else if (data['ads'] is List) {
          ads = data['ads'];
        } else if (data['data'] is List) {
          ads = data['data'];
        } else if (data is List) {
          ads = data;
        }
        
        return {
          'success': true,
          'ads': ads,
        };
      } else {
        return {'success': false, 'ads': []};
      }
    } catch (e) {
      print('Erreur getActiveAds: $e');
      return {'success': false, 'ads': []};
    }
  }

  // Récupérer toutes les publicités (pour commerçant)
  Future<Map<String, dynamic>> getMyAds(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/ads'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'ads': data['ads'] ?? data,
        };
      } else {
        return {'success': false, 'ads': []};
      }
    } catch (e) {
      print('Erreur getMyAds: $e');
      return {'success': false, 'ads': []};
    }
  }

  // Créer une publicité
  Future<Map<String, dynamic>> createAd({
    required String title,
    required String description,
    required String type,
    required String position,
    required String linkUrl,
    required double budget,
    double? costPerClick,
    double? costPerImpression,
    int? maxImpressions,
    int? maxClicks,
    DateTime? startsAt,
    DateTime? endsAt,
    required String token,
    required List<int> imageBytes,
  }) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/ads'),
      );

      request.headers['Authorization'] = 'Bearer $token';
      request.fields['title'] = title;
      request.fields['description'] = description;
      request.fields['type'] = type;
      request.fields['position'] = position;
      request.fields['link_url'] = linkUrl;
      request.fields['budget'] = budget.toString();
      if (costPerClick != null) request.fields['cost_per_click'] = costPerClick.toString();
      if (costPerImpression != null) request.fields['cost_per_impression'] = costPerImpression.toString();
      if (maxImpressions != null) request.fields['max_impressions'] = maxImpressions.toString();
      if (maxClicks != null) request.fields['max_clicks'] = maxClicks.toString();
      if (startsAt != null) request.fields['starts_at'] = startsAt.toIso8601String();
      if (endsAt != null) request.fields['ends_at'] = endsAt.toIso8601String();

      request.files.add(http.MultipartFile.fromBytes(
        'image',
        imageBytes,
        filename: 'ad_image.jpg',
      ));

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'ad': data['ad'] ?? data,
        };
      } else {
        final data = jsonDecode(response.body);
        return {
          'success': false,
          'message': data['message'] ?? 'Erreur lors de la création',
        };
      }
    } catch (e) {
      print('Erreur createAd: $e');
      return {
        'success': false,
        'message': 'Erreur de connexion',
      };
    }
  }

  // Démarrer une publicité
  Future<Map<String, dynamic>> startAd(int adId, String token) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/ads/$adId/start'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return {'success': true};
      } else {
        final data = jsonDecode(response.body);
        return {
          'success': false,
          'message': data['message'] ?? 'Erreur lors du démarrage',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Erreur de connexion'};
    }
  }

  // Mettre en pause une publicité
  Future<Map<String, dynamic>> pauseAd(int adId, String token) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/ads/$adId/pause'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return {'success': true};
      } else {
        final data = jsonDecode(response.body);
        return {
          'success': false,
          'message': data['message'] ?? 'Erreur lors de la mise en pause',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Erreur de connexion'};
    }
  }

  // Supprimer une publicité
  Future<Map<String, dynamic>> deleteAd(int adId, String token) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/ads/$adId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return {'success': true};
      } else {
        final data = jsonDecode(response.body);
        return {
          'success': false,
          'message': data['message'] ?? 'Erreur lors de la suppression',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Erreur de connexion'};
    }
  }

  // Enregistrer une impression
  Future<Map<String, dynamic>> recordImpression(int adId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/ads/$adId/impression'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        return {'success': true};
      } else {
        return {'success': false};
      }
    } catch (e) {
      return {'success': false};
    }
  }

  // Enregistrer un clic
  Future<Map<String, dynamic>> recordClick(int adId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/ads/$adId/click'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        return {'success': true};
      } else {
        return {'success': false};
      }
    } catch (e) {
      return {'success': false};
    }
  }

  // Récupérer les statistiques
  Future<Map<String, dynamic>> getAdStats(int adId, String token) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/ads/$adId/stats'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'stats': data['stats'] ?? data,
        };
      } else {
        return {'success': false, 'stats': null};
      }
    } catch (e) {
      print('Erreur getAdStats: $e');
      return {'success': false, 'stats': null};
    }
  }

  // Récupérer les publicités d'une boutique spécifique
  Future<Map<String, dynamic>> getShopAds(int shopId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/ads/shop/$shopId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        List ads = [];
        if (data['ads'] is List) {
          ads = data['ads'];
        } else if (data['data'] is List) {
          ads = data['data'];
        } else if (data is List) {
          ads = data;
        }
        
        return {
          'success': true,
          'ads': ads,
        };
      } else {
        return {'success': false, 'ads': []};
      }
    } catch (e) {
      print('Erreur getShopAds: $e');
      return {'success': false, 'ads': []};
    }
  }

  // Récupérer les promotions actives
  Future<Map<String, dynamic>> getPromotions() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/promotions'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'promotions': data['promotions'] ?? data['data'] ?? data,
        };
      } else {
        return {'success': false, 'promotions': []};
      }
    } catch (e) {
      print('Erreur getPromotions: $e');
      return {'success': false, 'promotions': []};
    }
  }
}