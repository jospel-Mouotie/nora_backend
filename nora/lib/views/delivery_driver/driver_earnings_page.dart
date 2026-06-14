import 'package:flutter/material.dart';
import '../../../config/app_colors.dart';
import '../../../services/api_service.dart';
import '../../../services/storage_service.dart';
import '../../../utils/converters.dart';

class DriverEarningsPage extends StatefulWidget {
  const DriverEarningsPage({super.key});

  @override
  State<DriverEarningsPage> createState() => _DriverEarningsPageState();
}

class _DriverEarningsPageState extends State<DriverEarningsPage> {
  final ApiService _apiService = ApiService();
  Map<String, dynamic>? _earnings;
  List<dynamic> _transactions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadEarnings();
  }

  Future<void> _loadEarnings() async {
    setState(() => _isLoading = true);
    
    final token = await StorageService().getToken();
    if (token == null) {
      setState(() => _isLoading = false);
      return;
    }
    
    try {
      final result = await _apiService.getDriverEarnings(token);
      if (result['success']) {
        setState(() {
          _earnings = result['earnings'];
          _transactions = result['transactions'] ?? [];
          _isLoading = false;
        });
      } else {
        _loadTestEarnings();
      }
    } catch (e) {
      _loadTestEarnings();
    }
  }

  void _loadTestEarnings() {
    setState(() {
      _earnings = {
        'total_earned': 125000,
        'this_week': 45000,
        'last_week': 38000,
        'pending': 15000,
      };
      _transactions = [
        {
          'date': '2026-05-16',
          'amount': 3500,
          'description': 'Livraison ORD-001',
          'status': 'completed',
        },
        {
          'date': '2026-05-15',
          'amount': 2000,
          'description': 'Livraison ORD-002',
          'status': 'completed',
        },
        {
          'date': '2026-05-14',
          'amount': 1500,
          'description': 'Livraison ORD-003',
          'status': 'completed',
        },
      ];
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
          'Mes gains',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.account_balance_wallet, color: AppColors.primary),
            onPressed: () {
              // TODO: Page de retrait
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Total des gains
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'Gain total',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white70,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${((_earnings?['total_earned'] ?? 0) / 1000).toInt()}K FCFA',
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Statistiques
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          title: 'Cette semaine',
                          value: '${((_earnings?['this_week'] ?? 0) / 1000).toInt()}K FCFA',
                          color: AppColors.success,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          title: 'Semaine dernière',
                          value: '${((_earnings?['last_week'] ?? 0) / 1000).toInt()}K FCFA',
                          color: AppColors.info,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildStatCard(
                    title: 'En attente',
                    value: '${((_earnings?['pending'] ?? 0) / 1000).toInt()}K FCFA',
                    color: AppColors.warning,
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Historique des transactions
                  const Text(
                    'Historique des gains',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _transactions.length,
                    itemBuilder: (context, index) {
                      final transaction = _transactions[index];
                      return _buildTransactionItem(transaction);
                    },
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
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

  Widget _buildTransactionItem(Map<String, dynamic> transaction) {
    final date = toStringSafe(transaction['date']);
    final amount = toIntSafe(transaction['amount']);
    final description = toStringSafe(transaction['description']);
    final status = toStringSafe(transaction['status']);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.money, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  date,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textTertiary,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '+$amount FCFA',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.success,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: status == 'completed'
                      ? AppColors.success.withOpacity(0.1)
                      : AppColors.warning.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  status == 'completed' ? 'Payé' : 'En attente',
                  style: TextStyle(
                    fontSize: 10,
                    color: status == 'completed' ? AppColors.success : AppColors.warning,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}