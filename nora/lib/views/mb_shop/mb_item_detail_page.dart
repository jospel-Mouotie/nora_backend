import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../config/app_colors.dart';
import '../../../config/routes.dart';
import '../../../services/shop_api_service.dart';
import '../../../services/mb_coins_api_service.dart';
import '../../../services/storage_service.dart';
import '../../../utils/converters.dart';

class MbItemDetailPage extends StatefulWidget {
  final int itemId;

  const MbItemDetailPage({super.key, required this.itemId});

  @override
  State<MbItemDetailPage> createState() => _MbItemDetailPageState();
}

class _MbItemDetailPageState extends State<MbItemDetailPage> {
  final ShopApiService _shopApiService = ShopApiService();
  final MbCoinsApiService _mbCoinsApiService = MbCoinsApiService();
  
  Map<String, dynamic>? _item;
  Map<String, dynamic>? _balance;
  bool _isLoading = true;
  bool _isPurchasing = false;
  String? _token;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    _token = await StorageService().getToken();
    
    try {
      await Future.wait([
        _loadItem(),
        _loadBalance(),
      ]);
    } catch (e) {
      print('Erreur chargement: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadItem() async {
    try {
      final result = await _shopApiService.getMbShopItem(widget.itemId);
      if (result['success'] && result['item'] != null) {
        setState(() {
          _item = result['item'];
        });
      } else {
        _loadTestItem();
      }
    } catch (e) {
      _loadTestItem();
    }
  }

  void _loadTestItem() {
    setState(() {
      _item = {
        'id': widget.itemId,
        'name': 'Badge Premium',
        'description': 'Obtenez un badge premium exclusif qui apparaîtra sur votre profil. Ce badge vous distingue des autres utilisateurs et montre votre engagement dans la communauté.',
        'price_mb_coins': 500,
        'type': 'digital',
        'category': 'badges',
        'image_url': null,
        'is_available': true,
        'features': [
          'Badge exclusif sur votre profil',
          'Accès à des contenus premium',
          'Support prioritaire',
        ],
      };
    });
  }

  Future<void> _loadBalance() async {
    if (_token == null) return;
    try {
      final result = await _mbCoinsApiService.getMbCoinsBalance(_token!);
      if (result['success'] && result['balance'] != null) {
        setState(() {
          _balance = result['balance'];
        });
      }
    } catch (e) {
      print('Erreur solde: $e');
    }
  }

  Future<void> _purchaseItem() async {
    if (_token == null) {
      _showLoginRequired();
      return;
    }

    setState(() => _isPurchasing = true);

    try {
      final result = await _shopApiService.purchaseMbItem(widget.itemId, _token!);
      
      if (result['success']) {
        _showSuccess('Achat réussi !');
        await _loadBalance();
        // Navigator pop pour revenir à la boutique
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) context.pop();
        });
      } else {
        _showError(result['message'] ?? 'Erreur lors de l\'achat');
      }
    } catch (e) {
      _showError('Erreur de connexion');
    } finally {
      setState(() => _isPurchasing = false);
    }
  }

  void _showLoginRequired() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Connexion requise'),
        content: const Text('Connectez-vous pour acheter cet article'),
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

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.success,
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _item == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    final item = _item!;
    final name = toStringSafe(item['name']);
    final description = toStringSafe(item['description']);
    final price = toDoubleSafe(item['price_mb_coins']).toInt();
    final imageUrl = item['image_url'];
    final features = item['features'] ?? [];
    final userBalance = toDoubleSafe(_balance?['balance']).toInt();
    final canAfford = userBalance >= price;

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
          'Détail article',
          style: TextStyle(color: AppColors.textPrimary),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            Container(
              height: 250,
              width: double.infinity,
              color: AppColors.backgroundLight,
              child: imageUrl != null && imageUrl.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: imageUrl,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      placeholder: (context, url) => const Center(
                        child: CircularProgressIndicator(color: AppColors.primary),
                      ),
                      errorWidget: (context, url, error) => Icon(
                        Icons.card_giftcard,
                        size: 80,
                        color: AppColors.textTertiary,
                      ),
                    )
                  : Icon(
                      Icons.card_giftcard,
                      size: 80,
                      color: AppColors.textTertiary,
                    ),
            ),
            
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Nom
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // Prix
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.monetization_on, color: Colors.white),
                        const SizedBox(width: 8),
                        Text(
                          '$price MB Coins',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Description
                  const Text(
                    'Description',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
                  ),
                  
                  if (features.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    const Text(
                      'Caractéristiques',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...features.map((feature) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Icon(Icons.check_circle, size: 20, color: AppColors.primary),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              feature,
                              style: const TextStyle(
                                fontSize: 14,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )).toList(),
                  ],
                  
                  const SizedBox(height: 32),
                  
                  // Solde utilisateur
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.backgroundLight,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Votre solde',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        Row(
                          children: [
                            const Icon(Icons.monetization_on, color: AppColors.primary),
                            const SizedBox(width: 4),
                            Text(
                              '$userBalance MB',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Bouton d'achat
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: (canAfford && !_isPurchasing) ? _purchaseItem : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: canAfford ? AppColors.primary : AppColors.border,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isPurchasing
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              canAfford ? 'Acheter pour $price MB' : 'Solde insuffisant',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}