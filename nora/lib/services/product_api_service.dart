import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../config/app_constants.dart';

class ProductApiService {
  static const String baseUrl = AppConstants.apiBaseUrl;

  // ========== PRODUITS PUBLICS ==========

  /// Récupérer tous les produits avec filtres
  Future<Map<String, dynamic>> getProducts({
    int limit = 20,
    int page = 1,
    String? search,
    int? categoryId,
    int? shopId,
    double? minPrice,
    double? maxPrice,
    String? sort,
    bool? inPromotion,
  }) async {
    try {
      final queryParams = <String, String>{};
      queryParams['limit'] = limit.toString();
      queryParams['page'] = page.toString();
      if (search != null && search.isNotEmpty) queryParams['search'] = search;
      if (categoryId != null) queryParams['category_id'] = categoryId.toString();
      if (shopId != null) queryParams['shop_id'] = shopId.toString();
      if (minPrice != null) queryParams['min_price'] = minPrice.toString();
      if (maxPrice != null) queryParams['max_price'] = maxPrice.toString();
      if (sort != null && sort.isNotEmpty) queryParams['sort'] = sort;
      if (inPromotion != null) queryParams['in_promotion'] = inPromotion.toString();

      final uri = Uri.parse('$baseUrl/products').replace(queryParameters: queryParams);
      final response = await http.get(
        uri,
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        List products = _extractProducts(data);
        _parseProductImages(products);

        return {
          'success': true,
          'products': products,
          'total': data['total'] ?? products.length,
          'current_page': data['current_page'] ?? 1,
          'last_page': data['last_page'] ?? 1,
        };
      } else {
        return {'success': false, 'products': [], 'message': 'Erreur de chargement'};
      }
    } catch (e) {
      print('❌ Erreur getProducts: $e');
      return {'success': false, 'products': [], 'message': 'Erreur de connexion'};
    }
  }

