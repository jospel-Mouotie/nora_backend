import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../config/app_colors.dart';
import '../../../config/routes.dart';  // ← AJOUTER CET IMPORT
import '../../../services/api_service.dart';
import '../../../services/storage_service.dart';
import '../../../widgets/mb_coins/reward_card.dart';

class RewardsPage extends StatefulWidget {
  const RewardsPage({super.key});

  @override
  State<RewardsPage> createState() => _RewardsPageState();
}

class _RewardsPageState extends State<RewardsPage> {
  final ApiService _apiService = ApiService();
  List<dynamic> _rewards = [];
  bool _isLoading = true;
  String? _token;

  @override
  void initState() {
    super.initState();
    _loadRewards();
  }

  Future<void> _loadRewards() async {
    setState(() => _isLoading = true);
    
    _token = await StorageService().getToken();
    if (_token == null) {
      setState(() => _isLoading = false);
      return;
    }
    
    try {
      final result = await _apiService.getMbRewards(status: 'available');
      if (result['success'] && result['rewards'] != null) {
        setState(() {
          _rewards = result['rewards'];
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      print('Erreur chargement récompenses: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _claimReward(int rewardId) async {
    if (_token == null) return;

    try {
      final result = await _apiService.claimMbReward(rewardId, _token!);
      if (result['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Récompense réclamée avec succès !'),
            backgroundColor: AppColors.success,
          ),
        );
        await _loadRewards();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Erreur lors du réclamation'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Erreur de connexion'),
          backgroundColor: AppColors.error,
        ),
      );
    }
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
          'Récompenses MB',
          style: TextStyle(color: AppColors.textPrimary),
        ),
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
                        'Connectez-vous pour voir vos récompenses',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: () => context.go(AppRoutes.login),  // ← Maintenant reconnu
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                        ),
                        child: const Text('Se connecter'),
                      ),
                    ],
                  ),
                )
              : _rewards.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.card_giftcard, size: 64, color: AppColors.textTertiary),
                          SizedBox(height: 16),
                          Text('Aucune récompense disponible'),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _rewards.length,
                      itemBuilder: (context, index) {
                        final reward = _rewards[index];
                        return RewardCard(
                          reward: reward,
                          onClaim: () => _claimReward(reward['id']),
                        );
                      },
                    ),
    );
  }
}