import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../config/app_colors.dart';
import '../../../config/routes.dart';
import '../../../services/theme_service.dart';
import '../../../services/language_service.dart';
import '../../../services/storage_service.dart';
import '../../../services/api_service.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _notificationsEnabled = true;
  bool _biometricLogin = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    // Récupérer les préférences locales
    // Tu peux utiliser SettingsService ici
  }

  Future<void> _toggleDarkMode(bool value) async {
    final themeService = Provider.of<ThemeService>(context, listen: false);
    await themeService.toggleTheme();
    // Pas besoin de setState, le Consumer le fera automatiquement
  }

  Future<void> _changeLanguage(String languageCode) async {
    final languageService = Provider.of<LanguageService>(context, listen: false);
    final newLanguage = languageCode == 'en'
        ? AppLanguage.english
        : AppLanguage.french;
    await languageService.setLanguage(newLanguage);
    // Pas besoin de redémarrer, la langue change instantanément
  }

  Future<void> _toggleNotifications(bool value) async {
    setState(() => _notificationsEnabled = value);
    // Sauvegarder dans SettingsService
  }

  Future<void> _toggleBiometricLogin(bool value) async {
    setState(() => _biometricLogin = value);
    // Sauvegarder dans SettingsService
  }

  @override
  Widget build(BuildContext context) {
    final themeService = Provider.of<ThemeService>(context);
    final languageService = Provider.of<LanguageService>(context);
    final isDarkMode = themeService.isDarkMode;
    final currentLanguage = languageService.currentLanguageCode;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: Text(
          languageService.translate('settings'),
          style: TextStyle(color: AppColors.textPrimary),
        ),
      ),
      body: ListView(
        children: [
          // Section Apparence
          _buildSectionTitle(languageService.translate('appearance')),
          _buildSwitchTile(
            icon: Icons.dark_mode,
            title: languageService.translate('dark_mode_title'),
            subtitle: languageService.translate('dark_mode_subtitle'),
            value: isDarkMode,
            onChanged: _toggleDarkMode,
          ),

          // Section Langue
          _buildSectionTitle(languageService.translate('language_section')),
          _buildRadioTile(
            icon: Icons.language,
            title: languageService.translate('language_french'),
            subtitle: languageService.translate('language_french_subtitle'),
            value: 'fr',
            groupValue: currentLanguage,
            onChanged: _changeLanguage,
            trailing: const Text('🇫🇷', style: TextStyle(fontSize: 24)),
          ),
          _buildRadioTile(
            icon: Icons.language,
            title: languageService.translate('language_english'),
            subtitle: languageService.translate('language_english_subtitle'),
            value: 'en',
            groupValue: currentLanguage,
            onChanged: _changeLanguage,
            trailing: const Text('🇬🇧', style: TextStyle(fontSize: 24)),
          ),

          // Section Notifications
          _buildSectionTitle(languageService.translate('notifications_section')),
          _buildSwitchTile(
            icon: Icons.notifications,
            title: languageService.translate('notifications_title'),
            subtitle: languageService.translate('notifications_subtitle'),
            value: _notificationsEnabled,
            onChanged: _toggleNotifications,
          ),

          // Section Sécurité
          _buildSectionTitle(languageService.translate('security_section')),
          _buildSwitchTile(
            icon: Icons.fingerprint,
            title: languageService.translate('biometric_login'),
            subtitle: languageService.translate('biometric_login_subtitle'),
            value: _biometricLogin,
            onChanged: _toggleBiometricLogin,
          ),

          // Section À propos
          _buildSectionTitle(languageService.translate('about_section')),
          _buildNavigationTile(
            icon: Icons.info,
            title: languageService.translate('version_title'),
            subtitle: '1.0.0',
            onTap: () {},
            showArrow: false,
          ),
          _buildNavigationTile(
            icon: Icons.description,
            title: languageService.translate('terms_title'),
            onTap: () => _showTermsDialog(),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppColors.primary,
        ),
      ),
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: AppColors.primary, size: 22),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: AppColors.primary,
      ),
      onTap: () => onChanged(!value),
    );
  }

  Widget _buildRadioTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required String value,
    required String groupValue,
    required Function(String) onChanged,
    Widget? trailing,
  }) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: AppColors.primary, size: 22),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
      trailing: trailing ?? Radio<String>(
        value: value,
        groupValue: groupValue,
        onChanged: (v) => onChanged(v!),
        activeColor: AppColors.primary,
      ),
      onTap: () => onChanged(value),
    );
  }

  Widget _buildNavigationTile({
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
    bool showArrow = true,
  }) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: AppColors.primary, size: 22),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      subtitle: subtitle != null ? Text(subtitle, style: const TextStyle(fontSize: 12)) : null,
      trailing: showArrow ? Icon(Icons.chevron_right, color: AppColors.textTertiary) : null,
      onTap: onTap,
    );
  }

  void _showTermsDialog() {
    final languageService = Provider.of<LanguageService>(context, listen: false);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(languageService.translate('terms_dialog_title')),
        content: SingleChildScrollView(
          child: Text(languageService.translate('terms_dialog_content')),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(languageService.translate('close')),
          ),
        ],
      ),
    );
  }
}
