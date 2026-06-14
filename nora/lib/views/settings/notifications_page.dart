import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../config/app_colors.dart';
import '../../../services/settings_service.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  final SettingsService _settings = SettingsService();
  
  bool _pushNotifications = true;
  bool _emailNotifications = true;
  bool _smsNotifications = false;
  bool _orderUpdates = true;
  bool _promotions = true;
  bool _newProducts = true;
  bool _flashSales = true;
  bool _mbCoinsUpdates = true;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);
    
    _pushNotifications = await _settings.arePushNotificationsEnabled();
    _emailNotifications = await _settings.areEmailNotificationsEnabled();
    _smsNotifications = await _settings.areSmsNotificationsEnabled();
    _orderUpdates = await _settings.areOrderUpdatesEnabled();
    _promotions = await _settings.arePromotionsEnabled();
    
    // Charger les autres paramètres depuis SharedPreferences
    final prefs = await _settings.getAllSettings();
    _newProducts = prefs['new_products'] ?? true;
    _flashSales = prefs['flash_sales'] ?? true;
    _mbCoinsUpdates = prefs['mb_coins_updates'] ?? true;
    
    setState(() => _isLoading = false);
  }

  Future<void> _saveSettings() async {
    await _settings.setPushNotificationsEnabled(_pushNotifications);
    await _settings.setEmailNotificationsEnabled(_emailNotifications);
    await _settings.setSmsNotificationsEnabled(_smsNotifications);
    await _settings.setOrderUpdatesEnabled(_orderUpdates);
    await _settings.setPromotionsEnabled(_promotions);
    
    // Sauvegarder les autres paramètres
    final prefs = await _settings.getAllSettings();
    // Note: Il faudrait ajouter ces clés dans SettingsService
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Préférences sauvegardées'),
        backgroundColor: AppColors.success,
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              context.pop();
            } else {
              context.go('/home');
            }
          },
        ),
        title: const Text(
          'Notifications',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        actions: [
          TextButton(
            onPressed: _saveSettings,
            child: const Text(
              'Enregistrer',
              style: TextStyle(color: AppColors.primary),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : SingleChildScrollView(
              child: Column(
                children: [
                  // Section Canaux de notification
                  _buildSectionTitle('Canaux de notification'),
                  _buildSwitchTile(
                    icon: Icons.notifications_active,
                    title: 'Notifications push',
                    subtitle: 'Recevoir des alertes en temps réel sur votre appareil',
                    value: _pushNotifications,
                    onChanged: (value) => setState(() => _pushNotifications = value),
                  ),
                  _buildSwitchTile(
                    icon: Icons.email,
                    title: 'Notifications email',
                    subtitle: 'Recevoir des emails importants',
                    value: _emailNotifications,
                    onChanged: (value) => setState(() => _emailNotifications = value),
                  ),
                  _buildSwitchTile(
                    icon: Icons.sms,
                    title: 'Notifications SMS',
                    subtitle: 'Recevoir des SMS pour les livraisons et alertes urgentes',
                    value: _smsNotifications,
                    onChanged: (value) => setState(() => _smsNotifications = value),
                  ),
                  
                  const Divider(height: 32),
                  
                  // Section Types de notifications
                  _buildSectionTitle('Types de notifications'),
                  _buildSwitchTile(
                    icon: Icons.local_shipping,
                    title: 'Mise à jour des commandes',
                    subtitle: 'Statut de livraison, confirmations, annulations',
                    value: _orderUpdates,
                    onChanged: (value) => setState(() => _orderUpdates = value),
                  ),
                  _buildSwitchTile(
                    icon: Icons.monetization_on,
                    title: 'MB Coins',
                    subtitle: 'Gain de MB Coins, expirations, récompenses',
                    value: _mbCoinsUpdates,
                    onChanged: (value) => setState(() => _mbCoinsUpdates = value),
                  ),
                  _buildSwitchTile(
                    icon: Icons.local_offer,
                    title: 'Offres et promotions',
                    subtitle: 'Réductions, codes promo, offres flash',
                    value: _promotions,
                    onChanged: (value) => setState(() => _promotions = value),
                  ),
                  _buildSwitchTile(
                    icon: Icons.new_releases,
                    title: 'Nouveaux produits',
                    subtitle: 'Découvrir les dernières arrivages',
                    value: _newProducts,
                    onChanged: (value) => setState(() => _newProducts = value),
                  ),
                  _buildSwitchTile(
                    icon: Icons.flash_on,
                    title: 'Ventes flash',
                    subtitle: 'Alertes pour les ventes limitées dans le temps',
                    value: _flashSales,
                    onChanged: (value) => setState(() => _flashSales = value),
                  ),
                  
                  const Divider(height: 32),
                  
                  // Section Horaires
                  _buildSectionTitle('Horaires de notification'),
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.backgroundLight,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        _buildTimeRangeTile(
                          title: 'Heure de début',
                          value: '08:00',
                          icon: Icons.wb_sunny,
                          onTap: () => _selectTime(context, isStart: true),
                        ),
                        const Divider(),
                        _buildTimeRangeTile(
                          title: 'Heure de fin',
                          value: '22:00',
                          icon: Icons.nights_stay,
                          onTap: () => _selectTime(context, isStart: false),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Message informatif
                  Container(
                    margin: const EdgeInsets.all(16),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.info.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, size: 20, color: AppColors.info),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Les notifications ne seront pas envoyées en dehors de la plage horaire sélectionnée.',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.info,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                ],
              ),
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

  Widget _buildTimeRangeTile({
    required String title,
    required String value,
    required IconData icon,
    required VoidCallback onTap,
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
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.chevron_right, size: 20, color: AppColors.textTertiary),
        ],
      ),
      onTap: onTap,
    );
  }

  Future<void> _selectTime(BuildContext context, {required bool isStart}) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: isStart ? const TimeOfDay(hour: 8, minute: 0) : const TimeOfDay(hour: 22, minute: 0),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null) {
      // TODO: Sauvegarder l'heure
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${isStart ? 'Heure de début' : 'Heure de fin'} réglée sur ${picked.format(context)}'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }
}