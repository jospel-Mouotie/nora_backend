import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/storage_service.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  final StorageService _storageService = StorageService();

  UserModel? _user;
  String? _token;
  bool _isLoading = false;
  String? _errorMessage;
  String? _pendingEmail; // Email en attente de vérification

  UserModel? get user => _user;
  String? get token => _token;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _user != null && _token != null;
  String? get pendingEmail => _pendingEmail;

  AuthProvider() {
    _loadUserFromStorage();
  }

  Future<void> _loadUserFromStorage() async {
    try {
      final token = await _storageService.getToken();
      final userJson = await _storageService.getUser();

      if (token != null && userJson != null) {
        _token = token;
        final userMap = jsonDecode(userJson) as Map<String, dynamic>;
        _user = UserModel.fromJson(userMap);
        notifyListeners();
      }
    } catch (e) {
      print('Erreur chargement utilisateur: $e');
    }
  }

  // Étape 1: Demande d'inscription (envoie le code)
  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
    String role = 'client',
    String? phone,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _authService.register(
        name: name,
        email: email,
        password: password,
        passwordConfirmation: passwordConfirmation,
        role: role,
        phone: phone,
      );

      _isLoading = false;

      if (result['success']) {
        _pendingEmail = email;
        notifyListeners();
        return {
          'success': true,
          'message': result['message'],
          'email': result['email'],
          'code': result['code'], // Code de validation (en local)
        };
      } else {
        _errorMessage = result['message'] ?? 'Erreur lors de l\'inscription';
        notifyListeners();
        return {
          'success': false,
          'message': _errorMessage,
          'errors': result['errors'],
        };
      }
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Erreur de connexion au serveur';
      notifyListeners();
      return {
        'success': false,
        'message': _errorMessage,
      };
    }
  }

  // Étape 2: Vérifier le code de validation
  Future<bool> verifyCode({
    required String email,
    required String code,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _authService.verifyCode(
        email: email,
        code: code,
      );

      if (result['success']) {
        _user = result['user'] as UserModel;
        _token = result['token'] as String;
        _pendingEmail = null;
        await _storageService.setToken(_token!);
        await _storageService.setUser(jsonEncode(_user!.toJson()));

        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = result['message'] ?? 'Code invalide';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Erreur de connexion au serveur';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Renvoyer le code de validation
  Future<Map<String, dynamic>> resendCode({
    required String email,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _authService.resendCode(email: email);

      _isLoading = false;

      if (result['success']) {
        notifyListeners();
        return {
          'success': true,
          'message': result['message'],
          'code': result['code'],
        };
      } else {
        _errorMessage = result['message'] ?? 'Erreur lors de l\'envoi du code';
        notifyListeners();
        return {
          'success': false,
          'message': _errorMessage,
        };
      }
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Erreur de connexion au serveur';
      notifyListeners();
      return {
        'success': false,
        'message': _errorMessage,
      };
    }
  }

  Future<bool> login({
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _authService.login(
        email: email,
        password: password,
      );

      if (result['success']) {
        _user = result['user'] as UserModel;
        _token = result['token'] as String;
        await _storageService.setToken(_token!);
        await _storageService.setUser(jsonEncode(_user!.toJson()));
        
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = result['message'] ?? 'Email ou mot de passe incorrect';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Erreur de connexion au serveur';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> logout() async {
    _isLoading = true;
    notifyListeners();

    try {
      if (_token != null) {
        await _authService.logout(_token!);
      }
      
      _user = null;
      _token = null;
      
      await _storageService.clearAll();
      
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Erreur lors de la déconnexion';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateProfile({
    String? name,
    String? email,
    String? phone,
    String? address,
    String? city,
    String? country,
  }) async {
    if (_token == null) return false;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _authService.updateProfile(
        name: name,
        email: email,
        phone: phone,
        address: address,
        city: city,
        country: country,
        token: _token!,
      );

      if (result['success']) {
        _user = result['user'] as UserModel;
        await _storageService.setUser(jsonEncode(_user!.toJson()));
        
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = result['message'] ?? 'Erreur lors de la mise à jour';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Erreur de connexion au serveur';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateProfilePhoto(String photoPath) async {
    if (_token == null) return false;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final file = File(photoPath);
      final result = await _authService.uploadProfilePicture(
        file,
        _token!,
      );

      if (result['success']) {
        _user = result['user'] as UserModel;
        await _storageService.setUser(jsonEncode(_user!.toJson()));
        
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = result['message'] ?? 'Erreur lors de l\'upload';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Erreur de connexion au serveur';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  Future<bool> updateFcmToken(String fcmToken) async {
    if (_token == null) return false;

    try {
      final result = await _authService.updateFcmToken(
        token: _token!,
        fcmToken: fcmToken,
      );

      return result['success'] ?? false;
    } catch (e) {
      print('Erreur update FCM token: $e');
      return false;
    }
  }

  Future<bool> removeFcmToken() async {
    if (_token == null) return false;

    try {
      final result = await _authService.removeFcmToken(_token!);
      return result['success'] ?? false;
    } catch (e) {
      print('Erreur remove FCM token: $e');
      return false;
    }
  }
}
