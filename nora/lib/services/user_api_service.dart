import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_constants.dart';

class UserApiService {
  static const String baseUrl = AppConstants.apiBaseUrl;

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

  // Activer ou désactiver un utilisateur (admin)
  Future<Map<String, dynamic>> updateUserStatus(
      int userId, bool isActive, String token) async {
    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/admin/users/$userId/status'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'is_active': isActive}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'message': data['message'] ?? 'Statut mis à jour',
        };
      } else {
        final data = jsonDecode(response.body);
        return {
          'success': false,
          'message': data['message'] ?? 'Erreur lors de la mise à jour',
        };
      }
    } catch (e) {
      print('❌ Erreur updateUserStatus: $e');
      return {'success': false, 'message': 'Erreur de connexion'};
    }
  }

  // Uploader la photo de profil
  Future<Map<String, dynamic>> uploadProfilePicture(
      dynamic imageFile, String token) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/user/profile-picture'),
      );
      request.headers['Authorization'] = 'Bearer $token';
      request.headers['Accept'] = 'application/json';
      request.files.add(
        await http.MultipartFile.fromPath('profile_picture', imageFile.path),
      );

      final streamed = await request.send();
      final response = await http.Response.fromStream(streamed);
      final data = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          'success': true,
          'user': data['user'] ?? data,
          'message': data['message'] ?? 'Photo mise à jour',
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Erreur lors de l\'upload',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Erreur de connexion'};
    }
  }
}
