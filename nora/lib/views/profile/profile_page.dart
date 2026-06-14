import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../config/app_colors.dart';
import '../../../config/app_constants.dart';
import '../../../config/routes.dart';
import '../../../services/api_service.dart';
import '../../../services/storage_service.dart';
import '../../../utils/converters.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final ApiService _apiService = ApiService();
  
  Map<String, dynamic>? _user;
  bool _isLoading = true;
  bool _isRefreshing = false;
  String? _errorMessage;
  String? _token;
  
  Timer? _refreshTimer;

  String _getFullImageUrl(String? path) {
    if (path == null || path.isEmpty) return '';
    if (path.startsWith('http')) return path;
    if (path.startsWith('/storage')) {
      return '${AppConstants.apiBaseUrl.replaceAll('/api', '')}$path';
    }
    return '${AppConstants.apiBaseUrl.replaceAll('/api', '')}/storage/$path';
  }

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    _token = await StorageService().getToken();
    if (_token == null) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      return;
    }
    
    try {
      final result = await _apiService.getUserProfile(_token!);
      if (!mounted) return;
      
      if (result['success'] && result['user'] != null) {
        setState(() {
          _user = result['user'];
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = result['message'] ?? 'Erreur de chargement';
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Erreur chargement profil: $e');
      if (mounted) {
        setState(() {
          _errorMessage = 'Erreur de connexion';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _refreshProfile() async {
    if (_isRefreshing) return;
    
    setState(() => _isRefreshing = true);
    await _loadUserProfile();
    if (mounted) {
      setState(() => _isRefreshing = false);
    }
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return '';
    }
  }

  String _formatNumber(int number) {
    if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toString();
  }

  void _showFaqDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('FAQ - Foire aux questions'),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildFaqItem(
                  question: 'Comment passer une commande ?',
                  answer: 'Ajoutez des produits au panier, puis validez votre commande en renseignant votre adresse de livraison.',
                ),
                const SizedBox(height: 12),
                _buildFaqItem(
                  question: 'Quels sont les moyens de paiement ?',
                  answer: 'Nous acceptons le paiement à la livraison en espèces, Orange Money, MTN Mobile Money et virement bancaire.',
                ),
                const SizedBox(height: 12),
                _buildFaqItem(
                  question: 'Comment suivre ma livraison ?',
                  answer: 'Dans l\'onglet "Mes commandes", cliquez sur "Suivre" pour voir la position en direct de votre livreur.',
                ),
                const SizedBox(height: 12),
                _buildFaqItem(
                  question: 'Comment gagner des MB Coins ?',
                  answer: 'Regardez des vidéos, likez des commentaires, parrainez des amis ou achetez des produits pour gagner des MB Coins.',
                ),
                const SizedBox(height: 12),
                _buildFaqItem(
                  question: 'Comment contacter le service client ?',
                  answer: 'Utilisez le chat dans l\'onglet "Aide & Support" ou envoyez un email à support@nora.com.',
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  Widget _buildFaqItem({required String question, required String answer}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          question,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          answer,
          style: const TextStyle(
            fontSize: 13,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 400;
    final avatarSize = isSmallScreen ? 80.0 : 100.0;
    final titleFontSize = isSmallScreen ? 20.0 : 22.0;
    final statFontSize = isSmallScreen ? 14.0 : 16.0;

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
          'Mon profil',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: AppColors.textPrimary),
            onPressed: () {
              context.push(AppRoutes.settings);
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : _token == null || _user == null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.person_outline, size: 64, color: AppColors.textTertiary),
                      const SizedBox(height: 16),
                      Text(
                        _errorMessage ?? 'Connectez-vous pour voir votre profil',
                        style: const TextStyle(color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: () => context.push(AppRoutes.login),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                        ),
                        child: const Text('Se connecter'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _refreshProfile,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Column(
                      children: [
                        // Header avec photo de profil
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: isSmallScreen ? 20 : 24,
                          ),
                          decoration: BoxDecoration(
                            gradient: AppColors.primaryGradient,
                            borderRadius: const BorderRadius.only(
                              bottomLeft: Radius.circular(30),
                              bottomRight: Radius.circular(30),
                            ),
                          ),
                          child: Column(
                            children: [
                              // Avatar
                              GestureDetector(
                                onTap: () {
                                  context.push(AppRoutes.editProfile);
                                },
                                child: Container(
                                  width: avatarSize,
                                  height: avatarSize,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white, width: 3),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.2),
                                        blurRadius: 10,
                                        offset: const Offset(0, 5),
                                      ),
                                    ],
                                  ),
                                  child: ClipOval(
                                    child: _user!['profile_photo'] != null
                                        ? CachedNetworkImage(
                                            imageUrl: _getFullImageUrl(_user!['profile_photo']),
                                            fit: BoxFit.cover,
                                            placeholder: (context, url) => Container(
                                              color: Colors.white,
                                              child: const Icon(Icons.person, size: 40, color: AppColors.primary),
                                            ),
                                            errorWidget: (context, url, error) => Container(
                                              color: Colors.white,
                                              child: const Icon(Icons.person, size: 40, color: AppColors.primary),
                                            ),
                                          )
                                        : Container(
                                            color: Colors.white,
                                            child: const Icon(Icons.person, size: 40, color: AppColors.primary),
                                          ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              // Nom
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Flexible(
                                    child: Text(
                                      toStringSafe(_user!['name']),
                                      style: TextStyle(
                                        fontSize: titleFontSize,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (_user!['email_verified_at'] != null)
                                    const Padding(
                                      padding: EdgeInsets.only(left: 8),
                                      child: Icon(Icons.verified, size: 18, color: Colors.white),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              // Email
                              Text(
                                toStringSafe(_user!['email']),
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.white70,
                                ),
                              ),
                              const SizedBox(height: 8),
                              // Badge membre
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  'Membre depuis ${_formatDate(toStringSafe(_user!['created_at']))}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              // Bouton modifier
                              TextButton.icon(
                                onPressed: () {
                                  context.push(AppRoutes.editProfile);
                                },
                                icon: const Icon(Icons.edit, color: Colors.white, size: 18),
                                label: const Text(
                                  'Modifier mon profil',
                                  style: TextStyle(color: Colors.white),
                                ),
                                style: TextButton.styleFrom(
                                  backgroundColor: Colors.white.withOpacity(0.2),
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        // Corps
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              // Statistiques
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: AppColors.backgroundLight,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                                  children: [
                                    _buildStatItem(
                                      'Commandes',
                                      _user?['total_orders']?.toString() ?? '0',
                                      Icons.shopping_bag,
                                      statFontSize,
                                    ),
                                    _buildStatItem(
                                      'Dépenses',
                                      '${_user?['total_spent'] ?? 0} FCFA',
                                      Icons.money,
                                      statFontSize,
                                    ),
                                    _buildStatItem(
                                      'MB Coins',
                                      _user?['mb_coins']?.toString() ?? '0',
                                      Icons.monetization_on,
                                      statFontSize,
                                    ),
                                  ],
                                ),
                              ),
                              
                              const SizedBox(height: 16),
                              
                              // Menu
                              _buildMenuItem(
                                icon: Icons.history,
                                title: 'Mes commandes',
                                onTap: () {
                                  context.push(AppRoutes.orderHistory);
                                },
                              ),
                              _buildMenuItem(
                                icon: Icons.shopping_bag,
                                title: 'Mes achats MB',
                                onTap: () {
                                  context.push(AppRoutes.mbPurchases);
                                },
                              ),
                              _buildMenuItem(
                                icon: Icons.card_giftcard,
                                title: 'Mes récompenses',
                                onTap: () {
                                  context.push(AppRoutes.mbCoinsRewards);
                                },
                              ),
                              _buildMenuItem(
                                icon: Icons.help_outline,
                                title: 'FAQ',
                                onTap: _showFaqDialog,
                              ),
                              _buildMenuItem(
                                icon: Icons.info_outline,
                                title: 'À propos',
                                onTap: () {
                                  _showAboutDialog();
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, double fontSize) {
    return Column(
      children: [
        Icon(icon, size: 24, color: AppColors.primary),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? iconColor,
    bool isLogout = false,
  }) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: (iconColor ?? AppColors.primary).withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          color: iconColor ?? AppColors.primary,
          size: 22,
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: isLogout ? AppColors.error : AppColors.textPrimary,
        ),
      ),
      trailing: isLogout ? null : const Icon(Icons.chevron_right, color: AppColors.textTertiary),
      onTap: onTap,
    );
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('NORA Marketplace'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.shopping_bag, size: 50, color: AppColors.primary),
            const SizedBox(height: 16),
            const Text(
              'Version 1.0.0',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Achetez et vendez en toute simplicité',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            Text(
              '© 2026 NORA Marketplace\nTous droits réservés',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textTertiary,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }
}