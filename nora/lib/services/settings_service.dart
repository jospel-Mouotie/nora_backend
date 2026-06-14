import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  static final SettingsService _instance = SettingsService._internal();
  factory SettingsService() => _instance;
  SettingsService._internal();

  // Clés pour les préférences
  static const String _keyNotificationsEnabled = 'notifications_enabled';
  static const String _keyPushNotifications = 'push_notifications';
  static const String _keyEmailNotifications = 'email_notifications';
  static const String _keySmsNotifications = 'sms_notifications';
  static const String _keyOrderUpdates = 'order_updates';
  static const String _keyPromotions = 'promotions';
  static const String _keyDarkMode = 'dark_mode';
  static const String _keyLanguage = 'language';
  static const String _keyBiometricLogin = 'biometric_login';
  static const String _keyFirstLaunch = 'first_launch';

  Future<SharedPreferences> get _prefs async => await SharedPreferences.getInstance();

  // ==================== INITIALISATION ====================
  
  Future<void> initialize() async {
    final prefs = await _prefs;
    if (prefs.getBool(_keyFirstLaunch) == null) {
      // Premier lancement, définir les valeurs par défaut
      await prefs.setBool(_keyFirstLaunch, false);
      await prefs.setBool(_keyNotificationsEnabled, true);
      await prefs.setBool(_keyPushNotifications, true);
      await prefs.setBool(_keyEmailNotifications, true);
      await prefs.setBool(_keySmsNotifications, false);
      await prefs.setBool(_keyOrderUpdates, true);
      await prefs.setBool(_keyPromotions, true);
      await prefs.setBool(_keyDarkMode, false);
      await prefs.setString(_keyLanguage, 'fr');
      await prefs.setBool(_keyBiometricLogin, false);
    }
  }

  // ==================== NOTIFICATIONS ====================
  
  // Notifications générales
  Future<bool> areNotificationsEnabled() async {
    final prefs = await _prefs;
    return prefs.getBool(_keyNotificationsEnabled) ?? true;
  }

  Future<void> setNotificationsEnabled(bool enabled) async {
    final prefs = await _prefs;
    await prefs.setBool(_keyNotificationsEnabled, enabled);
  }

  // Notifications push
  Future<bool> arePushNotificationsEnabled() async {
    final prefs = await _prefs;
    return prefs.getBool(_keyPushNotifications) ?? true;
  }

  Future<void> setPushNotificationsEnabled(bool enabled) async {
    final prefs = await _prefs;
    await prefs.setBool(_keyPushNotifications, enabled);
  }

  // Notifications email
  Future<bool> areEmailNotificationsEnabled() async {
    final prefs = await _prefs;
    return prefs.getBool(_keyEmailNotifications) ?? true;
  }

  Future<void> setEmailNotificationsEnabled(bool enabled) async {
    final prefs = await _prefs;
    await prefs.setBool(_keyEmailNotifications, enabled);
  }

  // Notifications SMS
  Future<bool> areSmsNotificationsEnabled() async {
    final prefs = await _prefs;
    return prefs.getBool(_keySmsNotifications) ?? false;
  }

  Future<void> setSmsNotificationsEnabled(bool enabled) async {
    final prefs = await _prefs;
    await prefs.setBool(_keySmsNotifications, enabled);
  }

  // Mise à jour des commandes
  Future<bool> areOrderUpdatesEnabled() async {
    final prefs = await _prefs;
    return prefs.getBool(_keyOrderUpdates) ?? true;
  }

  Future<void> setOrderUpdatesEnabled(bool enabled) async {
    final prefs = await _prefs;
    await prefs.setBool(_keyOrderUpdates, enabled);
  }

  // Promotions
  Future<bool> arePromotionsEnabled() async {
    final prefs = await _prefs;
    return prefs.getBool(_keyPromotions) ?? true;
  }

  Future<void> setPromotionsEnabled(bool enabled) async {
    final prefs = await _prefs;
    await prefs.setBool(_keyPromotions, enabled);
  }

  // ==================== APPAREANCE ====================
  
  // Mode sombre
  Future<bool> isDarkModeEnabled() async {
    final prefs = await _prefs;
    return prefs.getBool(_keyDarkMode) ?? false;
  }

  Future<void> setDarkModeEnabled(bool enabled) async {
    final prefs = await _prefs;
    await prefs.setBool(_keyDarkMode, enabled);
  }

  // ==================== LANGUE ====================
  
  // Langue de l'application
  Future<String> getLanguage() async {
    final prefs = await _prefs;
    return prefs.getString(_keyLanguage) ?? 'fr';
  }

  Future<void> setLanguage(String languageCode) async {
    final prefs = await _prefs;
    await prefs.setString(_keyLanguage, languageCode);
  }

  // ==================== SÉCURITÉ ====================
  
  // Authentification biométrique
  Future<bool> isBiometricLoginEnabled() async {
    final prefs = await _prefs;
    return prefs.getBool(_keyBiometricLogin) ?? false;
  }

  Future<void> setBiometricLoginEnabled(bool enabled) async {
    final prefs = await _prefs;
    await prefs.setBool(_keyBiometricLogin, enabled);
  }

  // ==================== UTILITAIRES ====================
  
  // Récupérer tous les paramètres
  Future<Map<String, dynamic>> getAllSettings() async {
    final prefs = await _prefs;
    return {
      'notifications_enabled': prefs.getBool(_keyNotificationsEnabled) ?? true,
      'push_notifications': prefs.getBool(_keyPushNotifications) ?? true,
      'email_notifications': prefs.getBool(_keyEmailNotifications) ?? true,
      'sms_notifications': prefs.getBool(_keySmsNotifications) ?? false,
      'order_updates': prefs.getBool(_keyOrderUpdates) ?? true,
      'promotions': prefs.getBool(_keyPromotions) ?? true,
      'dark_mode': prefs.getBool(_keyDarkMode) ?? false,
      'language': prefs.getString(_keyLanguage) ?? 'fr',
      'biometric_login': prefs.getBool(_keyBiometricLogin) ?? false,
    };
  }

  // Réinitialiser tous les paramètres
  Future<void> resetAllSettings() async {
    final prefs = await _prefs;
    await prefs.remove(_keyNotificationsEnabled);
    await prefs.remove(_keyPushNotifications);
    await prefs.remove(_keyEmailNotifications);
    await prefs.remove(_keySmsNotifications);
    await prefs.remove(_keyOrderUpdates);
    await prefs.remove(_keyPromotions);
    await prefs.remove(_keyDarkMode);
    await prefs.remove(_keyLanguage);
    await prefs.remove(_keyBiometricLogin);
    
    // Remettre les valeurs par défaut
    await initialize();
  }

  // Exporter les paramètres (pour sauvegarde)
  Future<String> exportSettings() async {
    final settings = await getAllSettings();
    return settings.toString();
  }

  // Importer les paramètres (pour restauration)
  Future<void> importSettings(Map<String, dynamic> settings) async {
    final prefs = await _prefs;
    if (settings.containsKey('notifications_enabled')) {
      await prefs.setBool(_keyNotificationsEnabled, settings['notifications_enabled']);
    }
    if (settings.containsKey('push_notifications')) {
      await prefs.setBool(_keyPushNotifications, settings['push_notifications']);
    }
    if (settings.containsKey('email_notifications')) {
      await prefs.setBool(_keyEmailNotifications, settings['email_notifications']);
    }
    if (settings.containsKey('sms_notifications')) {
      await prefs.setBool(_keySmsNotifications, settings['sms_notifications']);
    }
    if (settings.containsKey('order_updates')) {
      await prefs.setBool(_keyOrderUpdates, settings['order_updates']);
    }
    if (settings.containsKey('promotions')) {
      await prefs.setBool(_keyPromotions, settings['promotions']);
    }
    if (settings.containsKey('dark_mode')) {
      await prefs.setBool(_keyDarkMode, settings['dark_mode']);
    }
    if (settings.containsKey('language')) {
      await prefs.setString(_keyLanguage, settings['language']);
    }
    if (settings.containsKey('biometric_login')) {
      await prefs.setBool(_keyBiometricLogin, settings['biometric_login']);
    }
  }
}