import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../config/app_colors.dart';
import '../../../config/routes.dart';
import '../../../services/shop_api_service.dart';
import '../../../services/storage_service.dart';
import '../../../utils/converters.dart';

class MbPurchasesPage extends StatefulWidget {
  const MbPurchasesPage({super.key});

  @override
  State<MbPurchasesPage> createState() => _MbPurchasesPageState();
}

class _MbPurchasesPageState extends State<MbPurchasesPage> {
  final ShopApiService _shopApiService = ShopApiService();
  List<dynamic> _purchases = [];
  bool _isLoading = true;
  String? _token;

  @override
  void initState() {
    super.initState();
    _loadPurchases();
  }

  Future<void> _loadPurchases() async {
    setState(() => _isLoading = true);
    
    _token = await StorageService().getToken();
    if (_token == null) {
      setState(() => _isLoading = false);
      return;
    }
    
    try {
      final result = await _shopApiService.getMbPurchases(_token!);
      if (result['success'] && result['purchases'] != null) {
        setState(() {
          _purchases = result['purchases'];
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      print('Erreur chargement achats: $e');
      setState(() => _isLoading = false);
    }
  }

  String _formatDate(String dateTimeStr) {
    final dateTime = DateTime.tryParse(dateTimeStr);
    if (dateTime == null) return '';
    return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
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
          'Mes achats',
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
                        'Connectez-vous pour voir vos achats',
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
              : _purchases.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.shopping_bag_outlined, size: 64, color: AppColors.textTertiary),
                          SizedBox(height: 16),
                          Text('Aucun achat effectué'),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _purchases.length,
                      itemBuilder: (context, index) {
                        final purchase = _purchases[index];
                        final item = purchase['item'];
                        final name = toStringSafe(item?['name']);
                        final price = toDoubleSafe(purchase['price_paid']).toInt();
                        final imageUrl = item?['image_url'];
                        final status = toStringSafe(purchase['status']);
                        final createdAt = toStringSafe(purchase['created_at']);
                        
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            border: Border.all(color: AppColors.border),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 60,
                                height: 60,
                                decoration: BoxDecoration(
                                  color: AppColors.backgroundLight,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: imageUrl != null && imageUrl.isNotEmpty
                                    ? ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: CachedNetworkImage(
                                          imageUrl: imageUrl,
                                          fit: BoxFit.cover,
                                          errorWidget: (context, url, error) => const Icon(
                                            Icons.card_giftcard,
                                            size: 30,
                                            color: AppColors.textTertiary,
                                          ),
                                        ),
                                      )
                                    : const Icon(
                                        Icons.card_giftcard,
                                        size: 30,
                                        color: AppColors.textTertiary,
                                      ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      name,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        const Icon(Icons.monetization_on, size: 14, color: AppColors.primary),
                                        const SizedBox(width: 4),
                                        Text(
                                          '$price MB',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: AppColors.primary,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
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
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: status == 'completed' 
                                      ? AppColors.success.withOpacity(0.1) 
                                      : AppColors.warning.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  status == 'completed' ? 'Livré' : 'En cours',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: status == 'completed' ? AppColors.success : AppColors.warning,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
    );
  }
}