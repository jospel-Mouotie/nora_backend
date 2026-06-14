import 'dart:io'; 
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_constants.dart';
import '../models/user_model.dart';

class ApiService {
  static const String baseUrl = AppConstants.apiBaseUrl;

  // ========== AUTHENTIFICATION ==========
  
  // Inscription
  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
    String role = 'customer',
    String? phone,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': name,
          'email': email,
          'phone': phone,
          'password': password,
          'password_confirmation': passwordConfirmation,
          'role': role,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          'success': true,
          'user': UserModel.fromJson(data['user']),
          'token': data['token'],
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Erreur lors de l\'inscription',
          'errors': data['errors'],
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Erreur de connexion au serveur',
      };
    }
  }

  // Connexion
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final url = '$baseUrl/login';
      print('🌐 Login URL: $url');
      print('📧 Email: $email');
      
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      print('📡 Login Status: ${response.statusCode}');
      print('📦 Login Response: ${response.body}');

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        // Vérifier que les données existent
        if (data['user'] == null || data['token'] == null) {
          return {
            'success': false,
            'message': 'Réponse invalide du serveur',
          };
        }
        
        return {
          'success': true,
          'user': UserModel.fromJson(data['user']),
          'token': data['token'],
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Email ou mot de passe incorrect',
        };
      }
    } catch (e) {
      print('❌ Login Exception: $e');
      return {
        'success': false,
        'message': 'Erreur de connexion au serveur: $e',
      };
    }
  }

  // Vérifier le code de validation
  Future<Map<String, dynamic>> verifyCode({
    required String email,
    required String code,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/verify-code'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'code': code,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          'success': true,
          'user': UserModel.fromJson(data['user']),
          'token': data['token'],
          'message': data['message'] ?? 'Validation réussie',
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Code invalide',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Erreur de connexion au serveur',
      };
    }
  }

  // Renvoyer le code de validation
  Future<Map<String, dynamic>> resendCode({
    required String email,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/resend-code'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': data['message'] ?? 'Code renvoyé',
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Erreur lors du renvoi',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Erreur de connexion au serveur',
      };
    }
  }
