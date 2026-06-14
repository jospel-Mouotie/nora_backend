import 'package:flutter/material.dart';

class AppColors {
  // ========== COULEURS PRINCIPALES (DU LOGO) ==========
  /// Vert principal - #1B5E20
  static const Color primary = Color(0xFF1B5E20);

  /// Vert principal foncé
  static const Color primaryDark = Color(0xFF1B5E20);

  /// Vert principal clair
  static const Color primaryLight = Color(0xFF4CAF50);

  /// Vert secondaire - #2E7D32
  static const Color secondary = Color(0xFF2E7D32);

  /// Vert secondaire foncé
  static const Color secondaryDark = Color(0xFF2E7D32);

  /// Vert secondaire clair
  static const Color secondaryLight = Color(0xFF81C784);

  /// Orange d'accentuation - #F57C00
  static const Color accent = Color(0xFFF57C00);

  /// Vert succès
  static const Color success = Color(0xFF4CAF50);

  /// Rouge danger/erreur
  static const Color danger = Color(0xFFEF4444);

  /// Rouge erreur (alias)
  static const Color error = Color(0xFFF44336);

  /// Rouge pour les pourcentages de promo
  static const Color promotion = Color(0xFFEF4444);

  /// Orange d'avertissement
  static const Color warning = Color(0xFFFF9800);

  /// Bleu d'information
  static const Color info = Color(0xFF2196F3);

  // ========== COULEURS DE FOND ==========
  /// Fond blanc principal (mode clair)
  static const Color background = Color(0xFFFFFFFF);

  /// Fond gris clair pour sections (mode clair)
  static const Color backgroundLight = Color(0xFFF5F5F5);

  /// Fond sombre principal (mode sombre)
  static const Color backgroundDark = Color(0xFF121212);

  /// Fond sombre secondaire (mode sombre)
  static const Color backgroundDarkLight = Color(0xFF1E1E1E);

  /// Bordure grise (mode clair)
  static const Color border = Color(0xFFE0E0E0);

  /// Bordure sombre (mode sombre)
  static const Color borderDark = Color(0xFF2D2D2D);

  // ========== COULEURS DE TEXTE ==========
  /// Texte principal - gris foncé (mode clair)
  static const Color textPrimary = Color(0xFF212121);

  /// Texte principal - blanc (mode sombre)
  static const Color textPrimaryDark = Color(0xFFFFFFFF);

  /// Texte secondaire - gris moyen (mode clair)
  static const Color textSecondary = Color(0xFF757575);

  /// Texte secondaire - gris clair (mode sombre)
  static const Color textSecondaryDark = Color(0xFFBDBDBD);

  /// Texte tertiaire - gris clair (mode clair)
  static const Color textTertiary = Color(0xFFBDBDBD);

  /// Texte tertiaire - gris foncé (mode sombre)
  static const Color textTertiaryDark = Color(0xFF757575);

  /// Texte désactivé (mode clair)
  static const Color textDisabled = Color(0xFFE0E0E0);

  /// Texte désactivé (mode sombre)
  static const Color textDisabledDark = Color(0xFF424242);

  // ========== COULEURS D'ÉTOILES ==========
  /// Jaune pour les étoiles de notation
  static const Color starYellow = Color(0xFFFFC107);

  // ========== STATUTS ==========
  static const Color statusSuccess = Color(0xFF4CAF50);
  static const Color statusWarning = Color(0xFFFF9800);
  static const Color statusInfo = Color(0xFF2196F3);
  static const Color statusError = Color(0xFFF44336);

  // ========== GRADIENTS ==========
  // ========== GRADIENTS PREMIUM ==========
  /// Dégradé principal (vert foncé → vert émeraude)
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF1B5E20), Color(0xFF10B981)], // Vert foncé vers Vert émeraude (plus moderne)
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Dégradé secondaire (vert secondaire → orange)
  static const LinearGradient secondaryGradient = LinearGradient(
    colors: [Color(0xFF2E7D32), Color(0xFFF57C00)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Dégradé mixte (vert → orange)
  static const LinearGradient mixedGradient = LinearGradient(
    colors: [Color(0xFF1B5E20), Color(0xFFF57C00)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Dégradé pour les promotions (rouge → orange)
  static const LinearGradient promotionGradient = LinearGradient(
    colors: [Color(0xFFEF4444), Color(0xFFF97316)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Dégradé pour le fond (vert → vert clair)
static const LinearGradient gradient = LinearGradient(
  colors: [Color(0xFF1B5E20), Color(0xFF4CAF50)],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);
  // ========== OMBRES ==========
  // ========== OMBRES DOUCES (SOFT UI / GLASSMORPHISM) ==========
  static List<BoxShadow> get cardShadow => [
    BoxShadow(
      color: Colors.black.withOpacity(0.04),
      blurRadius: 24,
      spreadRadius: 0,
      offset: const Offset(0, 8),
    ),
  ];

  static List<BoxShadow> get buttonShadow => [
    BoxShadow(
      color: primary.withOpacity(0.25),
      blurRadius: 16,
      spreadRadius: 2,
      offset: const Offset(0, 6),
    ),
  ];

  // ========== MÉTHODES UTILITAIRES ==========
  static Color darken(Color color, [double amount = 0.1]) {
    final hsl = HSLColor.fromColor(color);
    final hslDark = hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0));
    return hslDark.toColor();
  }

  static Color lighten(Color color, [double amount = 0.1]) {
    final hsl = HSLColor.fromColor(color);
    final hslLight = hsl.withLightness((hsl.lightness + amount).clamp(0.0, 1.0));
    return hslLight.toColor();
  }
}
