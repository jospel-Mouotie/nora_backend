import 'package:flutter/material.dart';
import '../../../config/app_colors.dart';
import '../../../widgets/merchant/merchant_sidebar.dart';
import '../../../services/shop_api_service.dart';
import '../../../services/storage_service.dart';
import 'merchant_shop_page.dart';
import 'merchant_products_page.dart';
import 'merchant_videos_page.dart';
import 'merchant_stats_page.dart';
import 'merchant_orders_page.dart';

class MerchantDashboardPage extends StatefulWidget {
  const MerchantDashboardPage({super.key});

  @override
  State<MerchantDashboardPage> createState() => _MerchantDashboardPageState();
}

class _MerchantDashboardPageState extends State<MerchantDashboardPage> {
  int _selectedIndex = 0;
  late PageController _pageController;

  final List<Widget> _pages = [
    const _DashboardHomePage(),
    const MerchantShopPage(),
    const MerchantProductsPage(),
    const MerchantVideosPage(),
    const MerchantOrdersPage(),
    const MerchantStatsPage(),
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
          MerchantSidebar(
            selectedIndex: _selectedIndex,
            onItemSelected: (index) {
              setState(() {
                _selectedIndex = index;
                _pageController.jumpToPage(index);
              });
            },
          ),
          Expanded(
            child: PageView(
              controller: _pageController,
              onPageChanged: (index) => setState(() => _selectedIndex = index),
              children: _pages,
            ),
          ),
        ],
      ),
    );
  }
}

class _DashboardHomePage extends StatefulWidget {
  const _DashboardHomePage();

  @override
  State<_DashboardHomePage> createState() => _DashboardHomePageState();
}

class _DashboardHomePageState extends State<_DashboardHomePage> {
  final ShopApiService _apiService = ShopApiService();
  List<dynamic> _shops = [];
  bool _isLoading = true;
  String? _token;

  @override
  void initState() {
    super.initState();
    _loadShops();
  }

  Future<void> _loadShops() async {
    setState(() => _isLoading = true);
    _token = await StorageService().getToken();
    if (_token == null) {
      setState(() => _isLoading = false);
      return;
    }
    try {
      final result = await _apiService.getMyShops(_token!);
      if (result['success'] && result['shops'] != null) {
        setState(() {
          _shops = result['shops'];
          _isLoading = false;
        });
      } else {
        setState(() {
          _shops = [];
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _shops = [];
        _isLoading = false;
      });
    }
  }

  Future<void> _requestCertification(int shopId) async {
    setState(() => _isLoading = true);
    try {
      final result = await _apiService.requestCertification(shopId, _token!);
      if (result['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Demande envoyée avec succès'), backgroundColor: AppColors.success),
        );
        await _loadShops();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'] ?? 'Erreur'), backgroundColor: AppColors.error),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erreur de connexion'), backgroundColor: AppColors.error),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showCertificationBenefitsDialog(Map<String, dynamic> shop) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.verified, color: AppColors.primary, size: 28),
            SizedBox(width: 10),
            Text('Devenir certifié', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'La certification Nora offre de nombreux avantages pour booster les ventes de votre boutique :',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 16),
            _buildBenefitItem(Icons.trending_up, 'Plus de visibilité', 'Votre boutique est mise en avant dans les recherches.'),
            _buildBenefitItem(Icons.verified, 'Badge de confiance', 'Rassurez vos clients avec le badge de certification vert.'),
            _buildBenefitItem(Icons.card_giftcard, 'Offres exclusives', 'Accédez à des campagnes de promotion exclusives.'),
            _buildBenefitItem(Icons.support_agent, 'Support 24/7', 'Un conseiller dédié pour répondre à vos besoins.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Plus tard', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _requestCertification(shop['id']);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
            child: const Text('Se certifier maintenant'),
          ),
        ],
      ),
    );
  }

  Widget _buildBenefitItem(IconData icon, String title, String desc) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.primary, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                Text(desc, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              ],
            ),
          ),
        ],
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
        title: const Text('Tableau de bord', style: TextStyle(color: AppColors.textPrimary)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _shops.isEmpty
              ? const Center(child: Text('Aucune boutique. Allez dans "Mes boutiques" pour en créer une.'))
              : RefreshIndicator(
                  onRefresh: _loadShops,
                  color: AppColors.primary,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _shops.length,
                    itemBuilder: (context, index) {
                      final shop = _shops[index];
                      String statusText = 'Inconnu';
                      Color statusColor = AppColors.textTertiary;
                      if (shop['status'] == 'en_attente') {
                        statusText = 'En attente de validation';
                        statusColor = Colors.orange;
                      } else if (shop['status'] == 'active') {
                        statusText = 'Active';
                        statusColor = AppColors.success;
                      } else if (shop['status'] == 'refusee') {
                        statusText = 'Refusée';
                        statusColor = AppColors.error;
                      }

                      return Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        elevation: 2,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 50,
                                    height: 50,
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withOpacity(0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.store, color: AppColors.primary),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(shop['name'] ?? 'Boutique sans nom', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                        Text(statusText, style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.w500)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Icon(
                                    shop['certifiee'] == true
                                        ? Icons.verified
                                        : (shop['has_pending_certification'] == true
                                            ? Icons.hourglass_empty
                                            : Icons.new_releases),
                                    color: shop['certifiee'] == true
                                        ? AppColors.primary
                                        : (shop['has_pending_certification'] == true
                                            ? Colors.orange
                                            : AppColors.textSecondary),
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      shop['certifiee'] == true
                                          ? 'Certifiée'
                                          : (shop['has_pending_certification'] == true
                                              ? 'Certification en attente...'
                                              : 'Non certifiée'),
                                      style: const TextStyle(fontWeight: FontWeight.w500),
                                    ),
                                  ),
                                ],
                              ),
                              if (shop['certifiee'] != true && shop['has_pending_certification'] != true) ...[
                                const SizedBox(height: 12),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    onPressed: () => _showCertificationBenefitsDialog(shop),
                                    icon: const Icon(Icons.verified, size: 18),
                                    label: const Text('Demander la certification'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.primary,
                                      foregroundColor: Colors.white,
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}

class _SettingsPage extends StatelessWidget {
  const _SettingsPage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text('Paramètres', style: TextStyle(color: AppColors.textPrimary)),
      ),
      body: const Center(child: Text('Paramètres commerçant - À venir')),
    );
  }
}