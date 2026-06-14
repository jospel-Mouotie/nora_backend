import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../config/app_colors.dart';
import '../../../config/routes.dart';
import '../../../services/admin_api_service.dart';
import '../../../services/storage_service.dart';
import '../../../widgets/admin/admin_sidebar.dart';
import '../../../widgets/admin/admin_stats_card.dart';
import 'admin_users_page.dart';
import 'admin_shops_page.dart';
import 'admin_validations_page.dart';
import 'admin_categories_page.dart';
import 'admin_orders_page.dart';
import '../merchant/merchant_shop_page.dart';
import '../merchant/merchant_products_page.dart';
import '../merchant/merchant_videos_page.dart';
import '../merchant/merchant_stats_page.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  int _selectedIndex = 0;
  late PageController _pageController;

  final List<Widget> _pages = [
    const _AdminHomePage(),
    const MerchantShopPage(),
    const MerchantProductsPage(),
    const MerchantVideosPage(),
    const AdminOrdersPage(),
    const MerchantStatsPage(),
    const AdminUsersPage(),
    const AdminShopsPage(),
    const AdminValidationsPage(),
    const AdminCategoriesPage(),
    const _SettingsPage(),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Row(
        children: [
          AdminSidebar(
            selectedIndex: _selectedIndex,
            onItemSelected: (index) {
              if (index == 11) {
                _logout();
              } else if (index < _pages.length) {
                setState(() {
                  _selectedIndex = index;
                  _pageController.jumpToPage(index);
                });
              }
            },
          ),
          Expanded(
            child: PageView(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() => _selectedIndex = index);
              },
              children: _pages,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Déconnexion'),
        content: const Text('Voulez-vous vraiment vous déconnecter ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Se déconnecter'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final token = await StorageService().getToken();
    if (token != null) {
      await AdminApiService().logout(token);
    }
    await StorageService().clearAll();

    if (mounted) {
      context.go(AppRoutes.login);
    }
  }
}

// ===================================================================
// PAGE D'ACCUEIL DU DASHBOARD ADMIN - STATS DYNAMIQUES
// ===================================================================
class _AdminHomePage extends StatefulWidget {
  const _AdminHomePage();

  @override
  State<_AdminHomePage> createState() => _AdminHomePageState();
}

class _AdminHomePageState extends State<_AdminHomePage> {
  final AdminApiService _adminApiService = AdminApiService();
  Map<String, dynamic>? _stats;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final token = await StorageService().getToken();
    if (token == null) {
      setState(() {
        _isLoading = false;
        _error = 'Non authentifié';
      });
      return;
    }

    try {
      final result = await _adminApiService.getAdminStats(token);
      if (result['success'] && result['stats'] != null) {
        setState(() {
          _stats = result['stats'];
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
          _error = 'Impossible de charger les statistiques';
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = 'Erreur de connexion';
      });
    }
  }

  String _formatNumber(dynamic value) {
    if (value == null) return '0';
    final num n = value is num ? value : num.tryParse(value.toString()) ?? 0;
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return n.toStringAsFixed(0);
  }

  String _formatRevenue(dynamic value) {
    if (value == null) return '0 FCFA';
    final num n = value is num ? value : num.tryParse(value.toString()) ?? 0;
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M FCFA';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(0)}K FCFA';
    return '${n.toStringAsFixed(0)} FCFA';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text(
          'Tableau de bord',
          style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.primary),
            onPressed: _loadStats,
            tooltip: 'Actualiser',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadStats,
        color: AppColors.primary,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
            : _error != null
                ? _buildError()
                : _buildDashboard(),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: AppColors.error),
          const SizedBox(height: 16),
          Text(_error!, style: const TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _loadStats,
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('Réessayer'),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboard() {
    final s = _stats ?? {};

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ======= SECTION UTILISATEURS =======
          const _SectionTitle(title: '👥 Utilisateurs'),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: AdminStatsCard(
                  title: 'Total utilisateurs',
                  value: _formatNumber(s['total_users']),
                  icon: Icons.people,
                  color: AppColors.primary,
                  subtitle: '+${_formatNumber(s['new_users_period'])} ce mois',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AdminStatsCard(
                  title: 'Utilisateurs actifs',
                  value: _formatNumber(s['active_users']),
                  icon: Icons.person_pin,
                  color: AppColors.info,
                  subtitle: 'Ces 7 derniers jours',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ======= SECTION BOUTIQUES =======
          const _SectionTitle(title: '🏪 Boutiques'),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: AdminStatsCard(
                  title: 'Total boutiques',
                  value: _formatNumber(s['total_shops']),
                  icon: Icons.store,
                  color: AppColors.success,
                  subtitle: '${_formatNumber(s['active_shops'])} actives',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AdminStatsCard(
                  title: 'Certifiées',
                  value: _formatNumber(s['certified_shops']),
                  icon: Icons.verified,
                  color: const Color(0xFF2196F3),
                  subtitle: 'Badge vérification',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: AdminStatsCard(
                  title: 'En attente',
                  value: _formatNumber(s['pending_shops']),
                  icon: Icons.pending_actions,
                  color: AppColors.warning,
                  subtitle: 'À valider',
                  onTap: () => _navigateTo(AppRoutes.adminValidations),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AdminStatsCard(
                  title: 'Produits',
                  value: _formatNumber(s['total_products']),
                  icon: Icons.inventory_2,
                  color: const Color(0xFF9C27B0),
                  subtitle: 'Mis en vente',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ======= SECTION COMMANDES =======
          const _SectionTitle(title: '🛒 Commandes'),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: AdminStatsCard(
                  title: 'Total commandes',
                  value: _formatNumber(s['total_orders']),
                  icon: Icons.shopping_bag,
                  color: AppColors.info,
                  subtitle: '${_formatNumber(s['completed_orders'])} livrées',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AdminStatsCard(
                  title: 'En attente',
                  value: _formatNumber(s['pending_orders']),
                  icon: Icons.hourglass_top,
                  color: AppColors.warning,
                  subtitle: 'À traiter',
                  onTap: () => _navigateTo(AppRoutes.adminOrders),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: AdminStatsCard(
                  title: 'Chiffre d\'affaires',
                  value: _formatRevenue(s['total_revenue']),
                  icon: Icons.attach_money,
                  color: AppColors.success,
                  subtitle: _formatRevenue(s['revenue_period']) + ' ce mois',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AdminStatsCard(
                  title: 'Vidéos',
                  value: _formatNumber(s['total_videos']),
                  icon: Icons.video_library,
                  color: const Color(0xFFE91E63),
                  subtitle: 'Publiées',
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // ======= ACTIONS RAPIDES =======
          const _SectionTitle(title: '⚡ Actions rapides'),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _QuickActionButton(
                label: 'Valider boutiques',
                icon: Icons.store_mall_directory,
                color: AppColors.warning,
                badge: s['pending_shops'] != null && s['pending_shops'] > 0
                    ? '${s['pending_shops']}'
                    : null,
                onTap: () => _navigateTo(AppRoutes.adminValidations),
              ),
              _QuickActionButton(
                label: 'Gérer utilisateurs',
                icon: Icons.manage_accounts,
                color: AppColors.primary,
                onTap: () => _navigateTo(AppRoutes.adminUsers),
              ),
              _QuickActionButton(
                label: 'Voir commandes',
                icon: Icons.receipt_long,
                color: AppColors.info,
                badge: s['pending_orders'] != null && s['pending_orders'] > 0
                    ? '${s['pending_orders']}'
                    : null,
                onTap: () => _navigateTo(AppRoutes.adminOrders),
              ),
              _QuickActionButton(
                label: 'Catégories',
                icon: Icons.category,
                color: const Color(0xFF9C27B0),
                onTap: () => _navigateTo(AppRoutes.adminCategories),
              ),
            ],
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  void _navigateTo(String route) {
    context.push(route);
  }
}

// ===================================================================
// WIDGETS UTILITAIRES DU DASHBOARD
// ===================================================================

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimary,
      ),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final String? badge;
  final VoidCallback onTap;

  const _QuickActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 150,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Stack(
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: color, size: 32),
                const SizedBox(height: 8),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            if (badge != null)
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.error,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    badge!,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ===================================================================
// PAGE PARAMÈTRES ADMIN
// ===================================================================
class _SettingsPage extends StatelessWidget {
  const _SettingsPage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text(
          'Paramètres',
          style: TextStyle(color: AppColors.textPrimary),
        ),
      ),
      body: const Center(child: Text('Paramètres administrateur — À venir')),
    );
  }
}