// Uploader la photo de profil
Future<Map<String, dynamic>> uploadProfilePicture(File file, String token) async {
  try {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/user/profile-picture'),
    );
    
    request.headers['Authorization'] = 'Bearer $token';
    request.files.add(await http.MultipartFile.fromPath('profile_picture', file.path));
    
    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    
    print('📡 uploadProfilePicture Status: ${response.statusCode}');
    print('📦 uploadProfilePicture Response: ${response.body}');

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = jsonDecode(response.body);
      return {
        'success': true,
        'user': data['user'] ?? data,
        'message': data['message'] ?? 'Photo de profil mise à jour',
      };
    } else {
      final data = jsonDecode(response.body);
      return {
        'success': false,
        'message': data['message'] ?? 'Erreur lors de l\'upload',
      };
    }
  } catch (e) {
    print('❌ Erreur uploadProfilePicture: $e');
    return {
      'success': false,
      'message': 'Erreur de connexion au serveur',
    };
  }
}

  // Mot de passe oublié
  Future<Map<String, dynamic>> forgotPassword({required String email}) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/forgot-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': data['message'] ?? 'Email de réinitialisation envoyé',
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Email non trouvé',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Erreur de connexion au serveur',
      };
    }
  }

  // Réinitialisation mot de passe
  Future<Map<String, dynamic>> resetPassword({
    required String email,
    required String token,
    required String password,
    required String passwordConfirmation,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/reset-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'token': token,
          'password': password,
          'password_confirmation': passwordConfirmation,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': data['message'] ?? 'Mot de passe réinitialisé',
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Erreur lors de la réinitialisation',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Erreur de connexion au serveur',
      };
    }
  }

  // Déconnexion
  Future<Map<String, dynamic>> logout(String token) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/logout'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return {'success': true};
      } else {
        return {'success': false, 'message': 'Erreur lors de la déconnexion'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Erreur de connexion'};
    }
  }

  // ========== CATÉGORIES ==========
  
  // Récupérer toutes les catégories
 Future<Map<String, dynamic>> getCategories() async {
  try {
    final url = '$baseUrl/categories';
    print('🌐 URL appelée: $url');
    
    final response = await http.get(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
    );
    
    print('📡 Status code: ${response.statusCode}');
    print('📦 Response body (début): ${response.body.substring(0, response.body.length > 200 ? 200 : response.body.length)}');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      
      // La réponse est directement un tableau, pas un objet avec une clé 'categories'
      List categories;
      if (data is List) {
        categories = data;
        print('✅ Format: Liste directe, ${categories.length} catégories');
      } else if (data['categories'] is List) {
        categories = data['categories'];
        print('✅ Format: Objet avec clé categories, ${categories.length} catégories');
      } else if (data['data'] is List) {
        categories = data['data'];
        print('✅ Format: Objet avec clé data, ${categories.length} catégories');
      } else {
        categories = [];
        print('⚠️ Format inconnu: ${data.runtimeType}');
      }
      
      return {
        'success': true,
        'categories': categories,
      };
    } else {
      print('❌ Erreur HTTP: ${response.statusCode}');
      return {'success': false, 'categories': []};
    }
  } catch (e, stackTrace) {
    print('❌ Exception: $e');
    print('❌ StackTrace: $stackTrace');
    return {'success': false, 'categories': []};
  }
}

  // Récupérer une catégorie par son ID
  Future<Map<String, dynamic>> getCategory(int categoryId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/categories/$categoryId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'category': data['category'] ?? data,
        };
      } else {
        return {'success': false, 'message': 'Catégorie non trouvée'};
      }
    } catch (e) {
      print('Erreur getCategory: $e');
      return {'success': false, 'message': 'Erreur de connexion'};
    }
  }

  // Récupérer les sous-catégories d'une catégorie
  Future<Map<String, dynamic>> getCategoryChildren(int categoryId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/categories/$categoryId/children'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'subcategories': data['subcategories'] ?? data['data'] ?? data,
        };
      } else {
        return {'success': false, 'subcategories': []};
      }
    } catch (e) {
      print('Erreur getCategoryChildren: $e');
      return {'success': false, 'subcategories': []};
    }
  }

  // Créer une catégorie (Admin)
  Future<Map<String, dynamic>> createCategory(Map<String, dynamic> data, String token) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/admin/categories'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(data),
      );

      final responseData = jsonDecode(response.body);
      if (response.statusCode == 201 || response.statusCode == 200) {
        return {'success': true, 'category': responseData['category'] ?? responseData};
      } else {
        return {'success': false, 'message': responseData['message'] ?? 'Erreur lors de la création'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Erreur de connexion'};
    }
  }

  // Mettre à jour une catégorie (Admin)
  Future<Map<String, dynamic>> updateCategory(int id, Map<String, dynamic> data, String token) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/admin/categories/$id'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(data),
      );

      final responseData = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {'success': true, 'category': responseData['category'] ?? responseData};
      } else {
        return {'success': false, 'message': responseData['message'] ?? 'Erreur lors de la mise à jour'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Erreur de connexion'};
    }
  }

  // Supprimer une catégorie (Admin)
  Future<Map<String, dynamic>> deleteCategory(int id, String token) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/admin/categories/$id'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        return {'success': true, 'message': 'Catégorie supprimée'};
      } else {
        final responseData = jsonDecode(response.body);
        return {'success': false, 'message': responseData['message'] ?? 'Erreur lors de la suppression'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Erreur de connexion'};
    }
  }

  // ========== CENTRES D'INTÉRÊT ==========
  
  // Enregistrer les centres d'intérêt
  Future<Map<String, dynamic>> selectInterests(List<Map<String, dynamic>> interests, String? token) async {
    try {
      final headers = {
        'Content-Type': 'application/json',
      };
      
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
      
      final response = await http.post(
        Uri.parse('$baseUrl/user-interests/select-multiple'),
        headers: headers,
        body: jsonEncode({
          'categories': interests,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {'success': true, 'data': data};
      } else {
        return {'success': false, 'message': data['message'] ?? 'Erreur lors de l\'enregistrement'};
      }
    } catch (e) {
      print('Erreur selectInterests: $e');
      return {'success': false, 'message': 'Erreur de connexion'};
    }
  }

  // Récupérer les centres d'intérêt de l'utilisateur
  Future<Map<String, dynamic>> getUserInterests(String? token) async {
    try {
      if (token == null || token.isEmpty) {
        return {'success': false, 'interests': []};
      }

      final response = await http.get(
        Uri.parse('$baseUrl/user-interests'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'interests': data['interests'] ?? [],
        };
      } else {
        return {'success': false, 'interests': []};
      }
    } catch (e) {
      print('Erreur getUserInterests: $e');
      return {'success': false, 'interests': []};
    }
  }

  // ========== PRODUITS ==========
// Récupérer tous les produits
// Récupérer tous les produits
Future<Map<String, dynamic>> getProducts({
  int limit = 20,
  String? search,
  int? categoryId,
  int? shopId,
  double? minPrice,
  double? maxPrice,
  String? sort,
}) async {
  try {
    final queryParams = <String, String>{};
    queryParams['limit'] = limit.toString();
    if (search != null) queryParams['search'] = search;
    if (categoryId != null) queryParams['category_id'] = categoryId.toString();
    if (shopId != null) queryParams['shop_id'] = shopId.toString();
    if (minPrice != null) queryParams['min_price'] = minPrice.toString();
    if (maxPrice != null) queryParams['max_price'] = maxPrice.toString();
    if (sort != null) queryParams['sort'] = sort;

    final uri = Uri.parse('$baseUrl/products').replace(queryParameters: queryParams);
    final response = await http.get(
      uri,
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      
      // Extraire la liste des produits
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
      
      // Parser les images pour chaque produit
      for (var product in products) {
        // Parser le champ images qui est une chaîne JSON
        if (product['images'] is String && (product['images'] as String).isNotEmpty) {
          try {
            final imagesString = product['images'] as String;
            List<String> imageUrls = [];
            
            // Si c'est un tableau JSON
            if (imagesString.startsWith('[')) {
              final parsed = jsonDecode(imagesString);
              if (parsed is List) {
                imageUrls = parsed.map((e) => e.toString()).toList();
              }
            } else {
              // Si c'est une simple chaîne
              imageUrls = [imagesString];
            }
            
            product['images'] = imageUrls;
          } catch (e) {
            product['images'] = [];
          }
        } else if (product['images'] is List) {
          // Déjà une liste
          product['images'] = (product['images'] as List).map((e) => e.toString()).toList();
        } else {
          product['images'] = [];
        }
      }
      
      return {
        'success': true,
        'products': products,
      };
    } else {
      return {'success': false, 'products': []};
    }
  } catch (e) {
    print('❌ Erreur getProducts: $e');
    return {'success': false, 'products': []};
  }
}
  // Récupérer un produit par son ID
  // Récupérer un produit par son ID
Future<Map<String, dynamic>> getProduct(int productId) async {
  try {
    final response = await http.get(
      Uri.parse('$baseUrl/products/$productId'),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final product = data['product'] ?? data;
      
      // Parser les images
      if (product['images'] is String && (product['images'] as String).isNotEmpty) {
        try {
          final imagesString = product['images'] as String;
          if (imagesString.startsWith('[')) {
            final parsed = jsonDecode(imagesString);
            if (parsed is List) {
              product['images'] = parsed.map((e) => e.toString()).toList();
            }
          } else {
            product['images'] = [imagesString];
          }
        } catch (e) {
          product['images'] = [];
        }
      } else if (product['images'] is List) {
        product['images'] = (product['images'] as List).map((e) => e.toString()).toList();
      } else {
        product['images'] = [];
      }
      
      return {
        'success': true,
        'product': product,
      };
    } else {
      return {'success': false, 'message': 'Produit non trouvé'};
    }
  } catch (e) {
    print('❌ Erreur getProduct: $e');
    return {'success': false, 'message': 'Erreur de connexion'};
  }
}
// Récupérer les produits en promotion
Future<Map<String, dynamic>> getPromotions() async {
  try {
    final response = await http.get(
      Uri.parse('$baseUrl/products/promotions'),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      
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
      
      return {
        'success': true,
        'products': products,
      };
    } else {
      return {'success': false, 'products': []};
    }
  } catch (e) {
    print('Erreur getPromotions: $e');
    return {'success': false, 'products': []};
  }
}
  // =========
  // Récupérer les avis d'un produit
Future<Map<String, dynamic>> getProductReviews(int productId) async {
  try {
    final response = await http.get(
      Uri.parse('$baseUrl/products/$productId/reviews'),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return {
        'success': true,
        'reviews': data['reviews'] ?? data,
      };
    } else {
      return {'success': false, 'reviews': []};
    }
  } catch (e) {
    print('Erreur getProductReviews: $e');
    return {'success': false, 'reviews': []};
  }
}
// Ajouter un avis sur un produit
Future<Map<String, dynamic>> addProductReview(int productId, int rating, String comment, String token) async {
  try {
    final response = await http.post(
      Uri.parse('$baseUrl/products/$productId/reviews'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
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
    return {
      'success': false,
      'message': 'Erreur de connexion au serveur',
    };
  }
}
  //= BOUTIQUES ==========
  
  // Récupérer toutes les boutiques
// Récupérer toutes les boutiques
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

    print('📡 getShops Status: ${response.statusCode}');
    print('📦 getShops Body: ${response.body.substring(0, response.body.length > 200 ? 200 : response.body.length)}');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      
      // Gérer différents formats de réponse
      List shops = [];
      
      if (data is List) {
        shops = data;
      } else if (data['shops'] is List) {
        shops = data['shops'];
      } else if (data['data'] is List) {
        shops = data['data'];
      } else if (data['shops'] != null && data['shops']['data'] is List) {
        shops = data['shops']['data'];
      }
      
      return {
        'success': true,
        'shops': shops,
      };
    } else {
      return {'success': false, 'shops': []};
    }
  } catch (e) {
    print('❌ Erreur getShops: $e');
    return {'success': false, 'shops': []};
  }
}
  // Récupérer une boutique par son ID
  Future<Map<String, dynamic>> getShop(int shopId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/shops/$shopId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'shop': data['shop'] ?? data,
        };
      } else {
        return {'success': false, 'message': 'Boutique non trouvée'};
      }
    } catch (e) {
      print('Erreur getShop: $e');
      return {'success': false, 'message': 'Erreur de connexion'};
    }
  }

  // Suivre une boutique
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
        return {'success': true};
      } else {
        return {'success': false, 'message': 'Erreur lors du follow'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Erreur de connexion'};
    }
  }

  // Ne plus suivre une boutique
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
        return {'success': true};
      } else {
        return {'success': false, 'message': 'Erreur lors du unfollow'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Erreur de connexion'};
    }
  }
