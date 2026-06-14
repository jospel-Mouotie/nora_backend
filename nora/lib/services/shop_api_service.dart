// lib/services/shop_api_service.dart
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:flutter/foundation.dart';
import '../config/app_constants.dart';

class ShopApiService {
  static const String baseUrl = AppConstants.apiBaseUrl;

  // ==========================================
  // BOUTIQUES STANDARD (Consultation publique)
  // ==========================================

  /// Récupérer toutes les boutiques (actives uniquement)
  Future<Map<String, dynamic>> getShops({
    int limit = 20,
    String? search,
    int? categoryId,
    String? city,
  }) async {
    try {
      final queryParams = <String, String>{};
      queryParams['limit'] = limit.toString();
      if (search != null) queryParams['search'] = search;
      if (categoryId != null) queryParams['category_id'] = categoryId.toString();
      if (city != null) queryParams['city'] = city;

      final uri = Uri.parse('$baseUrl/shops').replace(queryParameters: queryParams);
      final response = await http.get(
        uri,
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        List shops = data is List ? data : (data['shops'] ?? data['data'] ?? []);
        return {'success': true, 'shops': shops};
      }
      return {'success': false, 'shops': []};
    } catch (e) {
      debugPrint('❌ Erreur getShops: $e');
      return {'success': false, 'shops': []};
    }
  }