  /// Récupérer un produit par son ID
  Future<Map<String, dynamic>> getProduct(int productId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/products/$productId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final product = data['product'] ?? data;

        _parseProductImages([product]);

        // Parser les variantes avec leur stock
        if (product['variants'] != null && product['variants'] is List) {
          for (var variant in product['variants']) {
            if (variant['stock'] != null) {
              variant['available_quantity'] = (variant['stock']['quantity'] ?? 0) - (variant['stock']['reserved_quantity'] ?? 0);
            }
          }
        }

        return {
          'success': true,
          'product': product,
        };
      } else {
        final data = jsonDecode(response.body);
        return {
          'success': false,
          'message': data['message'] ?? 'Produit non trouvé'
        };
      }
    } catch (e) {
      print('❌ Erreur getProduct: $e');
      return {'success': false, 'message': 'Erreur de connexion'};
    }
  }

  /// Récupérer les produits en promotion
  Future<Map<String, dynamic>> getPromotions({int limit = 15}) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/products/promotions?limit=$limit'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        List products = _extractProducts(data);
        _parseProductImages(products);

        return {
          'success': true,
          'products': products,
        };
      } else {
        return {'success': false, 'products': []};
      }
    } catch (e) {
      print('❌ Erreur getPromotions: $e');
      return {'success': false, 'products': []};
    }
  }

  /// Récupérer les produits recommandés (version améliorée)
  Future<Map<String, dynamic>> getRecommendedProducts({
    int limit = 20,
    String? token,
  }) async {
    try {
      // Si token fourni, essayer d'abord les recommandations personnalisées
      if (token != null && token.isNotEmpty) {
        try {
          final habitResponse = await http.get(
            Uri.parse('$baseUrl/user-habits/recommended-products?limit=$limit'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
          );

          if (habitResponse.statusCode == 200) {
            final data = jsonDecode(habitResponse.body);
            if (data['recommended_products'] != null && 
                (data['recommended_products'] as List).isNotEmpty) {
              List products = data['recommended_products'];
              _parseProductImages(products);
              return {
                'success': true,
                'products': products,
                'type': 'habits'
              };
            }
          }
        } catch (e) {
          print('⚠️ Erreur recommandations habitudes: $e');
        }
      }

      // Fallback: recommandations standard
      final response = await http.get(
        Uri.parse('$baseUrl/products/recommended?limit=$limit'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        List products = [];

        if (data['recommended_products'] is List) {
          products = data['recommended_products'];
        } else if (data['products'] is List) {
          products = data['products'];
        }

        _parseProductImages(products);

        return {
          'success': true,
          'products': products,
          'type': 'popular'
        };
      } else {
        return {'success': false, 'products': []};
      }
    } catch (e) {
      print('❌ Erreur getRecommendedProducts: $e');
      return {'success': false, 'products': []};
    }
  }

  /// Récupérer les produits similaires
  Future<Map<String, dynamic>> getSimilarProducts(int productId, {int limit = 10}) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/products/$productId/similar?limit=$limit'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        List products = [];

        if (data['similar_products'] is List) {
          products = data['similar_products'];
        } else if (data['products'] is List) {
          products = data['products'];
        }

        _parseProductImages(products);

        return {
          'success': true,
          'products': products,
        };
      } else {
        return {'success': false, 'products': []};
      }
    } catch (e) {
      print('❌ Erreur getSimilarProducts: $e');
      return {'success': false, 'products': []};
    }
  }

  /// Récupérer les produits par boutique
  Future<Map<String, dynamic>> getProductsByShop(int shopId, {int limit = 15}) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/products/by-shop/$shopId?limit=$limit'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        List products = _extractProducts(data);
        _parseProductImages(products);

        return {
          'success': true,
          'products': products,
        };
      } else {
        return {'success': false, 'products': []};
      }
    } catch (e) {
      print('❌ Erreur getProductsByShop: $e');
      return {'success': false, 'products': []};
    }
  }

  /// Récupérer les produits par catégorie
  Future<Map<String, dynamic>> getProductsByCategory(int categoryId, {int limit = 15}) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/products/by-category/$categoryId?limit=$limit'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        List products = _extractProducts(data);
        _parseProductImages(products);

        return {
          'success': true,
          'products': products,
        };
      } else {
        return {'success': false, 'products': []};
      }
    } catch (e) {
      print('❌ Erreur getProductsByCategory: $e');
      return {'success': false, 'products': []};
    }
  }

  /// Récupérer les produits tendance par intérêts
  Future<Map<String, dynamic>> getTrendingByInterests({
    int limit = 15,
    String? token,
  }) async {
    try {
      final headers = <String, String>{'Content-Type': 'application/json'};
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }

      final response = await http.get(
        Uri.parse('$baseUrl/products/trending-by-interests?limit=$limit'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        List products = [];

        if (data['trending_products'] is List) {
          products = data['trending_products'];
        } else if (data['products'] is List) {
          products = data['products'];
        }

        _parseProductImages(products);

        return {
          'success': true,
          'products': products,
        };
      } else {
        return {'success': false, 'products': []};
      }
    } catch (e) {
      print('❌ Erreur getTrendingByInterests: $e');
      return {'success': false, 'products': []};
    }
  }

  // ========== GESTION DES PRODUITS (AUTHENTIFIÉ) ==========

  /// Créer un produit
  Future<Map<String, dynamic>> createProduct({
    required String name,
    required double price,
    required String description,
    required int categoryId,
    int stock = 0,
    double? comparePrice,
    required List<File> images,
    List<Map<String, dynamic>>? variants,
    required String token,
  }) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/products'),
      );

      request.headers['Authorization'] = 'Bearer $token';
      request.fields['name'] = name;
      request.fields['price'] = price.toString();
      request.fields['description'] = description;
      request.fields['category_id'] = categoryId.toString();

      // Générer un SKU unique
      final sku = 'PRD-${DateTime.now().millisecondsSinceEpoch}';
      request.fields['sku'] = sku;

      if (comparePrice != null) {
        request.fields['compare_price'] = comparePrice.toString();
      }

      // Gestion des variantes
      if (variants != null && variants.isNotEmpty) {
        for (var i = 0; i < variants.length; i++) {
          final v = variants[i];
          if (v['size'] != null && v['size'].toString().isNotEmpty) {
            request.fields['variants[$i][size]'] = v['size'].toString();
          }
          if (v['color'] != null && v['color'].toString().isNotEmpty) {
            request.fields['variants[$i][color]'] = v['color'].toString();
          }
          if (v['material'] != null && v['material'].toString().isNotEmpty) {
            request.fields['variants[$i][material]'] = v['material'].toString();
          }
          request.fields['variants[$i][stock]'] = (v['stock'] ?? 0).toString();
          request.fields['variants[$i][sku]'] = v['sku'] ?? 'VAR-${DateTime.now().millisecondsSinceEpoch}-$i';
          request.fields['variants[$i][price_adjustment]'] = (v['price_adjustment'] ?? 0).toString();
        }
      } else {
        // Variante par défaut si aucune n'est fournie
        request.fields['variants[0][stock]'] = stock.toString();
        request.fields['variants[0][sku]'] = '${sku}-DEFAULT';
        request.fields['variants[0][price_adjustment]'] = '0';
      }

      // Ajout des images
      for (var i = 0; i < images.length; i++) {
        request.files.add(
          await http.MultipartFile.fromPath('images[$i]', images[i].path),
        );
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      print('📤 Create Product - Status: ${response.statusCode}');
      print('📤 Response: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'product': data['product'] ?? data,
          'message': data['message'] ?? 'Produit créé avec succès',
        };
      } else {
        final data = jsonDecode(response.body);
        return {
          'success': false,
          'message': data['message'] ?? 'Erreur lors de la création',
          'errors': data['errors'],
        };
      }
    } catch (e) {
      print('❌ Erreur createProduct: $e');
      return {
        'success': false,
        'message': 'Erreur de connexion: $e',
      };
    }
  }

  /// Mettre à jour un produit
  Future<Map<String, dynamic>> updateProduct({
    required int productId,
    required String name,
    required double price,
    required String description,
    required int categoryId,
    int? stock,
    double? comparePrice,
    bool? isActive,
    List<Map<String, dynamic>>? variants,
    required String token,
  }) async {
    try {
      final Map<String, dynamic> body = {
        'name': name,
        'price': price,
        'description': description,
        'category_id': categoryId,
      };

      if (stock != null) body['stock'] = stock;
      if (comparePrice != null) body['compare_price'] = comparePrice;
      if (isActive != null) body['is_active'] = isActive;
      if (variants != null) body['variants'] = variants;

      final response = await http.put(
        Uri.parse('$baseUrl/products/$productId'),
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
          'product': data['product'] ?? data,
          'message': data['message'] ?? 'Produit mis à jour',
        };
      } else {
        final data = jsonDecode(response.body);
        return {
          'success': false,
          'message': data['message'] ?? 'Erreur lors de la mise à jour',
        };
      }
    } catch (e) {
      print('❌ Erreur updateProduct: $e');
      return {
        'success': false,
        'message': 'Erreur de connexion',
      };
    }
  }

  /// Supprimer un produit
  Future<Map<String, dynamic>> deleteProduct(int productId, String token) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/products/$productId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'message': data['message'] ?? 'Produit supprimé',
        };
      } else {
        final data = jsonDecode(response.body);
        return {
          'success': false,
          'message': data['message'] ?? 'Erreur lors de la suppression',
        };
      }
    } catch (e) {
      print('❌ Erreur deleteProduct: $e');
      return {
        'success': false,
        'message': 'Erreur de connexion',
      };
    }
  }

  /// Récupérer mes produits (boutique du vendeur)
  Future<Map<String, dynamic>> getMyProducts(String token, {int page = 1, int limit = 15}) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/my-products?page=$page&limit=$limit'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('📤 getMyProducts - Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        List products = [];
        if (data['products'] != null) {
          if (data['products'] is List) {
            products = data['products'];
          } else if (data['products']['data'] is List) {
            products = data['products']['data'];
          }
        } else if (data['data'] is List) {
          products = data['data'];
        }

        _parseProductImages(products);

        return {
          'success': true,
          'products': products,
          'total': data['products']['total'] ?? data['total'] ?? products.length,
          'current_page': data['products']['current_page'] ?? data['current_page'] ?? page,
          'last_page': data['products']['last_page'] ?? data['last_page'] ?? 1,
        };
      } else {
        final data = jsonDecode(response.body);
        return {
          'success': false,
          'products': [],
          'message': data['message'] ?? 'Erreur chargement produits',
        };
      }
    } catch (e) {
      print('❌ Erreur getMyProducts: $e');
      return {
        'success': false,
        'products': [],
        'message': 'Erreur de connexion',
      };
    }
  }

  // ========== GESTION DES VARIANTES ==========

  /// Récupérer les variantes d'un produit
  Future<Map<String, dynamic>> getProductVariants(int productId, String token) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/products/$productId/variants'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        List variants = [];

        if (data['variants'] is List) {
          variants = data['variants'];
        } else if (data is List) {
          variants = data;
        }

        return {
          'success': true,
          'variants': variants,
        };
      } else {
        return {'success': false, 'variants': []};
      }
    } catch (e) {
      print('❌ Erreur getProductVariants: $e');
      return {'success': false, 'variants': []};
    }
  }

  /// Ajouter une variante à un produit
  Future<Map<String, dynamic>> addProductVariant({
    required int productId,
    required String sku,
    required int stock,
    String? size,
    String? color,
    String? material,
    double priceAdjustment = 0,
    required String token,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/products/$productId/variants'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'sku': sku,
          'stock': stock,
          'size': size,
          'color': color,
          'material': material,
          'price_adjustment': priceAdjustment,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'variant': data['variant'] ?? data,
          'message': data['message'] ?? 'Variante ajoutée',
        };
      } else {
        final data = jsonDecode(response.body);
        return {
          'success': false,
          'message': data['message'] ?? 'Erreur lors de l\'ajout',
        };
      }
    } catch (e) {
      print('❌ Erreur addProductVariant: $e');
      return {
        'success': false,
        'message': 'Erreur de connexion',
      };
    }
  }

  // ========== GESTION DES PROMOTIONS ==========

  /// Activer une promotion sur un produit
  Future<Map<String, dynamic>> activatePromotion({
    required int productId,
    required double promotionPrice,
    required DateTime startDate,
    required DateTime endDate,
    required String token,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/products/$productId/activate-promotion'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'promotion_price': promotionPrice,
          'promotion_start': startDate.toIso8601String(),
          'promotion_end': endDate.toIso8601String(),
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'product': data['product'],
          'message': data['message'] ?? 'Promotion activée',
        };
      } else {
        final data = jsonDecode(response.body);
        return {
          'success': false,
          'message': data['message'] ?? 'Erreur lors de l\'activation',
        };
      }
    } catch (e) {
      print('❌ Erreur activatePromotion: $e');
      return {
        'success': false,
        'message': 'Erreur de connexion',
      };
    }
  }

  /// Désactiver une promotion sur un produit
  Future<Map<String, dynamic>> deactivatePromotion(int productId, String token) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/products/$productId/deactivate-promotion'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'product': data['product'],
          'message': data['message'] ?? 'Promotion désactivée',
        };
      } else {
        final data = jsonDecode(response.body);
        return {
          'success': false,
          'message': data['message'] ?? 'Erreur lors de la désactivation',
        };
      }
    } catch (e) {
      print('❌ Erreur deactivatePromotion: $e');
      return {
        'success': false,
        'message': 'Erreur de connexion',
      };
    }
  }

  // ========== AVIS ET NOTES ==========

  /// Récupérer les avis d'un produit
  Future<Map<String, dynamic>> getProductReviews(int productId, {int page = 1, int limit = 10}) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/reviews?product_id=$productId&page=$page&limit=$limit'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'reviews': data['reviews'] ?? data['data'] ?? [],
          'average_rating': data['average_rating'],
          'total_reviews': data['total'] ?? 0,
        };
      } else {
        return {'success': false, 'reviews': []};
      }
    } catch (e) {
      print('❌ Erreur getProductReviews: $e');
      return {'success': false, 'reviews': []};
    }
  }

  /// Ajouter un avis sur un produit
  Future<Map<String, dynamic>> addProductReview({
    required int productId,
    required int rating,
    required String comment,
    required String token,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/reviews'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'product_id': productId,
          'rating': rating,
          'comment': comment,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          'success': true,
          'review': data['review'] ?? data,
          'message': data['message'] ?? 'Avis ajouté avec succès',
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Erreur lors de l\'ajout de l\'avis',
        };
      }
    } catch (e) {
      print('❌ Erreur addProductReview: $e');
      return {
        'success': false,
        'message': 'Erreur de connexion au serveur',
      };
    }
  }

  // ========== MÉTHODES UTILITAIRES PRIVÉES ==========

  /// Extraire la liste des produits depuis la réponse API
  List _extractProducts(dynamic data) {
    List products = [];

    if (data['products'] is List) {
      products = data['products'];
    } else if (data['data'] is List) {
      products = data['data'];
    } else if (data is List) {
      products = data;
    } else if (data['products'] != null && data['products']['data'] is List) {
      products = data['products']['data'];
    }

    return products;
  }

  /// Parser les images des produits (string JSON -> List<String>)
  void _parseProductImages(List products) {
    for (var product in products) {
      // Parser les images
      if (product['images'] is String && (product['images'] as String).isNotEmpty) {
        try {
          final imagesString = product['images'] as String;
          List<String> imageUrls = [];

          if (imagesString.startsWith('[')) {
            final parsed = jsonDecode(imagesString);
            if (parsed is List) {
              imageUrls = parsed.map((e) => e.toString()).toList();
            }
          } else {
            imageUrls = [imagesString];
          }

          product['images'] = imageUrls;
        } catch (e) {
          product['images'] = [];
        }
      } else if (product['images'] is List) {
        product['images'] = (product['images'] as List).map((e) => e.toString()).toList();
      } else {
        product['images'] = [];
      }

      // Calculer la quantité disponible si les variantes existent
      if (product['variants'] != null && product['variants'] is List) {
        int totalStock = 0;
        for (var variant in product['variants']) {
          final stock = variant['stock'];
          if (stock != null && stock is Map) {
            try {
              final quantity = (stock['quantity'] as num?)?.toInt() ?? 0;
              final reservedQuantity = (stock['reserved_quantity'] as num?)?.toInt() ?? 0;
              totalStock += quantity - reservedQuantity;
            } catch (e) {
              print('⚠️ Erreur parsing stock: $e');
            }
          }
        }
        product['available_stock'] = totalStock;
      }
    }
  }
}