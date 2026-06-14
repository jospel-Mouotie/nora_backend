import 'dart:convert';
import 'package:flutter/material.dart';
import '../../../config/app_colors.dart';
import '../../../config/app_constants.dart';

class CartItemCard extends StatelessWidget {
  final Map<String, dynamic> item;
  final Function(int) onQuantityChanged;
  final VoidCallback onRemove;
  final bool isUpdating;

  const CartItemCard({
    super.key,
    required this.item,
    required this.onQuantityChanged,
    required this.onRemove,
    this.isUpdating = false,
  });

  String _getImageUrl(dynamic imagesData) {
    if (imagesData == null) return '';
    try {
      List<dynamic> images = [];
      if (imagesData is String) {
        images = jsonDecode(imagesData);
      } else if (imagesData is List) {
        images = imagesData;
      }
      
      if (images.isNotEmpty && images.first.toString().isNotEmpty) {
        String path = images.first.toString();
        if (path.startsWith('http')) return path;
        final baseUrl = AppConstants.apiBaseUrl.replaceAll('/api', '');
        return '$baseUrl/storage/$path';
      }
    } catch (e) {
      print('Erreur parsing image: $e');
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final quantity = item['quantity'] as int;
    final price = item['price'] as int;
    final total = item['total_price'] ?? (price * quantity);
    final shopName = item['shop_name'] ?? item['shop']?['name'] ?? 'Boutique';
    final imageUrl = _getImageUrl(item['images']);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.background,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          // Header avec boutique
          Row(
            children: [
              Icon(Icons.store_outlined, size: 16, color: AppColors.textSecondary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  shopName,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              TextButton(
                onPressed: onRemove,
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(40, 32),
                ),
                child: const Text(
                  'Supprimer',
                  style: TextStyle(color: AppColors.error, fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Corps du produit
          Row(
            children: [
              // Image
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  color: AppColors.backgroundLight,
                  borderRadius: BorderRadius.circular(8),
                  image: imageUrl.isNotEmpty 
                      ? DecorationImage(
                          image: NetworkImage(imageUrl),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: imageUrl.isEmpty 
                    ? const Center(
                        child: Icon(Icons.image, size: 30, color: AppColors.textTertiary),
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              // Infos
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item['name'],
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${price.toString().replaceAll('.0', '')} FCFA',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Quantité
                    Row(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: AppColors.border),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            children: [
                              IconButton(
                                onPressed: isUpdating || quantity <= 1
                                    ? null
                                    : () => onQuantityChanged(quantity - 1),
                                icon: const Icon(Icons.remove, size: 16),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(minWidth: 32),
                              ),
                              SizedBox(
                                width: 32,
                                child: Center(
                                  child: isUpdating
                                      ? const SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: AppColors.primary,
                                          ),
                                        )
                                      : Text(
                                          quantity.toString(),
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                ),
                              ),
                              IconButton(
                                onPressed: isUpdating
                                    ? null
                                    : () => onQuantityChanged(quantity + 1),
                                icon: const Icon(Icons.add, size: 16),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(minWidth: 32),
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '= ${total.toString().replaceAll('.0', '')} FCFA',
                          style: const TextStyle(
                            fontSize: 14,
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
        ],
      ),
    );
  }
}