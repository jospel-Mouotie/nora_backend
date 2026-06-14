import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/user_model.dart';
import '../config/app_constants.dart';

class AuthService {
  static const String baseUrl = AppConstants.apiBaseUrl;

  // Headers standard avec ou sans token
  Map<String, String> _getHeaders({String? token}) {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  // 1. Inscription
  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
    String role = 'client',
    String? phone,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/register'),
        headers: _getHeaders(),
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
          'message': data['message'],
          'email': data['email'],
          'code': data['code'], // Utile pour auto-remplir en phase de test
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

  // 2. Connexion
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: _getHeaders(),
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        if (data['user'] == null || data['token'] == null) {
          return {'success': false, 'message': 'Réponse invalide du serveur'};
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
      return {
        'success': false,
        'message': 'Erreur de connexion au serveur',
      };
    }
  }

  // 3. Vérification du code
  Future<Map<String, dynamic>> verifyCode({
    required String email,
    required String code,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/verify-code'),
        headers: _getHeaders(),
        body: jsonEncode({
          'email': email,
          'code': code,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 201) {
        return {
          'success': true,
          'user': UserModel.fromJson(data['user']),
          'token': data['token'],
          'message': data['message'],
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

  // 4. Renvoyer le code
  Future<Map<String, dynamic>> resendCode({required String email}) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/resend-code'),
        headers: _getHeaders(),
        body: jsonEncode({'email': email}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': data['message'],
          'code': data['code'],
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

  // 5. Déconnexion
  Future<Map<String, dynamic>> logout(String token) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/logout'),
        headers: _getHeaders(token: token),
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

  // 6. Obtenir le profil actuel (Me)
  Future<Map<String, dynamic>> getMe(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/me'),
        headers: _getHeaders(token: token),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'user': UserModel.fromJson(data),
        };
      } else {
        return {'success': false, 'message': 'Erreur de récupération du profil'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Erreur de connexion'};
    }
  }

  // 7. Mettre à jour le profil
  Future<Map<String, dynamic>> updateProfile({
    required String token,
    String? name,
    String? email,
    String? phone,
    String? address,
    String? city,
    String? country,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/user'),
        headers: _getHeaders(token: token),
        body: jsonEncode({
          if (name != null) 'name': name,
          if (email != null) 'email': email,
          if (phone != null) 'phone': phone,
          if (address != null) 'address': address,
          if (city != null) 'city': city,
          if (country != null) 'country': country,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': data['message'] ?? 'Profil mis à jour',
          'user': UserModel.fromJson(data['user'] ?? data),
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Erreur lors de la mise à jour',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Erreur de connexion'};
    }
  }

  // 8. Mettre à jour la photo de profil
  Future<Map<String, dynamic>> uploadProfilePicture(File file, String token) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/user/profile-picture'),
      );
      
      request.headers['Authorization'] = 'Bearer $token';
      request.headers['Accept'] = 'application/json';
      request.files.add(await http.MultipartFile.fromPath('profile_photo', file.path));
      
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      
      final data = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          'success': true,
          'user': UserModel.fromJson(data['user'] ?? data),
          'message': data['message'] ?? 'Photo mise à jour',
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Erreur lors de l\'upload',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Erreur de connexion au serveur',
      };
    }
  }

  // 9. Mettre à jour le token FCM
  Future<Map<String, dynamic>> updateFcmToken({
    required String token,
    required String fcmToken,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/fcm-token'),
        headers: _getHeaders(token: token),
        body: jsonEncode({'fcm_token': fcmToken}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': data['message'] ?? 'Token FCM mis à jour',
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Erreur lors de la mise à jour',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Erreur de connexion'};
    }
  }

  // 10. Supprimer le token FCM
  Future<Map<String, dynamic>> removeFcmToken(String token) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/fcm-token/remove'),
        headers: _getHeaders(token: token),
      );

      if (response.statusCode == 200) {
        return {'success': true, 'message': 'Token FCM supprimé'};
      } else {
        return {'success': false, 'message': 'Erreur lors de la suppression'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Erreur de connexion'};
    }
  }
}