// Like une boutique
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
      return {'success': true};
    } else {
      return {'success': false, 'message': 'Erreur lors du like'};
    }
  } catch (e) {
    return {'success': false, 'message': 'Erreur de connexion'};
  }
}

// Unlike une boutique
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
      return {'success': true};
    } else {
      return {'success': false, 'message': 'Erreur lors du unlike'};
    }
  } catch (e) {
    return {'success': false, 'message': 'Erreur de connexion'};
  }
}

// ========== BOUTIQUE MB ==========

// Récupérer les articles de la boutique MB
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
      return {
        'success': true,
        'items': data['items'] ?? data,
      };
    } else {
      return {'success': false, 'items': []};
    }
  } catch (e) {
    print('Erreur getMbShopItems: $e');
    return {'success': false, 'items': []};
  }
}

// Récupérer un article MB par son ID
Future<Map<String, dynamic>> getMbShopItem(int itemId) async {
  try {
    final response = await http.get(
      Uri.parse('$baseUrl/mb-shop-items/$itemId'),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return {
        'success': true,
        'item': data['item'] ?? data,
      };
    } else {
      return {'success': false, 'message': 'Article non trouvé'};
    }
  } catch (e) {
    print('Erreur getMbShopItem: $e');
    return {'success': false, 'message': 'Erreur de connexion'};
  }
}

// Acheter un article MB
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
    } else {
      return {
        'success': false,
        'message': data['message'] ?? 'Erreur lors de l\'achat',
      };
    }
  } catch (e) {
    return {
      'success': false,
      'message': 'Erreur de connexion au serveur',
    };
  }
}

// Récupérer les achats de l'utilisateur
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
      return {
        'success': true,
        'purchases': data['purchases'] ?? data,
      };
    } else {
      return {'success': false, 'purchases': []};
    }
  } catch (e) {
    print('Erreur getMbPurchases: $e');
    return {'success': false, 'purchases': []};
  }
}

// Récupérer les articles tendances
Future<Map<String, dynamic>> getTrendingMbItems({int limit = 10}) async {
  try {
    final response = await http.get(
      Uri.parse('$baseUrl/mb-shop-items/trending?limit=$limit'),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return {
        'success': true,
        'items': data['items'] ?? data,
      };
    } else {
      return {'success': false, 'items': []};
    }
  } catch (e) {
    print('Erreur getTrendingMbItems: $e');
    return {'success': false, 'items': []};
  }
}

