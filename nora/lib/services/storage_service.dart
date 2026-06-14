import 'dart:convert';  // AJOUTE CETTE LIGNE
import 'package:nora/services/user_api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  static SharedPreferences? _preferences;

  static const String _keyOnboardingCompleted = 'onboarding_completed';
  static const String _keyInterestsSelected = 'interests_selected';
  static const String _keyToken = 'auth_token';
  static const String _keyUser = 'user_data';
  static const String _keyLocalInterests = 'local_interests';  // Ajouté

  static Future<void> init() async {
    _preferences = await SharedPreferences.getInstance();
  }

  SharedPreferences get prefs {
    if (_preferences == null) {
      throw Exception('SharedPreferences not initialized. Call StorageService.init() first.');
    }
    return _preferences!;
  }

  // ========== ONBOARDING ==========
  Future<void> setOnboardingCompleted(bool completed) async {
    await prefs.setBool(_keyOnboardingCompleted, completed);
  }

  Future<bool> isOnboardingCompleted() async {
    return prefs.getBool(_keyOnboardingCompleted) ?? false;
  }

  // ========== CENTRES D'INTÉRÊT ==========
  Future<void> setInterestsSelected(bool selected) async {
    await prefs.setBool(_keyInterestsSelected, selected);
  }

  Future<bool> areInterestsSelected() async {
    return prefs.getBool(_keyInterestsSelected) ?? false;
  }

  // Sauvegarder les intérêts localement
  Future<void> saveLocalInterests(List<Map<String, dynamic>> interests) async {
    final jsonString = jsonEncode(interests);
    await prefs.setString(_keyLocalInterests, jsonString);
  }

  // Récupérer les intérêts locaux
  Future<List<Map<String, dynamic>>> getLocalInterests() async {
    final data = prefs.getString(_keyLocalInterests);
    if (data == null || data.isEmpty) return [];
    try {
      final List<dynamic> decoded = jsonDecode(data);
      return decoded.map((e) => Map<String, dynamic>.from(e)).toList();
    } catch (e) {
      return [];
    }
  }

  // Supprimer les intérêts locaux (après synchro)
  Future<void> clearLocalInterests() async {
    await prefs.remove(_keyLocalInterests);
  }

  // ========== AUTH ==========
  Future<void> setToken(String token) async {
    await prefs.setString(_keyToken, token);
    await prefs.setString('token', token);
  }

  Future<String?> getToken() async {
    return prefs.getString(_keyToken) ?? prefs.getString('token');
  }

  Future<void> clearToken() async {
    await prefs.remove(_keyToken);
    await prefs.remove('token');
  }

  Future<void> setUser(String userJson) async {
    await prefs.setString(_keyUser, userJson);
  }

  Future<String?> getUser() async {
    return prefs.getString(_keyUser);
  }

  // Synchroniser les intérêts avec l'API (à appeler après connexion)
  Future<void> syncInterestsWithApi(String token) async {
    final localInterests = await getLocalInterests();
    final userApiService = UserApiService();
    if (localInterests.isNotEmpty) {
      await userApiService.selectInterests(localInterests, token);
      await clearLocalInterests();
      await setInterestsSelected(true);
      print('✅ Intérêts synchronisés avec l\'API');
    } else {
      // Pas d'intérêts locaux, on vérifie si l'utilisateur a déjà des intérêts sur le serveur
      try {
        final result = await userApiService.getUserInterests(token);
        if (result['success'] == true && result['interests'] != null) {
          final List remoteInterests = result['interests'];
          if (remoteInterests.isNotEmpty) {
            // Stocker les intérêts récupérés depuis le serveur dans le stockage local
            await saveLocalInterests(remoteInterests.cast<Map<String, dynamic>>());
            await setInterestsSelected(true);
            print('✅ Intérêts récupérés depuis le serveur: ${remoteInterests.length} trouvés et stockés localement');
          }
        }
      } catch (e) {
        print('❌ Erreur de récupération des intérêts depuis le serveur: $e');
      }
    }
  }

  // ========== DÉCONNEXION COMPLÈTE ==========
  Future<void> clearAll() async {
    await prefs.clear();
  }
}