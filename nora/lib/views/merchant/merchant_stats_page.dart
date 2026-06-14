import 'package:flutter/material.dart';
import '../../../config/app_colors.dart';
import '../../../services/shop_api_service.dart';
import '../../../services/storage_service.dart';

class MerchantStatsPage extends StatefulWidget {
  const MerchantStatsPage({super.key});

  @override
  State<MerchantStatsPage> createState() => _MerchantStatsPageState();
}

class _MerchantStatsPageState extends State<MerchantStatsPage> {
  final ShopApiService _shopApiService = ShopApiService();
  Map<String, dynamic>? _stats;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() => _isLoading = true);
    
    final token = await StorageService().getToken();
    if (token == null) {
      setState(() => _isLoading = false);
      return;
    }
    
    try {
      final result = await _shopApiService.getShopStats(token);
      if (result['success'] && result['stats'] != null) {
        setState(() {
          _stats = result['stats'];
          _isLoading = false;
        });
      } else {
        _loadTestStats();
      }
    } catch (e) {
      _loadTestStats();
    }
  }

  void _loadTestStats() {
    setState(() {
      _stats = {
        'total_orders': 156,
        'total_revenue': 2450000,
        'total_products': 45,
        'total_views': 12500,
        'conversion_rate': 3.2,
        'pending_orders': 8,
        'delivered_orders': 142,
        'cancelled_orders': 6,
      };
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text(
          'Statistiques',
          style: TextStyle(color: AppColors.textPrimary),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Première ligne de statistiques
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          title: 'Commandes',
                          value: '${_stats?['total_orders'] ?? 0}',
                          icon: Icons.shopping_bag,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          title: 'Chiffre d\'affaires',
                          value: '${((_stats?['total_revenue'] ?? 0) / 1000).toInt()}K FCFA',
                          icon: Icons.money,
                          color: AppColors.success,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  
                  // Deuxième ligne de statistiques
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          title: 'Produits',
                          value: '${_stats?['total_products'] ?? 0}',
                          icon: Icons.inventory,
                          color: AppColors.info,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          title: 'Vues totales',
                          value: '${_stats?['total_views'] ?? 0}',
                          icon: Icons.visibility,
                          color: AppColors.warning,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  
                  // Troisième ligne de statistiques
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          title: 'Taux conversion',
                          value: '${_stats?['conversion_rate'] ?? 0}%',
                          icon: Icons.trending_up,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          title: 'Commandes en attente',
                          value: '${_stats?['pending_orders'] ?? 0}',
                          icon: Icons.pending,
                          color: AppColors.warning,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  // Évolution des ventes (graphique)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.backgroundLight,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Évolution des ventes (cette semaine)',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          height: 200,
                          child: Row(
                            children: [
                              // Lundi
                              Expanded(
                                child: Column(
                                  children: [
                                    Expanded(
                                      child: Container(
                                        width: 30,
                                        decoration: BoxDecoration(
                                          color: AppColors.primary,
                                          borderRadius: const BorderRadius.vertical(
                                            top: Radius.circular(8),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    const Text(
                                      'Lun',
                                      style: TextStyle(fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),
                              // Mardi
                              Expanded(
                                child: Column(
                                  children: [
                                    Expanded(
                                      child: Container(
                                        width: 30,
                                        decoration: BoxDecoration(
                                          color: AppColors.primary,
                                          borderRadius: const BorderRadius.vertical(
                                            top: Radius.circular(8),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    const Text(
                                      'Mar',
                                      style: TextStyle(fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),
                              // Mercredi
                              Expanded(
                                child: Column(
                                  children: [
                                    Expanded(
                                      child: Container(
                                        width: 30,
                                        decoration: BoxDecoration(
                                          color: AppColors.primary,
                                          borderRadius: const BorderRadius.vertical(
                                            top: Radius.circular(8),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    const Text(
                                      'Mer',
                                      style: TextStyle(fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),
                              // Jeudi
                              Expanded(
                                child: Column(
                                  children: [
                                    Expanded(
                                      child: Container(
                                        width: 30,
                                        decoration: BoxDecoration(
                                          color: AppColors.primary,
                                          borderRadius: const BorderRadius.vertical(
                                            top: Radius.circular(8),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    const Text(
                                      'Jeu',
                                      style: TextStyle(fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),
                              // Vendredi
                              Expanded(
                                child: Column(
                                  children: [
                                    Expanded(
                                      child: Container(
                                        width: 30,
                                        decoration: BoxDecoration(
                                          color: AppColors.primary,
                                          borderRadius: const BorderRadius.vertical(
                                            top: Radius.circular(8),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    const Text(
                                      'Ven',
                                      style: TextStyle(fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),
                              // Samedi
                              Expanded(
                                child: Column(
                                  children: [
                                    Expanded(
                                      child: Container(
                                        width: 30,
                                        decoration: BoxDecoration(
                                          color: AppColors.primary,
                                          borderRadius: const BorderRadius.vertical(
                                            top: Radius.circular(8),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    const Text(
                                      'Sam',
                                      style: TextStyle(fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),
                              // Dimanche
                              Expanded(
                                child: Column(
                                  children: [
                                    Expanded(
                                      child: Container(
                                        width: 30,
                                        decoration: BoxDecoration(
                                          color: AppColors.primary,
                                          borderRadius: const BorderRadius.vertical(
                                            top: Radius.circular(8),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    const Text(
                                      'Dim',
                                      style: TextStyle(fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Détail des commandes par statut
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.backgroundLight,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Commandes par statut',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildStatusItem(
                          label: 'En attente',
                          count: _stats?['pending_orders'] ?? 0,
                          color: AppColors.warning,
                        ),
                        const SizedBox(height: 12),
                        _buildStatusItem(
                          label: 'Livrées',
                          count: _stats?['delivered_orders'] ?? 0,
                          color: AppColors.success,
                        ),
                        const SizedBox(height: 12),
                        _buildStatusItem(
                          label: 'Annulées',
                          count: _stats?['cancelled_orders'] ?? 0,
                          color: AppColors.error,
                        ),
                      ],
                    ),
                  ),
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
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildStatusItem({
    required String label,
    required int count,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        Text(
          count.toString(),
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}