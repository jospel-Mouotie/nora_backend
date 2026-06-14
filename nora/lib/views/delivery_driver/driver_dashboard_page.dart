import 'package:flutter/material.dart';
import '../../../config/app_colors.dart';
import '../../../services/api_service.dart';
import '../../../services/storage_service.dart';
import '../../../widgets/delivery_driver/driver_sidebar.dart';
import 'driver_missions_page.dart';
import 'driver_earnings_page.dart';

class DriverDashboardPage extends StatefulWidget {
  const DriverDashboardPage({super.key});

  @override
  State<DriverDashboardPage> createState() => _DriverDashboardPageState();
}

class _DriverDashboardPageState extends State<DriverDashboardPage> {
  int _selectedIndex = 0;
  late PageController _pageController;
  
  List<dynamic> _currentMissions = [];
  Map<String, dynamic>? _stats;
  bool _isLoading = true;

  final List<Widget> _pages = [
    const _DashboardHomePage(),
    const DriverMissionsPage(),
    const DriverEarningsPage(),
    const _HistoryPage(),
    const _SettingsPage(),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    final token = await StorageService().getToken();
    if (token != null) {
      try {
        final apiService = ApiService();
        final missionsResult = await apiService.getMyMissions(token);
        if (missionsResult['success']) {
          setState(() {
            _currentMissions = missionsResult['missions'] ?? [];
          });
        }
        
        final statsResult = await apiService.getDriverStats(token);
        if (statsResult['success']) {
          setState(() {
            _stats = statsResult['stats'];
          });
        }
      } catch (e) {
        print('Erreur chargement dashboard: $e');
        _loadTestData();
      }
    } else {
      _loadTestData();
    }
    
    setState(() => _isLoading = false);
  }

  void _loadTestData() {
    setState(() {
      _currentMissions = [
        {
          'id': 1,
          'order_number': 'ORD-001',
          'customer_name': 'Jean Dupont',
          'customer_address': 'Nkolbisson, Yaoundé',
          'distance': '3.2 km',
          'estimated_time': '14h30',
          'status': 'pending',
          'delivery_fee': 1500,
        },
        {
          'id': 2,
          'order_number': 'ORD-002',
          'customer_name': 'Marie Laurent',
          'customer_address': 'Mvog-Mbi, Yaoundé',
          'distance': '5.7 km',
          'estimated_time': '15h00',
          'status': 'pending',
          'delivery_fee': 2000,
        },
      ];
      _stats = {
        'total_deliveries': 42,
        'total_earnings': 125000,
        'rating': 4.8,
        'online_hours': 120,
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Row(
        children: [
          DriverSidebar(
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
}

// Page d'accueil du dashboard livreur
class _DashboardHomePage extends StatelessWidget {
  const _DashboardHomePage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text(
          'Tableau de bord',
          style: TextStyle(color: AppColors.textPrimary),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Statistiques
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    title: 'Livraisons',
                    value: '42',
                    icon: Icons.delivery_dining,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    title: 'Gains',
                    value: '125 000 FCFA',
                    icon: Icons.monetization_on,
                    color: AppColors.success,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    title: 'Note',
                    value: '4.8',
                    icon: Icons.star,
                    color: AppColors.warning,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    title: 'Heures en ligne',
                    value: '120h',
                    icon: Icons.access_time,
                    color: AppColors.info,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Missions en cours
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Missions en attente',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Voir tout >',
                  style: TextStyle(color: AppColors.primary),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // TODO: Afficher les missions
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, size: 28, color: color),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryPage extends StatelessWidget {
  const _HistoryPage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text(
          'Historique',
          style: TextStyle(color: AppColors.textPrimary),
        ),
      ),
      body: const Center(
        child: Text('Historique des livraisons - À venir'),
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
        title: const Text(
          'Paramètres',
          style: TextStyle(color: AppColors.textPrimary),
        ),
      ),
      body: const Center(
        child: Text('Paramètres livreur - À venir'),
      ),
    );
  }
}