// Récupérer les articles promotionnels
Future<Map<String, dynamic>> getPromotionalMbItems({int limit = 10}) async {
  try {
    final response = await http.get(
      Uri.parse('$baseUrl/mb-shop-items/promotional?limit=$limit'),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return {
        'success': true,
        'items': data['items'] ?? data,
      };
    } else {
      return {'success': false, 'items': []};
    }
  } catch (e) {
    print('Erreur getPromotionalMbItems: $e');
    return {'success': false, 'items': []};
  }
}

  // ========== PANIER ==========
  
  // Voir le panier
  Future<Map<String, dynamic>> getCart(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/cart'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'cart': data,
        };
      } else {
        return {'success': false, 'cart': null};
      }
    } catch (e) {
      print('Erreur getCart: $e');
      return {'success': false, 'cart': null};
    }
  }

  // Ajouter au panier
  Future<Map<String, dynamic>> addToCart({
    required int productId,
    required int quantity,
    int? productVariantId,
    required String token,
  }) async {
    try {
      final Map<String, dynamic> body = {
        'quantity': quantity,
      };
      if (productVariantId != null) {
        body['variant_id'] = productVariantId;
      } else {
        body['product_id'] = productId;
      }

      final response = await http.post(
        Uri.parse('$baseUrl/cart/add'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'cart': data};
      } else {
        return {'success': false, 'message': data['message'] ?? 'Erreur lors de l\'ajout'};
      }
    } catch (e) {
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
        },
        body: jsonEncode({'quantity': quantity}),
      );

      if (response.statusCode == 200) {
        return {'success': true};
      } else {
        return {'success': false, 'message': 'Erreur lors de la mise à jour'};
      }
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
        },
      );

      if (response.statusCode == 200) {
        return {'success': true};
      } else {
        return {'success': false, 'message': 'Erreur lors de la suppression'};
      }
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
        },
      );

      if (response.statusCode == 200) {
        return {'success': true};
      } else {
        return {'success': false, 'message': 'Erreur lors du vidage'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Erreur de connexion'};
    }
  }

  // ========== COMMANDES ==========
  // Note: Les méthodes de commandes sont déplacées vers order_api_service.dart
  // pour éviter la duplication et améliorer la maintenance

  // ========== PUBLICITÉS ==========
  
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

  // ========== STORIES ==========
  
  // Récupérer les stories des boutiques suivies
  Future<Map<String, dynamic>> getStoriesFeed(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/feed/stories'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'stories': data is List ? data : (data['stories'] ?? []),
        };
      } else {
        return {'success': false, 'stories': []};
      }
    } catch (e) {
      print('Erreur getStoriesFeed: $e');
      return {'success': false, 'stories': []};
    }
  }
  Future<Map<String, dynamic>> generateOrderQrCode(String orderId, String token) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/orders/$orderId/generate-qr'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'qr_code': data['qr_code'],
          'qr_code_url': data['qr_code_url'],
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Erreur lors de la génération du QR code',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Erreur de connexion au serveur',
      };
    }
  }

  // Scanner un QR code (par le livreur)
  Future<Map<String, dynamic>> scanQrCode(String qrCodeData, String token) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/delivery/scan-qr'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'qr_code': qrCodeData,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'delivery': data['delivery'],
          'order': data['order'],
          'message': data['message'] ?? 'QR code scanné avec succès',
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

  // Générer un PIN pour une livraison
  Future<Map<String, dynamic>> generateDeliveryPin(String deliveryId, String token) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/deliveries/$deliveryId/generate-pin'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'pin': data['pin'],
          'expires_at': data['expires_at'],
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Erreur lors de la génération du PIN',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Erreur de connexion au serveur',
      };
    }
  }

  // Vérifier un PIN (par le client pour confirmer la livraison)
  Future<Map<String, dynamic>> verifyDeliveryPin(String deliveryId, String pin, String token) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/deliveries/$deliveryId/verify-pin'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'pin': pin,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': data['message'] ?? 'PIN vérifié avec succès',
          'delivery_status': data['status'],
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

  // Récupérer le QR code d'une commande (sous forme d'image)
  Future<Map<String, dynamic>> getOrderQrCode(String orderId, String token) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/orders/$orderId/qr-code'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'qr_code': data['qr_code'],
          'qr_code_url': data['qr_code_url'],
        };
      } else {
        return {
          'success': false,
          'message': 'QR code non trouvé',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Erreur de connexion au serveur',
      };
    }
  }

  // Confirmer la livraison avec PIN (client)
  Future<Map<String, dynamic>> confirmDeliveryWithPin(String deliveryId, String pin, String token) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/deliveries/$deliveryId/confirm'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'pin': pin,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': data['message'] ?? 'Livraison confirmée',
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Erreur lors de la confirmation',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Erreur de connexion au serveur',
      };
    }
  }

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
        Uri.parse('$baseUrl/deliveries/$deliveryId/location'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'latitude': data['current_latitude'],
          'longitude': data['current_longitude'],
          'updated_at': data['updated_at'],
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




// ========== LIVRAISONS ==========



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


























  // ========== VIDÉOS (REELS) ==========

 // Récupérer les vidéos
// Dans api_service.dart
// Récupérer les vidéos
// Récupérer les vidéos
Future<Map<String, dynamic>> getVideos({int limit = 20, String? category, int? shopId}) async {
  try {
    final queryParams = <String, String>{};
    queryParams['limit'] = limit.toString();
    if (category != null) queryParams['category'] = category;
    if (shopId != null) queryParams['shop_id'] = shopId.toString();

    final uri = Uri.parse('$baseUrl/videos').replace(queryParameters: queryParams);
    final response = await http.get(
      uri,
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      
      // Extraire la liste des vidéos (gestion de la pagination)
      List videos = [];
      if (data['videos'] is List) {
        videos = data['videos'];
      } else if (data['data'] is List) {
        videos = data['data'];
      } else if (data is List) {
        videos = data;
      } else if (data['videos'] != null && data['videos']['data'] is List) {
        videos = data['videos']['data'];
      }
      
      // Formater les URLs des vidéos
      for (var video in videos) {
        // URL de la vidéo
        if (video['video_path'] != null) {
          video['video_url'] = video['video_path'];
        } else if (video['stream_url'] != null) {
          video['video_url'] = video['stream_url'];
        }
        
        // Miniature
        if (video['thumbnail_path'] != null && video['thumbnail_path'].toString().isNotEmpty) {
          String thumbnail = video['thumbnail_path'];
          if (!thumbnail.startsWith('http')) {
            thumbnail = '${AppConstants.apiBaseUrl.replaceAll('/api', '')}$thumbnail';
          }
          video['thumbnail'] = thumbnail;
        }
        
        // Compter les vues
        video['view_count'] = video['view_count'] ?? 0;
        video['likes_count'] = video['likes_count'] ?? 0;
        video['comments_count'] = video['comments_count'] ?? 0;
      }
      
      return {
        'success': true,
        'videos': videos,
      };
    } else {
      return {'success': false, 'videos': []};
    }
  } catch (e) {
    print('❌ Erreur getVideos: $e');
    return {'success': false, 'videos': []};
  }
}
// Récupérer une vidéo par son ID
Future<Map<String, dynamic>> getVideo(int videoId) async {
  try {
    final response = await http.get(
      Uri.parse('$baseUrl/videos/$videoId'),
      headers: {'Content-Type': 'application/json'},
    );

    print('📡 getVideo Status: ${response.statusCode}');
    print('📦 getVideo Body: ${response.body}');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      
      // Gérer différents formats de réponse avec conversion explicite
      Map<String, dynamic> video = {};
      
      if (data['video'] != null) {
        video = Map<String, dynamic>.from(data['video']);
      } else if (data['data'] != null) {
        video = Map<String, dynamic>.from(data['data']);
      } else if (data is Map) {
        video = Map<String, dynamic>.from(data);
      }
      
      return {
        'success': true,
        'video': video,
      };
    } else if (response.statusCode == 404) {
      return {'success': false, 'message': 'Vidéo non trouvée'};
    } else {
      return {'success': false, 'message': 'Erreur lors du chargement'};
    }
  } catch (e) {
    print('❌ Erreur getVideo: $e');
    return {'success': false, 'message': 'Erreur de connexion'};
  }
}
  // Récupérer les vidéos tendances
  Future<Map<String, dynamic>> getTrendingVideos({int limit = 20}) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/videos/trending?limit=$limit'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'videos': data['videos'] ?? data,
        };
      } else {
        return {'success': false, 'videos': []};
      }
    } catch (e) {
      print('Erreur getTrendingVideos: $e');
      return {'success': false, 'videos': []};
    }
  }