  /// Récupérer une boutique par son ID
  Future<Map<String, dynamic>> getShop(int shopId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/shops/$shopId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {'success': true, 'shop': data['shop'] ?? data};
      }
      return {'success': false, 'message': 'Boutique non trouvée'};
    } catch (e) {
      debugPrint('❌ Erreur getShop: $e');
      return {'success': false, 'message': 'Erreur de connexion'};
    }
  }

  // ==========================================
  // GESTION DES BOUTIQUES (Commerçant)
  // ==========================================

  /// Créer une boutique (version complète avec tous les champs)
  Future<Map<String, dynamic>> createShop({
    required String name,
    required String description,
    required String address,
    required String phone,
    required String email,
    String? city,
    String? postalCode,
    List<int>? categoryIds,
    required String token,
    File? photo,
    File? banner,
    // Nouveaux champs
    List<String>? deliveryCities,
    double? deliveryPrice,
    double? freeDeliveryMinAmount,
    String? deliveryType,
    double? latitude,
    double? longitude,
    Map<String, dynamic>? openingHours,
    String? facebookUrl,
    String? instagramUrl,
    String? whatsappNumber,
  }) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/shops'),
      );

      request.headers['Authorization'] = 'Bearer $token';
      request.fields['name'] = name;
      request.fields['description'] = description;
      request.fields['address'] = address;
      request.fields['phone'] = phone;
      request.fields['email'] = email;
      
      if (city != null) request.fields['city'] = city;
      if (postalCode != null) request.fields['postal_code'] = postalCode;
      
      // Catégories
      if (categoryIds != null && categoryIds.isNotEmpty) {
        for (var i = 0; i < categoryIds.length; i++) {
          request.fields['category_ids[$i]'] = categoryIds[i].toString();
        }
      }

      // Villes de livraison
      if (deliveryCities != null && deliveryCities.isNotEmpty) {
        request.fields['delivery_cities'] = jsonEncode(deliveryCities);
      }
      
      // Prix de livraison
      if (deliveryPrice != null) {
        request.fields['delivery_price'] = deliveryPrice.toString();
      }
      
      // Livraison gratuite à partir de
      if (freeDeliveryMinAmount != null) {
        request.fields['free_delivery_min_amount'] = freeDeliveryMinAmount.toString();
      }
      
      // Type de livraison
      if (deliveryType != null) {
        request.fields['delivery_type'] = deliveryType;
      }
      
      // Coordonnées GPS
      if (latitude != null) {
        request.fields['latitude'] = latitude.toString();
      }
      if (longitude != null) {
        request.fields['longitude'] = longitude.toString();
      }
      
      // Horaires d'ouverture
      if (openingHours != null && openingHours.isNotEmpty) {
        request.fields['opening_hours'] = jsonEncode(openingHours);
      }
      
      // Réseaux sociaux
      if (facebookUrl != null) request.fields['facebook_url'] = facebookUrl;
      if (instagramUrl != null) request.fields['instagram_url'] = instagramUrl;
      if (whatsappNumber != null) request.fields['whatsapp_number'] = whatsappNumber;

      // Upload du logo
      if (photo != null) {
        final mimeType = _getMimeType(photo.path);
        request.files.add(
          await http.MultipartFile.fromPath(
            'photo',
            photo.path,
            contentType: MediaType(mimeType.split('/')[0], mimeType.split('/')[1]),
          ),
        );
      }

      // Upload de la bannière
      if (banner != null) {
        final mimeType = _getMimeType(banner.path);
        request.files.add(
          await http.MultipartFile.fromPath(
            'banner',
            banner.path,
            contentType: MediaType(mimeType.split('/')[0], mimeType.split('/')[1]),
          ),
        );
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      debugPrint('📤 Create Shop - Status: ${response.statusCode}');
      debugPrint('📤 Response: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'shop': data['shop'] ?? data,
          'message': data['message'] ?? 'Boutique créée',
        };
      }
      final data = jsonDecode(response.body);
      return {
        'success': false,
        'message': data['message'] ?? 'Erreur lors de la création',
        'errors': data['errors'],
      };
    } catch (e) {
      debugPrint('❌ Erreur createShop: $e');
      return {'success': false, 'message': 'Erreur de connexion'};
    }
  }

  /// Mettre à jour une boutique (version complète avec tous les champs)
  Future<Map<String, dynamic>> updateShop({
    required int shopId,
    String? name,
    String? description,
    String? address,
    String? phone,
    String? email,
    String? city,
    String? postalCode,
    List<int>? categoryIds,
    File? photo,
    File? banner,
    required String token,
    List<String>? deliveryCities,
    double? deliveryPrice,
    double? freeDeliveryMinAmount,
    String? deliveryType,
    double? latitude,
    double? longitude,
    Map<String, dynamic>? openingHours,
    String? facebookUrl,
    String? instagramUrl,
    String? whatsappNumber,
  }) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/shops/$shopId'),
      );

      request.headers['Authorization'] = 'Bearer $token';
      request.fields['_method'] = 'PUT';

      if (name != null) request.fields['name'] = name;
      if (description != null) request.fields['description'] = description;
      if (address != null) request.fields['address'] = address;
      if (phone != null) request.fields['phone'] = phone;
      if (email != null) request.fields['email'] = email;
      if (city != null) request.fields['city'] = city;
      if (postalCode != null) request.fields['postal_code'] = postalCode;
      
      // Catégories
      if (categoryIds != null && categoryIds.isNotEmpty) {
        for (var i = 0; i < categoryIds.length; i++) {
          request.fields['category_ids[$i]'] = categoryIds[i].toString();
        }
      } else if (categoryIds != null && categoryIds.isEmpty) {
        request.fields['category_ids'] = '[]';
      }

      // Villes de livraison
      if (deliveryCities != null) {
        request.fields['delivery_cities'] = jsonEncode(deliveryCities);
      }
      
      // Prix de livraison
      if (deliveryPrice != null) {
        request.fields['delivery_price'] = deliveryPrice.toString();
      }
      
      // Livraison gratuite
      if (freeDeliveryMinAmount != null) {
        request.fields['free_delivery_min_amount'] = freeDeliveryMinAmount.toString();
      }
      
      // Type de livraison
      if (deliveryType != null) {
        request.fields['delivery_type'] = deliveryType;
      }
      
      // Coordonnées GPS
      if (latitude != null) {
        request.fields['latitude'] = latitude.toString();
      }
      if (longitude != null) {
        request.fields['longitude'] = longitude.toString();
      }
      
      // Horaires
      if (openingHours != null) {
        request.fields['opening_hours'] = jsonEncode(openingHours);
      }
      
      // Réseaux sociaux
      if (facebookUrl != null) request.fields['facebook_url'] = facebookUrl;
      if (instagramUrl != null) request.fields['instagram_url'] = instagramUrl;
      if (whatsappNumber != null) request.fields['whatsapp_number'] = whatsappNumber;

      // Upload photo
      if (photo != null) {
        final mimeType = _getMimeType(photo.path);
        request.files.add(
          await http.MultipartFile.fromPath(
            'photo',
            photo.path,
            contentType: MediaType(mimeType.split('/')[0], mimeType.split('/')[1]),
          ),
        );
      }

      // Upload bannière
      if (banner != null) {
        final mimeType = _getMimeType(banner.path);
        request.files.add(
          await http.MultipartFile.fromPath(
            'banner',
            banner.path,
            contentType: MediaType(mimeType.split('/')[0], mimeType.split('/')[1]),
          ),
        );
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      debugPrint('📤 Update Shop - Status: ${response.statusCode}');
      debugPrint('📤 Response: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'shop': data['shop'] ?? data,
          'message': data['message'] ?? 'Boutique mise à jour',
        };
      }
      final data = jsonDecode(response.body);
      return {
        'success': false,
        'message': data['message'] ?? 'Erreur lors de la mise à jour',
      };
    } catch (e) {
      debugPrint('❌ Erreur updateShop: $e');
      return {'success': false, 'message': 'Erreur de connexion'};
    }
  }

  /// Supprimer une boutique
  Future<Map<String, dynamic>> deleteShop(int shopId, String token) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/shops/$shopId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {'success': true, 'message': data['message'] ?? 'Boutique supprimée'};
      }
      return {'success': false, 'message': 'Erreur lors de la suppression'};
    } catch (e) {
      debugPrint('❌ Erreur deleteShop: $e');
      return {'success': false, 'message': 'Erreur de connexion'};
    }
  }

  /// Récupérer ma boutique (marchand connecté)
  Future<Map<String, dynamic>> getMyShop(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/mes-boutiques'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        List shops = data is List ? data : (data['shops'] ?? data['data'] ?? []);
        return {'success': true, 'shop': shops.isNotEmpty ? shops[0] : null, 'shops': shops};
      }
      return {'success': false, 'shop': null, 'shops': []};
    } catch (e) {
      debugPrint('❌ Erreur getMyShop: $e');
      return {'success': false, 'shop': null, 'shops': []};
    }
  }

  /// Récupérer toutes les boutiques du marchand connecté
  Future<Map<String, dynamic>> getMyShops(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/mes-boutiques'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        List shops = data is List ? data : (data['shops'] ?? data['data'] ?? []);
        return {'success': true, 'shops': shops};
      }
      return {'success': false, 'shops': []};
    } catch (e) {
      debugPrint('❌ Erreur getMyShops: $e');
      return {'success': false, 'shops': []};
    }
  }

  // ==========================================
  // ADMIN - VALIDATION DES BOUTIQUES
  // ==========================================

  /// Récupérer les boutiques en attente de validation (admin)
  Future<Map<String, dynamic>> getPendingShops(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/admin/shops/en-attente'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        List shops = data is List ? data : (data['shops'] ?? []);
        return {'success': true, 'shops': shops};
      }
      debugPrint('❌ getPendingShops: ${response.statusCode}');
      return {'success': false, 'shops': []};
    } catch (e) {
      debugPrint('❌ getPendingShops: $e');
      return {'success': false, 'shops': []};
    }
  }

  /// Approuver une boutique (admin)
  Future<Map<String, dynamic>> approveShop(int shopId, String token) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/admin/shops/$shopId/valider'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'message': data['message'] ?? 'Boutique approuvée',
          'shop': data['shop'],
        };
      }
      final data = jsonDecode(response.body);
      return {
        'success': false,
        'message': data['message'] ?? 'Erreur lors de l\'approbation',
      };
    } catch (e) {
      debugPrint('❌ Erreur approveShop: $e');
      return {'success': false, 'message': 'Erreur de connexion'};
    }
  }

  /// Refuser une boutique (admin)
  Future<Map<String, dynamic>> rejectShop(int shopId, String token) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/admin/shops/$shopId/refuser'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'message': data['message'] ?? 'Boutique refusée',
          'shop': data['shop'],
        };
      }
      final data = jsonDecode(response.body);
      return {
        'success': false,
        'message': data['message'] ?? 'Erreur lors du rejet',
      };
    } catch (e) {
      debugPrint('❌ Erreur rejectShop: $e');
      return {'success': false, 'message': 'Erreur de connexion'};
    }
  }

  /// Basculer la certification d'une boutique (admin)
  Future<Map<String, dynamic>> toggleShopCertification(int shopId, String token) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/admin/shops/$shopId/toggle-certification'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'message': data['message'] ?? 'Certification mise à jour',
          'shop': data['shop'],
          'is_certified': data['is_certified'] ?? false,
        };
      }
      final data = jsonDecode(response.body);
      return {
        'success': false,
        'message': data['message'] ?? 'Erreur lors de la mise à jour',
      };
    } catch (e) {
      debugPrint('❌ Erreur toggleShopCertification: $e');
      return {'success': false, 'message': 'Erreur de connexion'};
    }
  }

  // ==========================================
  // ADMIN - CERTIFICATION (Demandes)
  // ==========================================

  /// Récupérer les demandes de certification en attente (admin)
  Future<Map<String, dynamic>> getPendingCertifications(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/admin/certifications/pending'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {'success': true, 'requests': data['requests'] ?? []};
      }
      debugPrint('❌ getPendingCertifications: ${response.statusCode}');
      return {'success': false, 'requests': []};
    } catch (e) {
      debugPrint('❌ getPendingCertifications: $e');
      return {'success': false, 'requests': []};
    }
  }

  /// Valider une demande de certification (admin)
  Future<Map<String, dynamic>> approveCertification(
    int requestId,
    String token, {
    String? comment,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/admin/certifications/$requestId/validate'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'admin_comment': comment ?? ''}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'message': data['message'] ?? 'Certification approuvée',
        };
      }
      final data = jsonDecode(response.body);
      return {
        'success': false,
        'message': data['message'] ?? 'Erreur lors de la validation',
      };
    } catch (e) {
      debugPrint('❌ Erreur approveCertification: $e');
      return {'success': false, 'message': 'Erreur de connexion'};
    }
  }

  /// Rejeter une demande de certification (admin)
  Future<Map<String, dynamic>> rejectCertification(
    int requestId,
    String token, {
    String? comment,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/admin/certifications/$requestId/reject'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'admin_comment': comment ?? ''}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'message': data['message'] ?? 'Certification rejetée',
        };
      }
      final data = jsonDecode(response.body);
      return {
        'success': false,
        'message': data['message'] ?? 'Erreur lors du rejet',
      };
    } catch (e) {
      debugPrint('❌ Erreur rejectCertification: $e');
      return {'success': false, 'message': 'Erreur de connexion'};
    }
  }

  // ==========================================
  // DEMANDE DE CERTIFICATION (Commerçant)
  // ==========================================

  /// Demander la certification d'une boutique
  Future<Map<String, dynamic>> requestCertification(int shopId, String token) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/shops/$shopId/request-certification'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'message': data['message'] ?? 'Demande envoyée',
          'request': data['request'],
        };
      }
      final data = jsonDecode(response.body);
      return {
        'success': false,
        'message': data['error'] ?? data['message'] ?? 'Erreur lors de la demande',
      };
    } catch (e) {
      debugPrint('❌ Erreur requestCertification: $e');
      return {'success': false, 'message': 'Erreur de connexion'};
    }
  }

  /// Payer la certification
  Future<Map<String, dynamic>> payCertification({
    required int requestId,
    required String paymentMethod,
    required String transactionId,
    required String token,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/shops/certifications/$requestId/pay'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'payment_method': paymentMethod,
          'transaction_id': transactionId,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'message': data['message'] ?? 'Paiement enregistré',
          'request': data['request'],
        };
      }
      final data = jsonDecode(response.body);
      return {
        'success': false,
        'message': data['error'] ?? 'Erreur lors du paiement',
      };
    } catch (e) {
      debugPrint('❌ Erreur payCertification: $e');
      return {'success': false, 'message': 'Erreur de connexion'};
    }
  }

  // ==========================================
  // INTERACTIONS AVEC LES BOUTIQUES (Client)
  // ==========================================

  /// Suivre une boutique
  Future<Map<String, dynamic>> followShop(int shopId, String token) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/shops/$shopId/follow'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'message': data['message'] ?? 'Boutique suivie',
          'followers_count': data['followers_count'],
        };
      }
      return {'success': false, 'message': 'Erreur lors du follow'};
    } catch (e) {
      debugPrint('❌ Erreur followShop: $e');
      return {'success': false, 'message': 'Erreur de connexion'};
    }
  }

  /// Ne plus suivre une boutique
  Future<Map<String, dynamic>> unfollowShop(int shopId, String token) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/shops/$shopId/follow'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'message': data['message'] ?? 'Boutique non suivie',
          'followers_count': data['followers_count'],
        };
      }
      return {'success': false, 'message': 'Erreur lors du unfollow'};
    } catch (e) {
      debugPrint('❌ Erreur unfollowShop: $e');
      return {'success': false, 'message': 'Erreur de connexion'};
    }
  }

  /// Liker une boutique
  Future<Map<String, dynamic>> likeShop(int shopId, String token) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/shops/$shopId/like'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'message': data['message'] ?? 'Boutique likée',
        };
      }
      return {'success': false, 'message': 'Erreur lors du like'};
    } catch (e) {
      debugPrint('❌ Erreur likeShop: $e');
      return {'success': false, 'message': 'Erreur de connexion'};
    }
  }

  /// Retirer le like
  Future<Map<String, dynamic>> unlikeShop(int shopId, String token) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/shops/$shopId/like'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'message': data['message'] ?? 'Like retiré',
        };
      }
      return {'success': false, 'message': 'Erreur lors du unlike'};
    } catch (e) {
      debugPrint('❌ Erreur unlikeShop: $e');
      return {'success': false, 'message': 'Erreur de connexion'};
    }
  }

  /// Vérifier si l'utilisateur suit la boutique
  Future<Map<String, dynamic>> isFollowing(int shopId, String token) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/shops/$shopId/is-following'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {'success': true, 'is_following': data['is_following'] ?? false};
      }
      return {'success': false, 'is_following': false};
    } catch (e) {
      debugPrint('❌ Erreur isFollowing: $e');
      return {'success': false, 'is_following': false};
    }
  }

  /// Vérifier si l'utilisateur a liké la boutique
  Future<Map<String, dynamic>> hasLiked(int shopId, String token) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/shops/$shopId/has-liked'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {'success': true, 'has_liked': data['has_liked'] ?? false};
      }
      return {'success': false, 'has_liked': false};
    } catch (e) {
      debugPrint('❌ Erreur hasLiked: $e');
      return {'success': false, 'has_liked': false};
    }
  }

  /// Récupérer les boutiques suivies
  Future<Map<String, dynamic>> getFollowedShops(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/my-followed-shops'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {'success': true, 'shops': data['shops'] ?? []};
      }
      return {'success': false, 'shops': []};
    } catch (e) {
      debugPrint('❌ Erreur getFollowedShops: $e');
      return {'success': false, 'shops': []};
    }
  }

  /// Récupérer les abonnés d'une boutique (admin ou propriétaire)
  Future<Map<String, dynamic>> getShopFollowers(int shopId, String token) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/shops/$shopId/followers'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {'success': true, 'followers': data['followers'] ?? data};
      }
      return {'success': false, 'followers': []};
    } catch (e) {
      debugPrint('❌ Erreur getShopFollowers: $e');
      return {'success': false, 'followers': []};
    }
  }

  /// Récupérer les avis d'une boutique
  Future<Map<String, dynamic>> getShopReviews(int shopId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/shops/$shopId/reviews'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {'success': true, 'reviews': data['reviews'] ?? data['data'] ?? []};
      }
      return {'success': false, 'reviews': []};
    } catch (e) {
      debugPrint('❌ Erreur getShopReviews: $e');
      return {'success': false, 'reviews': []};
    }
  }

  /// Ajouter un avis sur une boutique
  Future<Map<String, dynamic>> addShopReview(
    int shopId,
    int rating,
    String comment,
    String token,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/shops/$shopId/reviews'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'rating': rating, 'comment': comment}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'review': data['review'] ?? data,
          'message': data['message'] ?? 'Avis ajouté',
        };
      }
      final data = jsonDecode(response.body);
      return {'success': false, 'message': data['message'] ?? 'Erreur'};
    } catch (e) {
      debugPrint('❌ Erreur addShopReview: $e');
      return {'success': false, 'message': 'Erreur de connexion'};
    }
  }

  // ==========================================
  // STATISTIQUES BOUTIQUE (Commerçant)
  // ==========================================

  /// Récupérer les statistiques de la boutique
  Future<Map<String, dynamic>> getShopStats(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/merchant/shop/stats'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {'success': true, 'stats': data['stats'] ?? data};
      }
      return {'success': false, 'stats': null};
    } catch (e) {
      debugPrint('❌ Erreur getShopStats: $e');
      return {'success': false, 'stats': null};
    }
  }

  // ==========================================
  // BOUTIQUE MB (Monnaie virtuelle)
  // ==========================================

  /// Récupérer les articles de la boutique MB
  Future<Map<String, dynamic>> getMbShopItems({
    String? category,
    String? type,
    bool? featured,
    int limit = 20,
  }) async {
    try {
      final queryParams = <String, String>{};
      queryParams['limit'] = limit.toString();
      if (category != null) queryParams['category'] = category;
      if (type != null) queryParams['type'] = type;
      if (featured != null) queryParams['featured'] = featured.toString();

      final uri = Uri.parse('$baseUrl/mb-shop-items').replace(queryParameters: queryParams);
      final response = await http.get(
        uri,
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {'success': true, 'items': data['items'] ?? data};
      }
      return {'success': false, 'items': []};
    } catch (e) {
      debugPrint('❌ Erreur getMbShopItems: $e');
      return {'success': false, 'items': []};
    }
  }

  /// Récupérer un article MB par son ID
  Future<Map<String, dynamic>> getMbShopItem(int itemId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/mb-shop-items/$itemId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {'success': true, 'item': data['item'] ?? data};
      }
      return {'success': false, 'message': 'Article non trouvé'};
    } catch (e) {
      debugPrint('❌ Erreur getMbShopItem: $e');
      return {'success': false, 'message': 'Erreur de connexion'};
    }
  }

  /// Acheter un article MB
  Future<Map<String, dynamic>> purchaseMbItem(int itemId, String token) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/mb-shop-items/$itemId/purchase'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          'success': true,
          'purchase': data['purchase'] ?? data,
          'message': data['message'] ?? 'Achat réussi',
        };
      }
      return {
        'success': false,
        'message': data['message'] ?? 'Erreur lors de l\'achat',
      };
    } catch (e) {
      debugPrint('❌ Erreur purchaseMbItem: $e');
      return {'success': false, 'message': 'Erreur de connexion'};
    }
  }

  /// Récupérer les achats MB de l'utilisateur
  Future<Map<String, dynamic>> getMbPurchases(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/mb-shop-purchases'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {'success': true, 'purchases': data['purchases'] ?? data};
      }
      return {'success': false, 'purchases': []};
    } catch (e) {
      debugPrint('❌ Erreur getMbPurchases: $e');
      return {'success': false, 'purchases': []};
    }
  }

  /// Récupérer les articles promotionnels MB
  Future<Map<String, dynamic>> getPromotionalMbItems({int limit = 10}) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/mb-shop-items/promotional?limit=$limit'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {'success': true, 'items': data['items'] ?? data};
      }
      return {'success': false, 'items': []};
    } catch (e) {
      debugPrint('❌ Erreur getPromotionalMbItems: $e');
      return {'success': false, 'items': []};
    }
  }

  /// Récupérer les articles tendances MB
  Future<Map<String, dynamic>> getTrendingMbItems({int limit = 10}) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/mb-shop-items/trending?limit=$limit'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {'success': true, 'items': data['items'] ?? data};
      }
      return {'success': false, 'items': []};
    } catch (e) {
      debugPrint('❌ Erreur getTrendingMbItems: $e');
      return {'success': false, 'items': []};
    }
  }

  /// Récupérer les boutiques MB
  Future<Map<String, dynamic>> getMbShops() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/mb-shops'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {'success': true, 'shops': data['shops'] ?? data};
      }
      return {'success': false, 'shops': []};
    } catch (e) {
      debugPrint('❌ Erreur getMbShops: $e');
      return {'success': false, 'shops': []};
    }
  }

  // ==========================================
  // UTILITAIRES
  // ==========================================

  String _getMimeType(String path) {
    final extension = path.split('.').last.toLowerCase();
    switch (extension) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'mp4':
        return 'video/mp4';
      case 'mov':
        return 'video/quicktime';
      case 'webm':
        return 'video/webm';
      default:
        return 'application/octet-stream';
    }
  }
}