import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../config/app_colors.dart';
import '../../config/app_constants.dart';
import '../../config/routes.dart';
import '../../services/ad_service.dart';
import '../../utils/converters.dart';

class PromotionsAllPage extends StatefulWidget {
  const PromotionsAllPage({super.key});

  @override
  State<PromotionsAllPage> createState() => _PromotionsAllPageState();
}

class _PromotionsAllPageState extends State<PromotionsAllPage> {
  final AdService _adService = AdService();
  List<dynamic> _products = [];
  bool _isLoading = true;
  String? _errorMessage;

  String _getFullImageUrl(String? path) {
    if (path == null || path.isEmpty) return '';
    if (path.startsWith('http')) return path;
    if (path.startsWith('/storage')) {
      return '${AppConstants.apiBaseUrl.replaceAll('/api', '')}$path';
    }
    return '${AppConstants.apiBaseUrl.replaceAll('/api', '')}/storage/$path';
  }

  String _getRemainingTime() {
    final now = DateTime.now();
    final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);
    final difference = endOfDay.difference(now);

    final hours = difference.inHours;
    final minutes = difference.inMinutes % 60;
    final seconds = difference.inSeconds % 60;

    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  void initState() {
    super.initState();
    _loadPromotions();
  }

  Future<void> _loadPromotions() async {
    setState(() => _isLoading = true);
    
    try {
      final result = await _adService.getPromotions();
      if (result['success'] && result['products'] != null) {
        setState(() {
          _products = result['products'];
          _isLoading = false;
        });
      } else {
        setState(() {
          _products = [];
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Erreur chargement promotions: $e');
      setState(() {
        _errorMessage = 'Erreur de connexion';
        _isLoading = false;
      });
    }
  }

  void _onProductTap(Map<String, dynamic> product) {
    final productId = product['id'];
    if (productId != null) {
      context.push('${AppRoutes.productDetail}/$productId');
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
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              context.pop();
            } else {
              context.go('/home');
            }
          },
        ),
        title: const Text(
          'Produits en promotion',
          style: TextStyle(color: AppColors.textPrimary),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 64, color: AppColors.error),
                      const SizedBox(height: 16),
                      Text(
                        _errorMessage!,
                        style: const TextStyle(color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: _loadPromotions,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                        ),
                        child: const Text('Réessayer'),
                      ),
                    ],
                  ),
                )
              : _products.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.local_offer_outlined, size: 64, color: AppColors.textTertiary),
                          const SizedBox(height: 16),
                          const Text(
                            'Aucune promotion disponible',
                            style: TextStyle(color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadPromotions,
                      child: Column(
                        children: [
                          // Timer
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            color: AppColors.promotion.withOpacity(0.1),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.timer, color: AppColors.promotion, size: 16),
                                const SizedBox(width: 8),
                                const Text(
                                  'Offres valables jusqu\'à minuit: ',
                                  style: TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 14,
                                  ),
                                ),
                                Text(
                                  _getRemainingTime(),
                                  style: const TextStyle(
                                    color: AppColors.promotion,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Grid de produits
                          Expanded(
                            child: GridView.builder(
                              padding: const EdgeInsets.all(16),
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                childAspectRatio: 0.75,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 12,
                              ),
                              itemCount: _products.length,
                              itemBuilder: (context, index) {
                                final product = _products[index];
                                return _buildPromotionCard(product);
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
    );
  }

  Widget _buildPromotionCard(Map<String, dynamic> product) {
    final images = product['images'];
    String imageUrl = '';
    if (images != null) {
      if (images is String && images.isNotEmpty) {
        imageUrl = images;
      } else if (images is List && images.isNotEmpty) {
        imageUrl = images[0].toString();
      }
    }

    final name = product['name'] ?? '';
    final price = toDoubleSafe(product['price']);
    final promotionPrice = toDoubleSafe(product['promotion_price']);
    final discount = promotionPrice > 0 ? ((price - promotionPrice) / price * 100).round() : 0;
    final shopName = product['shop']?['name'] ?? '';

    return GestureDetector(
      onTap: () => _onProductTap(product),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.promotion.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image avec badge promotion
            Stack(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                    child: imageUrl.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: _getFullImageUrl(imageUrl),
                            fit: BoxFit.cover,
                            width: double.infinity,
                            placeholder: (context, url) => Container(
                              color: AppColors.backgroundLight,
                              child: const Center(
                                child: CircularProgressIndicator(color: AppColors.primary),
                              ),
                            ),
                            errorWidget: (context, url, error) => Container(
                              color: AppColors.backgroundLight,
                              child: const Icon(Icons.image_not_supported, size: 40),
                            ),
                          )
                        : Container(
                            color: AppColors.backgroundLight,
                            child: const Icon(Icons.image, size: 40),
                          ),
                  ),
                ),
                if (discount > 0)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.promotion,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '-$discount%',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            // Info produit
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (shopName.isNotEmpty)
                    Text(
                      shopName,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  const SizedBox(height: 4),
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      if (promotionPrice > 0) ...[
                        Text(
                          '${promotionPrice.toStringAsFixed(0)} FCFA',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.promotion,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${price.toStringAsFixed(0)} FCFA',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textTertiary,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                      ] else
                        Text(
                          '${price.toStringAsFixed(0)} FCFA',
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
          ],
        ),
      ),
    );
  }
}