// ========== VIDÉOS - COMMENTAIRES ==========

// Récupérer les commentaires d'une vidéo
Future<Map<String, dynamic>> getVideoComments(int videoId) async {
  try {
    final response = await http.get(
      Uri.parse('$baseUrl/videos/$videoId/comments'),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return {
        'success': true,
        'comments': data['comments'] ?? data,
      };
    } else {
      return {'success': false, 'comments': []};
    }
  } catch (e) {
    print('Erreur getVideoComments: $e');
    return {'success': false, 'comments': []};
  }
}

// Ajouter un commentaire
Future<Map<String, dynamic>> addVideoComment(int videoId, String content, String token) async {
  try {
    final response = await http.post(
      Uri.parse('$baseUrl/videos/$videoId/comments'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'content': content}),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200 || response.statusCode == 201) {
      return {
        'success': true,
        'comment': data['comment'] ?? data,
      };
    } else {
      return {
        'success': false,
        'message': data['message'] ?? 'Erreur lors de l\'ajout du commentaire',
      };
    }
  } catch (e) {
    return {
      'success': false,
      'message': 'Erreur de connexion au serveur',
    };
  }
}

// Toggle like sur une vidéo
Future<Map<String, dynamic>> toggleVideoLike(int videoId, String token) async {
  try {
    final response = await http.post(
      Uri.parse('$baseUrl/videos/$videoId/like'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return {
        'success': true,
        'is_liked': data['is_liked'] ?? true,
        'likes_count': data['likes_count'],
      };
    } else {
      return {'success': false};
    }
  } catch (e) {
    return {'success': false};
  }
}
  // ========== MB COINS ==========
// Uploader une vidéo
Future<Map<String, dynamic>> uploadVideo({
  required File file,
  required String title,
  required String description,
  required String token,
  Function(double)? onProgress,
}) async {
  try {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/videos/upload'),
    );
    
    request.headers['Authorization'] = 'Bearer $token';
    request.fields['title'] = title;
    request.fields['description'] = description;
    request.files.add(await http.MultipartFile.fromPath('video', file.path));
    
    final response = await request.send();
    
    if (response.statusCode == 200 || response.statusCode == 201) {
      final responseData = await response.stream.bytesToString();
      final data = jsonDecode(responseData);
      return {
        'success': true,
        'video': data['video'],
      };
    } else {
      return {
        'success': false,
        'message': 'Erreur lors de l\'upload',
      };
    }
  } catch (e) {
    return {
      'success': false,
      'message': 'Erreur: $e',
    };
  }
}




  // Récupérer le solde MB Coins
  Future<Map<String, dynamic>> getMbCoinsBalance(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/mb-coins/balance'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'balance': data,
        };
      } else {
        return {'success': false, 'message': 'Erreur lors du chargement du solde'};
      }
    } catch (e) {
      print('Erreur getMbCoinsBalance: $e');
      return {'success': false, 'message': 'Erreur de connexion'};
    }
  }
// Demander un retrait MB Coins
Future<Map<String, dynamic>> requestMbWithdrawal({
  required double amount,
  required String method,
  required Map<String, dynamic> details,
  required String token,
}) async {
  try {
    final response = await http.post(
      Uri.parse('$baseUrl/mb-coins/withdraw'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'amount': amount,
        'method': method,
        'details': details,
      }),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return {
        'success': true,
        'message': data['message'] ?? 'Demande envoyée',
      };
    } else {
      return {
        'success': false,
        'message': data['message'] ?? 'Erreur lors de la demande',
      };
    }
  } catch (e) {
    return {
      'success': false,
      'message': 'Erreur de connexion au serveur',
    };
  }
}
  // Récupérer l'historique des transactions MB Coins
  Future<Map<String, dynamic>> getMbCoinsTransactions({
    String? type,
    String? startDate,
    String? endDate,
    int limit = 20,
    required String token,
  }) async {
    try {
      final queryParams = <String, String>{};
      queryParams['limit'] = limit.toString();
      if (type != null) queryParams['type'] = type;
      if (startDate != null) queryParams['start_date'] = startDate;
      if (endDate != null) queryParams['end_date'] = endDate;

      final uri = Uri.parse('$baseUrl/mb-coins/transactions').replace(queryParameters: queryParams);
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
          'transactions': data['transactions'] ?? data,
          'summary': data['summary'],
        };
      } else {
        return {'success': false, 'transactions': []};
      }
    } catch (e) {
      print('Erreur getMbCoinsTransactions: $e');
      return {'success': false, 'transactions': []};
    }
  }

  // Récupérer les récompenses MB disponibles
  Future<Map<String, dynamic>> getMbRewards({String? status, int limit = 20}) async {
    try {
      final queryParams = <String, String>{};
      queryParams['limit'] = limit.toString();
      if (status != null) queryParams['status'] = status;

      final uri = Uri.parse('$baseUrl/mb-rewards').replace(queryParameters: queryParams);
      final response = await http.get(
        uri,
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'rewards': data['rewards'] ?? data,
          'summary': data['summary'],
        };
      } else {
        return {'success': false, 'rewards': []};
      }
    } catch (e) {
      print('Erreur getMbRewards: $e');
      return {'success': false, 'rewards': []};
    }
  }

  // Réclamer une récompense
  Future<Map<String, dynamic>> claimMbReward(int rewardId, String token) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/mb-rewards/$rewardId/claim'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': data['message'] ?? 'Récompense réclamée',
          'new_balance': data['new_balance'],
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Erreur lors du réclamation',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Erreur de connexion au serveur',
      };
    }
  }


// ========== BOUTIQUE MB ==========

