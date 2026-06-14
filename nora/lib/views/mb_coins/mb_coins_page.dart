import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../config/app_colors.dart';
import '../../../config/routes.dart';
import '../../../services/mb_coins_api_service.dart';
import '../../../services/storage_service.dart';
import '../../../widgets/mb_coins/coin_balance_card.dart';
import '../../../widgets/mb_coins/reward_card.dart';
import '../../../widgets/home/product_card.dart';
import '../../../services/product_api_service.dart';
import '../../../utils/converters.dart';

class MbCoinsPage extends StatefulWidget {
  const MbCoinsPage({super.key});

  @override
  State<MbCoinsPage> createState() => _MbCoinsPageState();
}

class _MbCoinsPageState extends State<MbCoinsPage> {
  final MbCoinsApiService _apiService = MbCoinsApiService();
  final ProductApiService _productApiService = ProductApiService();
  Map<String, dynamic>? _balance;
  List<dynamic> _rewards = [];
  List<dynamic> _recentTransactions = [];
  List<dynamic> _products = [];
  bool _isLoading = true;
  String? _token;
  bool _hasClaimedDailyBonus = false;
  bool _isClaimingBonus = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    _token = await StorageService().getToken();

    if (_token == null) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    try {
      await Future.wait([
        _loadBalance(),
        _loadRewards(),
        _loadRecentTransactions(),
        _checkDailyBonus(),
        _loadProducts(),
      ]);
    } catch (e) {
      print('Erreur chargement MB Coins: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadBalance() async {
    try {
      final result = await _apiService.getMbCoinsBalance(_token!);
      if (result['success'] && result['balance'] != null) {
        setState(() {
          _balance = result['balance'];
        });
      }
    } catch (e) {
      print('Erreur solde: $e');
    }
  }

  Future<void> _loadRewards() async {
    try {
      final result = await _apiService.getMbRewards(status: 'available');
      if (result['success'] && result['rewards'] != null) {
        setState(() {
          _rewards = result['rewards'];
        });
      }
    } catch (e) {
      print('Erreur récompenses: $e');
    }
  }

  Future<void> _loadRecentTransactions() async {
    try {
      final result = await _apiService.getMbCoinsTransactions(limit: 5, token: _token!);
      if (result['success'] && result['transactions'] != null) {
        setState(() {
          _recentTransactions = result['transactions'];
        });
      }
    } catch (e) {
      print('Erreur transactions: $e');
    }
  }

  Future<void> _loadProducts() async {
    try {
      final result = await _productApiService.getProducts(limit: 10);
      if (result['success'] && result['products'] != null) {
        if (mounted) {
          setState(() {
            _products = result['products'];
          });
        }
      }
    } catch (e) {
      print('Erreur produits: $e');
    }
  }

  Future<void> _checkDailyBonus() async {
    if (_token == null) return;

    try {
      final result = await _apiService.checkDailyBonus(_token!);
      if (result['success']) {
        setState(() {
          _hasClaimedDailyBonus = result['claimed'] ?? false;
        });
      }
    } catch (e) {
      print('Erreur vérification bonus quotidien: $e');
    }
  }

  Future<void> _claimDailyBonus() async {
    if (_token == null) {
      _showLoginRequired();
      return;
    }

    setState(() => _isClaimingBonus = true);

    try {
      final result = await _apiService.claimDailyBonus(_token!);
      if (result['success']) {
        _showSnackBar('Bonus quotidien réclamé: +${result['amount']} MB Coins !', isSuccess: true);
        setState(() => _hasClaimedDailyBonus = true);
        await _loadBalance();
        await _loadRecentTransactions();
      } else {
        _showSnackBar(result['message'] ?? 'Erreur lors de la réclamation');
      }
    } catch (e) {
      _showSnackBar('Erreur de connexion');
    } finally {
      setState(() => _isClaimingBonus = false);
    }
  }

  Future<void> _claimReward(int rewardId) async {
    if (_token == null) {
      _showLoginRequired();
      return;
    }

    try {
      final result = await _apiService.claimMbReward(rewardId, _token!);
      if (result['success']) {
        _showSnackBar('Récompense réclamée avec succès !', isSuccess: true);
        await _loadBalance();
        await _loadRewards();
      } else {
        _showSnackBar(result['message'] ?? 'Erreur lors du réclamation');
      }
    } catch (e) {
      _showSnackBar('Erreur de connexion');
    }
  }

  void _showLoginRequired() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Connexion requise'),
        content: const Text('Connectez-vous pour accéder à MB Coins'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              context.push(AppRoutes.login);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
            ),
            child: const Text('Se connecter'),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(String message, {bool isSuccess = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isSuccess ? AppColors.success : AppColors.error,
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
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'MB Coins',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.history, color: AppColors.textPrimary),
            onPressed: () {
              context.push('/mb-coins/transactions');
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : _token == null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.lock_outline, size: 64, color: AppColors.textTertiary),
                      const SizedBox(height: 16),
                      const Text(
                        'Connectez-vous pour voir vos MB Coins',
                        style: TextStyle(color: AppColors.textSecondary),
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
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      CoinBalanceCard(balance: _balance),

                      const SizedBox(height: 24),

                      // Bonus quotidien
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppColors.primary.withOpacity(0.1),
                              AppColors.primary.withOpacity(0.05),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                gradient: AppColors.primaryGradient,
                                borderRadius: BorderRadius.circular(25),
                              ),
                              child: const Icon(
                                Icons.card_giftcard,
                                color: Colors.white,
                                size: 28,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Bonus quotidien',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _hasClaimedDailyBonus
                                        ? 'Déjà réclamé aujourd\'hui'
                                        : 'Récupérez vos 10 MB Coins gratuits',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (!_hasClaimedDailyBonus)
                              ElevatedButton(
                                onPressed: _isClaimingBonus ? null : _claimDailyBonus,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                ),
                                child: _isClaimingBonus
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Text('Réclamer'),
                              ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Actions rapides
                      Row(
                        children: [
                          Expanded(
                            child: _buildActionCard(
                              icon: Icons.shopping_bag,
                              label: 'Boutique MB',
                              color: AppColors.primary,
                              onTap: () {
                                context.push(AppRoutes.mbShop);
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildActionCard(
                              icon: Icons.emoji_events,
                              label: 'Récompenses',
                              color: AppColors.warning,
                              onTap: () {
                                context.push('/mb-coins/rewards');
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildActionCard(
                              icon: Icons.history,
                              label: 'Historique',
                              color: AppColors.info,
                              onTap: () {
                                context.push('/mb-coins/transactions');
                              },
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Récompenses disponibles
                      if (_rewards.isNotEmpty) ...[
                        const Text(
                          'Récompenses disponibles',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _rewards.length > 3 ? 3 : _rewards.length,
                          itemBuilder: (context, index) {
                            final reward = _rewards[index];
                            return RewardCard(
                              reward: reward,
                              onClaim: () => _claimReward(reward['id']),
                            );
                          },
                        ),
                        if (_rewards.length > 3)
                          TextButton(
                            onPressed: () {
                              context.push('/mb-coins/rewards');
                            },
                            child: const Text('Voir toutes les récompenses'),
                          ),
                      ],

                      const SizedBox(height: 24),

                      // Produits achetable avec MB Coins
                      if (_products.isNotEmpty) ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Produits achetables en MB',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            Text(
                              '1 MB = 2 FCFA',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 16,
                            childAspectRatio: 0.72,
                          ),
                          itemCount: _products.length,
                          itemBuilder: (context, index) {
                            final product = _products[index];
                            return ProductCard(
                              product: product,
                              showMbCoinsPrice: true,
                              onTap: () {
                                context.push('${AppRoutes.productDetail}/${product['id']}');
                              },
                            );
                          },
                        ),
                      ],

                      const SizedBox(height: 24),

                      // Transactions récentes
                      if (_recentTransactions.isNotEmpty) ...[
                        const Text(
                          'Activité récente',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ..._recentTransactions.map((transaction) => _buildTransactionItem(transaction)),
                      ],
                    ],
                  ),
                ),
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionItem(Map<String, dynamic> transaction) {
    final amount = toDoubleSafe(transaction['amount']);
    final type = toStringSafe(transaction['type']);
    final description = toStringSafe(transaction['description']);
    final createdAt = toStringSafe(transaction['created_at']);
    final isCredit = type == 'credit';

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
              color: isCredit ? AppColors.success.withOpacity(0.1) : AppColors.error.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              isCredit ? Icons.arrow_upward : Icons.arrow_downward,
              color: isCredit ? AppColors.success : AppColors.error,
            ),
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
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _formatDate(createdAt),
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textTertiary,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${isCredit ? '+' : '-'} ${amount.toInt()} MB',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: isCredit ? AppColors.success : AppColors.error,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String dateTimeStr) {
    final dateTime = DateTime.tryParse(dateTimeStr);
    if (dateTime == null) return '';
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 7) {
      return '${difference.inDays ~/ 7} sem';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} j';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} h';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} min';
    } else {
      return 'à l\'instant';
    }
  }
}
