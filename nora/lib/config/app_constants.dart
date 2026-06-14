class AppConstants {
  // API - Avec le port 8000
  static const String apiBaseUrl = 'https://nora-backend-rlwn.onrender.com/api';
  //
  //                                            IP     Port

  // Storage Keys
  static const String storageToken = 'auth_token';
  static const String storageUser = 'user_data';
  static const String storageOnboardingCompleted = 'onboarding_completed';
  static const String storageInterestsSelected = 'interests_selected';

  // Autres
  static const int connectTimeout = 30000;
  static const int receiveTimeout = 30000;
}