// Récupérer la liste des boutiques MB
Future<Map<String, dynamic>> getMbShops() async {
  try {
    final response = await http.get(
      Uri.parse('$baseUrl/mb-shops'),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return {
        'success': true,
        'shops': data['shops'] ?? data,
      };
    } else {
      return {'success': false, 'shops': []};
    }
  } catch (e) {
    print('Erreur getMbShops: $e');
    return {'success': false, 'shops': []};
  }
}





  // ========== UTILISATEUR ==========
  
  // Récupérer le profil utilisateur
  Future<Map<String, dynamic>> getUserProfile(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/user'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'user': data,
        };
      } else {
        return {'success': false, 'message': 'Erreur lors du chargement du profil'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Erreur de connexion'};
    }
  }

  // Mettre à jour le profil utilisateur
  Future<Map<String, dynamic>> updateUserProfile({
    required String name,
    String? phone,
    String? address,
    String? city,
    String? postalCode,
    required String token,
  }) async {
    try {
      final body = {
        'name': name,
      };
      if (phone != null) body['phone'] = phone;
      if (address != null) body['address'] = address;
      if (city != null) body['city'] = city;
      if (postalCode != null) body['postal_code'] = postalCode;

      final response = await http.put(
        Uri.parse('$baseUrl/user'),
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
          'user': data['user'] ?? data,
        };
      } else {
        return {'success': false, 'message': 'Erreur lors de la mise à jour'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Erreur de connexion'};
    }
  }








  // ========== CHAT ADMIN ==========

// Récupérer les conversations admin
Future<Map<String, dynamic>> getAdminConversations(String token) async {
  try {
    final response = await http.get(
      Uri.parse('$baseUrl/admin-chat/recent-conversations'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return {
        'success': true,
        'conversations': data['conversations'] ?? data,
      };
    } else {
      return {'success': false, 'conversations': []};
    }
  } catch (e) {
    print('Erreur getAdminConversations: $e');
    return {'success': false, 'conversations': []};
  }
}

// Récupérer une conversation admin avec un utilisateur
Future<Map<String, dynamic>> getAdminConversation(int userId, String token) async {
  try {
    final response = await http.get(
      Uri.parse('$baseUrl/admin-chat/conversation/$userId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
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
    print('Erreur getAdminConversation: $e');
    return {'success': false, 'messages': []};
  }
}

// Envoyer un message admin
Future<Map<String, dynamic>> sendAdminMessage(int userId, String content, String token) async {
  try {
    final response = await http.post(
      Uri.parse('$baseUrl/admin-chat/send'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'user_id': userId,
        'content': content,
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

// Récupérer un utilisateur par son ID
Future<Map<String, dynamic>> getUserById(int userId, String token) async {
  try {
    final response = await http.get(
      Uri.parse('$baseUrl/admin-chat/user/$userId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return {
        'success': true,
        'user': data['user'] ?? data,
      };
    } else {
      return {'success': false, 'message': 'Utilisateur non trouvé'};
    }
  } catch (e) {
    print('Erreur getUserById: $e');
    return {'success': false, 'message': 'Erreur de connexion'};
  }
}
// ========== GESTION BOUTIQUE (COMMERÇANT) ==========

// Récupérer mes boutiques
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
      return {
        'success': true,
        'shops': data['shops'] ?? [],
      };
    } else {
      return {'success': false, 'message': 'Boutiques non trouvées'};
    }
  } catch (e) {
    print('Erreur getMyShops: $e');
    return {'success': false, 'message': 'Erreur de connexion'};
  }
}

// Récupérer les statistiques de la boutique
Future<Map<String, dynamic>> getShopStats(String token) async {
  try {
    final response = await http.get(
      Uri.parse('$baseUrl/dashboard/shop-stats'),
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
    print('Erreur getShopStats: $e');
    return {'success': false, 'stats': null};
  }
}

  // Récupérer mes produits
  Future<Map<String, dynamic>> getMyProducts(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/my-products'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        List products = [];
        if (data is List) {
          products = data;
        } else if (data['data'] is List) {
          products = data['data'];
        } else if (data['products'] is List) {
          products = data['products'];
        }
        
        return {
          'success': true,
          'products': products,
        };
      } else {
        return {'success': false, 'products': []};
      }
  } catch (e) {
    print('Erreur getMyProducts: $e');
    return {'success': false, 'products': []};
  }
}

// Créer un produit
Future<Map<String, dynamic>> createProduct(
  String name,
  double price,
  String description,
  int categoryId,
  int stock,
  double? comparePrice,
  List<File> images,
  String token,
) async {
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
    request.fields['stock'] = stock.toString();
    if (comparePrice != null) {
      request.fields['compare_price'] = comparePrice.toString();
    }
    
    for (var i = 0; i < images.length; i++) {
      request.files.add(
        await http.MultipartFile.fromPath('images[$i]', images[i].path),
      );
    }
    
    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    
    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = jsonDecode(response.body);
      return {
        'success': true,
        'product': data['product'] ?? data,
      };
    } else {
      final data = jsonDecode(response.body);
      return {
        'success': false,
        'message': data['message'] ?? 'Erreur lors de la création',
      };
    }
  } catch (e) {
    print('Erreur createProduct: $e');
    return {
      'success': false,
      'message': 'Erreur de connexion',
    };
  }
}

// Mettre à jour un produit
Future<Map<String, dynamic>> updateProduct(
  int productId,
  String name,
  double price,
  String description,
  int categoryId,
  int stock,
  double? comparePrice,
  bool isActive,
  String token,
) async {
  try {
    final response = await http.put(
      Uri.parse('$baseUrl/products/$productId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'name': name,
        'price': price,
        'description': description,
        'category_id': categoryId,
        'stock': stock,
        'compare_price': comparePrice,
        'is_active': isActive,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return {
        'success': true,
        'product': data['product'] ?? data,
      };
    } else {
      final data = jsonDecode(response.body);
      return {
        'success': false,
        'message': data['message'] ?? 'Erreur lors de la mise à jour',
      };
    }
  } catch (e) {
    print('Erreur updateProduct: $e');
    return {
      'success': false,
      'message': 'Erreur de connexion',
    };
  }
}

// Supprimer un produit
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
      return {'success': true};
    } else {
      final data = jsonDecode(response.body);
      return {
        'success': false,
        'message': data['message'] ?? 'Erreur lors de la suppression',
      };
    }
  } catch (e) {
    print('Erreur deleteProduct: $e');
    return {
      'success': false,
      'message': 'Erreur de connexion',
    };
  }
}
// Récupérer les commandes de ma boutique
Future<Map<String, dynamic>> getMyShopOrders(String token) async {
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
        'orders': data['orders'] ?? data,
      };
    } else {
      return {'success': false, 'orders': []};
    }
  } catch (e) {
    print('Erreur getMyShopOrders: $e');
    return {'success': false, 'orders': []};
  }
}

