import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../config/app_constants.dart';

class CategoryApiService {
  static const String baseUrl = AppConstants.apiBaseUrl;

  // ========== LECTURE ==========

  /// Récupérer toutes les catégories (avec leurs sous-catégories)
  Future<Map<String, dynamic>> getCategories() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/categories'),
        headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        List categories = [];
        if (data is List) {
          categories = data;
        } else if (data['categories'] is List) {
          categories = data['categories'];
        } else if (data['data'] is List) {
          categories = data['data'];
        }

        // Normaliser les IDs en int
        for (var cat in categories) {
          if (cat['id'] is String) cat['id'] = int.tryParse(cat['id']) ?? 0;
          if (cat['children'] is List) {
            for (var child in cat['children']) {
              if (child['id'] is String) child['id'] = int.tryParse(child['id']) ?? 0;
            }
          }
        }

        return {'success': true, 'categories': categories};
      }
      return {'success': false, 'categories': []};
    } catch (e) {
      debugPrint('❌ Erreur getCategories: $e');
      return {'success': false, 'categories': []};
    }
  }

  /// Récupérer les sous-catégories d'une catégorie
  Future<Map<String, dynamic>> getCategoryChildren(int categoryId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/categories/$categoryId/children'),
        headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        List subs = [];
        if (data is List) {
          subs = data;
        } else if (data['subcategories'] is List) {
          subs = data['subcategories'];
        } else if (data['data'] is List) {
          subs = data['data'];
        }
        // Normaliser les IDs
        for (var s in subs) {
          if (s['id'] is String) s['id'] = int.tryParse(s['id']) ?? 0;
        }
        return {'success': true, 'subcategories': subs};
      }
      return {'success': false, 'subcategories': []};
    } catch (e) {
      debugPrint('❌ Erreur getCategoryChildren: $e');
      return {'success': false, 'subcategories': []};
    }
  }

  // ========== CRUD ADMIN (multipart pour supporter l'image) ==========

  /// Créer une catégorie avec image (admin)
  Future<Map<String, dynamic>> createCategory(
    Map<String, dynamic> data,
    String token, {
    File? imageFile,
  }) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/admin/categories'),
      );
      request.headers['Authorization'] = 'Bearer $token';
      request.headers['Accept'] = 'application/json';

      // Champs textuels
      data.forEach((key, value) {
        if (value != null) request.fields[key] = value.toString();
      });

      // Image optionnelle
      if (imageFile != null) {
        final ext = imageFile.path.split('.').last.toLowerCase();
        request.files.add(await http.MultipartFile.fromPath(
          'image',
          imageFile.path,
          contentType: MediaType('image', ext == 'jpg' ? 'jpeg' : ext),
        ));
      }

      final streamed = await request.send();
      final response = await http.Response.fromStream(streamed);
      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          'success': true,
          'category': responseData['category'] ?? responseData,
          'message': responseData['message'] ?? 'Catégorie créée avec succès',
        };
      }
      return {
        'success': false,
        'message': responseData['message'] ?? responseData['errors']?.toString() ?? 'Erreur lors de la création',
      };
    } catch (e) {
      debugPrint('❌ Erreur createCategory: $e');
      return {'success': false, 'message': 'Erreur de connexion'};
    }
  }

  /// Mettre à jour une catégorie avec image (admin)
  Future<Map<String, dynamic>> updateCategory(
    int categoryId,
    Map<String, dynamic> data,
    String token, {
    File? imageFile,
  }) async {
    try {
      // Laravel ne supporte pas PUT multipart — on utilise POST + _method=PUT
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/admin/categories/$categoryId'),
      );
      request.headers['Authorization'] = 'Bearer $token';
      request.headers['Accept'] = 'application/json';
      request.fields['_method'] = 'PUT';

      data.forEach((key, value) {
        if (value != null) request.fields[key] = value.toString();
      });

      if (imageFile != null) {
        final ext = imageFile.path.split('.').last.toLowerCase();
        request.files.add(await http.MultipartFile.fromPath(
          'image',
          imageFile.path,
          contentType: MediaType('image', ext == 'jpg' ? 'jpeg' : ext),
        ));
      }

      final streamed = await request.send();
      final response = await http.Response.fromStream(streamed);
      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'category': responseData['category'] ?? responseData,
          'message': responseData['message'] ?? 'Catégorie mise à jour',
        };
      }
      return {
        'success': false,
        'message': responseData['message'] ?? 'Erreur lors de la mise à jour',
      };
    } catch (e) {
      debugPrint('❌ Erreur updateCategory: $e');
      return {'success': false, 'message': 'Erreur de connexion'};
    }
  }

  /// Supprimer une catégorie (admin)
  Future<Map<String, dynamic>> deleteCategory(int categoryId, String token) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/admin/categories/$categoryId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        final responseData = response.body.isNotEmpty ? jsonDecode(response.body) : {};
        return {
          'success': true,
          'message': responseData['message'] ?? 'Catégorie supprimée',
        };
      }
      final responseData = jsonDecode(response.body);
      return {
        'success': false,
        'message': responseData['message'] ?? 'Erreur lors de la suppression',
      };
    } catch (e) {
      debugPrint('❌ Erreur deleteCategory: $e');
      return {'success': false, 'message': 'Erreur de connexion'};
    }
  }
}
