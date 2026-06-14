import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeService extends ChangeNotifier {
  static final ThemeService _instance = ThemeService._internal();
  factory ThemeService() => _instance;
  ThemeService._internal();

  bool _isDarkMode = false;
  bool get isDarkMode => _isDarkMode;

  // Rendre les thèmes finaux (private static final)
  static final ThemeData _lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    primaryColor: const Color(0xFF4CAF50),
    scaffoldBackgroundColor: const Color(0xFFF5F5F5),
    colorScheme: const ColorScheme.light(
      primary: Color(0xFF4CAF50),
      secondary: Color(0xFF2196F3),
      surface: Color(0xFFFFFFFF),
      error: Color(0xFFE53935),
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: Color(0xFF212121),
      onError: Colors.white,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF4CAF50),
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: false,
    ),
    cardTheme: const CardThemeData(
      color: Colors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF4CAF50),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.grey.shade50,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFF4CAF50), width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFE53935), width: 1),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Colors.white,
      selectedItemColor: Color(0xFF4CAF50),
      unselectedItemColor: Colors.grey,
      type: BottomNavigationBarType.fixed,
      elevation: 8,
    ),
  );

  static final ThemeData _darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    primaryColor: const Color(0xFF4CAF50),
    scaffoldBackgroundColor: const Color(0xFF121212),
    colorScheme: const ColorScheme.dark(
      primary: Color(0xFF4CAF50),
      secondary: Color(0xFF2196F3),
      surface: Color(0xFF1E1E1E),
      error: Color(0xFFEF5350),
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: Color(0xFFE0E0E0),
      onError: Colors.white,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF1E1E1E),
      foregroundColor: Color(0xFF4CAF50),
      elevation: 0,
      centerTitle: false,
    ),
    cardTheme: const CardThemeData(
      color: Color(0xFF1E1E1E),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF4CAF50),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFF2C2C2C),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFF4CAF50), width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFEF5350), width: 1),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Color(0xFF1E1E1E),
      selectedItemColor: Color(0xFF4CAF50),
      unselectedItemColor: Colors.grey,
      type: BottomNavigationBarType.fixed,
      elevation: 8,
    ),
  );

  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool('is_dark_mode') ?? false;
    notifyListeners();
  }

  Future<void> toggleTheme() async {
    _isDarkMode = !_isDarkMode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_dark_mode', _isDarkMode);
    notifyListeners();
  }

  ThemeData getTheme() {
    return _isDarkMode ? _darkTheme : _lightTheme;
  }

  // Méthode utilitaire pour obtenir la couleur primaire
  Color get primaryColor => const Color(0xFF4CAF50);
  
  // Méthode utilitaire pour obtenir la couleur d'arrière-plan
  Color get backgroundColor => _isDarkMode ? const Color(0xFF121212) : const Color(0xFFF5F5F5);
  
  // Méthode utilitaire pour obtenir la couleur de surface
  Color get surfaceColor => _isDarkMode ? const Color(0xFF1E1E1E) : Colors.white;
}