// Récupérer mes vidéos (boutique)
Future<Map<String, dynamic>> getMyVideos(String token) async {
  try {
    final response = await http.get(
      Uri.parse('$baseUrl/videos/my'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return {
        'success': true,
        'videos': data['videos'] ?? data,
      };
    } else {
      return {'success': false, 'videos': []};
    }
  } catch (e) {
    print('Erreur getMyVideos: $e');
    return {'success': false, 'videos': []};
  }
}

// Supprimer une vidéo
Future<Map<String, dynamic>> deleteVideo(int videoId, String token) async {
  try {
    final response = await http.delete(
      Uri.parse('$baseUrl/videos/$videoId'),
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
// ========== DASHBOARD LIVREUR ==========

// Récupérer mes missions
Future<Map<String, dynamic>> getMyMissions(String token) async {
  try {
    final response = await http.get(
      Uri.parse('$baseUrl/delivery-person/missions'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return {
        'success': true,
        'missions': data['missions'] ?? data,
      };
    } else {
      return {'success': false, 'missions': []};
    }
  } catch (e) {
    print('Erreur getMyMissions: $e');
    return {'success': false, 'missions': []};
  }
}

// Accepter une mission
Future<Map<String, dynamic>> acceptMission(int missionId, String token) async {
  try {
    final response = await http.post(
      Uri.parse('$baseUrl/delivery-person/missions/$missionId/accept'),
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
        'message': data['message'] ?? 'Erreur lors de l\'acceptation',
      };
    }
  } catch (e) {
    return {'success': false, 'message': 'Erreur de connexion'};
  }
}

// Terminer une mission
Future<Map<String, dynamic>> completeMission(int missionId, String token) async {
  try {
    final response = await http.post(
      Uri.parse('$baseUrl/delivery-person/missions/$missionId/complete'),
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
        'message': data['message'] ?? 'Erreur lors de la completion',
      };
    }
  } catch (e) {
    return {'success': false, 'message': 'Erreur de connexion'};
  }
}

// Récupérer les gains du livreur
Future<Map<String, dynamic>> getDriverEarnings(String token) async {
  try {
    final response = await http.get(
      Uri.parse('$baseUrl/delivery-person/earnings'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return {
        'success': true,
        'earnings': data['earnings'] ?? data,
        'transactions': data['transactions'] ?? [],
      };
    } else {
      return {'success': false, 'earnings': null};
    }
  } catch (e) {
    print('Erreur getDriverEarnings: $e');
    return {'success': false, 'earnings': null};
  }
}

// Récupérer les statistiques du livreur
Future<Map<String, dynamic>> getDriverStats(String token) async {
  try {
    final response = await http.get(
      Uri.parse('$baseUrl/delivery-person/stats'),
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
    print('Erreur getDriverStats: $e');
    return {'success': false, 'stats': null};
  }
}
// ========== ADMIN ==========

// Récupérer les statistiques admin
Future<Map<String, dynamic>> getAdminStats(String token) async {
  try {
    final response = await http.get(
      Uri.parse('$baseUrl/dashboard'),
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
    print('Erreur getAdminStats: $e');
    return {'success': false, 'stats': null};
  }
}

// Récupérer tous les utilisateurs
Future<Map<String, dynamic>> getUsers(String token) async {
  try {
    final response = await http.get(
      Uri.parse('$baseUrl/admin/users'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return {
        'success': true,
        'users': data['users'] ?? data,
      };
    } else {
      return {'success': false, 'users': []};
    }
  } catch (e) {
    print('Erreur getUsers: $e');
    return {'success': false, 'users': []};
  }
}

// Mettre à jour le statut d'un utilisateur
Future<Map<String, dynamic>> updateUserStatus(int userId, bool isActive, String token) async {
  try {
    final response = await http.put(
      Uri.parse('$baseUrl/admin/users/$userId/status'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'is_active': isActive}),
    );

    if (response.statusCode == 200) {
      return {'success': true};
    } else {
      return {'success': false, 'message': 'Erreur lors de la mise à jour'};
    }
  } catch (e) {
    return {'success': false, 'message': 'Erreur de connexion'};
  }
}

// Récupérer les boutiques en attente
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
      return {
        'success': true,
        'shops': data['shops'] ?? data,
      };
    } else {
      return {'success': false, 'shops': []};
    }
  } catch (e) {
    print('Erreur getPendingShops: $e');
    return {'success': false, 'shops': []};
  }
}

// Approuver une boutique
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
      return {'success': true};
    } else {
      return {'success': false, 'message': 'Erreur lors de l\'approbation'};
    }
  } catch (e) {
    return {'success': false, 'message': 'Erreur de connexion'};
  }
}

// Rejeter une boutique
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
      return {'success': true};
    } else {
      return {'success': false, 'message': 'Erreur lors du rejet'};
    }
  } catch (e) {
    return {'success': false, 'message': 'Erreur de connexion'};
  }
}

// Certifier une boutique
Future<Map<String, dynamic>> toggleShopCertification(int shopId, String token) async {
  try {
    final response = await http.post(
      Uri.parse('$baseUrl/admin/shops/$shopId/certifier'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return {'success': true};
    } else {
      return {'success': false, 'message': 'Erreur lors de la certification'};
    }
  } catch (e) {
    return {'success': false, 'message': 'Erreur de connexion'};
  }
}

// Récupérer les stories en attente
Future<Map<String, dynamic>> getPendingStories(String token) async {
  try {
    final response = await http.get(
      Uri.parse('$baseUrl/admin/stories/en-attente'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return {
        'success': true,
        'stories': data['stories'] ?? data,
      };
    } else {
      return {'success': false, 'stories': []};
    }
  } catch (e) {
    print('Erreur getPendingStories: $e');
    return {'success': false, 'stories': []};
  }
}

// Approuver une story
Future<Map<String, dynamic>> approveStory(int storyId, String token) async {
  try {
    final response = await http.post(
      Uri.parse('$baseUrl/admin/stories/$storyId/valider'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return {'success': true};
    } else {
      return {'success': false, 'message': 'Erreur lors de l\'approbation'};
    }
  } catch (e) {
    return {'success': false, 'message': 'Erreur de connexion'};
  }
}

// Rejeter une story
Future<Map<String, dynamic>> rejectStory(int storyId, String token) async {
  try {
    final response = await http.post(
      Uri.parse('$baseUrl/admin/stories/$storyId/refuser'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return {'success': true};
    } else {
      return {'success': false, 'message': 'Erreur lors du rejet'};
    }
  } catch (e) {
    return {'success': false, 'message': 'Erreur de connexion'};
  }
}
// Récupérer les avis d'une boutique
  Future<Map<String, dynamic>> getShopReviews(int shopId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/shops/$shopId/reviews'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'reviews': data['reviews'] ?? data,
        };
      } else {
        return {'success': false, 'reviews': []};
      }
    } catch (e) {
      print('Erreur getShopReviews: $e');
      return {'success': false, 'reviews': []};
    }
  }
  // Ajouter un avis sur une boutique
  Future<Map<String, dynamic>> addShopReview(int shopId, int rating, String comment, String token) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/shops/$shopId/reviews'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
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
      return {
        'success': false,
        'message': 'Erreur de connexion au serveur',
      };
    }
    // Créer une boutique
Future<Map<String, dynamic>> createShop({
  required String name,
  required String description,
  required String address,
  required String phone,
  required String email,
  required String token,
}) async {
  try {
    final response = await http.post(
      Uri.parse('$baseUrl/shops'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'name': name,
        'description': description,
        'address': address,
        'phone': phone,
        'email': email,
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = jsonDecode(response.body);
      return {'success': true, 'shop': data['shop'] ?? data};
    } else {
      final data = jsonDecode(response.body);
      return {'success': false, 'message': data['message'] ?? 'Erreur lors de la création'};
    }
  } catch (e) {
    return {'success': false, 'message': 'Erreur de connexion'};
  }
}

// Mettre à jour une boutique
Future<Map<String, dynamic>> updateShop(
  int shopId, {
  required String name,
  required String description,
  required String address,
  required String phone,
  required String email,
  required String token,
}) async {
  try {
    final response = await http.put(
      Uri.parse('$baseUrl/shops/$shopId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'name': name,
        'description': description,
        'address': address,
        'phone': phone,
        'email': email,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return {'success': true, 'shop': data['shop'] ?? data};
    } else {
      final data = jsonDecode(response.body);
      return {'success': false, 'message': data['message'] ?? 'Erreur lors de la mise à jour'};
    }
  } catch (e) {
    return {'success': false, 'message': 'Erreur de connexion'};
  }
}
  }
// ========== GESTION BOUTIQUE (COMMERÇANT) ==========

// Créer une boutique
Future<Map<String, dynamic>> createShop({
  required String name,
  required String description,
  required String address,
  required String phone,
  required String email,
  required String token,
}) async {
  try {
    final response = await http.post(
      Uri.parse('$baseUrl/shops'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'name': name,
        'description': description,
        'address': address,
        'phone': phone,
        'email': email,
      }),
    );

    print('📡 createShop Status: ${response.statusCode}');
    print('📦 createShop Response: ${response.body}');

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = jsonDecode(response.body);
      return {
        
        'success': true,
        'shop': data['shop'] ?? data,
        'message': 'Boutique créée avec succès',
      };
    } else {
      final data = jsonDecode(response.body);
      return {
        'success': false,
        'message': data['message'] ?? 'Erreur lors de la création',
      };
    }
  } catch (e) {
    print('❌ Erreur createShop: $e');
    return {
      'success': false,
      'message': 'Erreur de connexion au serveur',
    };
  }
}

// Mettre à jour une boutique
Future<Map<String, dynamic>> updateShop(
  int shopId, {
  required String name,
  required String description,
  required String address,
  required String phone,
  required String email,
  required String token,
}) async {
  try {
    final response = await http.put(
      Uri.parse('$baseUrl/shops/$shopId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'name': name,
        'description': description,
        'address': address,
        'phone': phone,
        'email': email,
      }),
    );

    print('📡 updateShop Status: ${response.statusCode}');
    print('📦 updateShop Response: ${response.body}');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return {
        'success': true,
        'shop': data['shop'] ?? data,
        'message': 'Boutique mise à jour',
      };
    } else {
      final data = jsonDecode(response.body);
      return {
        'success': false,
        'message': data['message'] ?? 'Erreur lors de la mise à jour',
      };
    }
  } catch (e) {
    print('❌ Erreur updateShop: $e');
    return {
      'success': false,
      'message': 'Erreur de connexion au serveur',
    };
  }
}
// Uploader le logo de la boutique
  Future<Map<String, dynamic>> uploadShopLogo(int shopId, File file, String token) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/shops/$shopId/logo'),
      );

      request.headers['Authorization'] = 'Bearer $token';
      request.files.add(await http.MultipartFile.fromPath('logo', file.path));

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      print('📡 uploadShopLogo Status: ${response.statusCode}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'logo_url': data['logo_url'],
          'message': 'Logo mis à jour',
        };
      } else {
        return {
          'success': false,
          'message': 'Erreur lors de l\'upload du logo',
        };
      }
    } catch (e) {
      print('❌ Erreur uploadShopLogo: $e');
      return {
        'success': false,
        'message': 'Erreur de connexion',
      };
    }
  }

// Uploader la bannière de la boutique
  Future<Map<String, dynamic>> uploadShopBanner(int shopId, File file, String token) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/shops/$shopId/banner'),
      );

      request.headers['Authorization'] = 'Bearer $token';
      request.files.add(await http.MultipartFile.fromPath('banner', file.path));

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      print('📡 uploadShopBanner Status: ${response.statusCode}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'banner_url': data['banner_url'],
          'message': 'Bannière mise à jour',
        };
      } else {
        return {
          'success': false,
          'message': 'Erreur lors de l\'upload de la bannière',
        };
      }
    } catch (e) {
      print('❌ Erreur uploadShopBanner: $e');
      return {
        'success': false,
        'message': 'Erreur de connexion',
      };
    }
  }
}