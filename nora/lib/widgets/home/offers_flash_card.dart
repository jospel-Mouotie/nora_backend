import 'package:flutter/material.dart'; 
import '../../../config/app_colors.dart';

class OffersFlashCard extends StatelessWidget {
  final Map<String, dynamic> product;
  final VoidCallback onTap;

  const OffersFlashCard({
    super.key,
    required this.product,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final price = product['price'] ?? 0;
    final originalPrice = product['original_price'] ?? product['compare_price'];
    final discount = product['discount'] ?? 
        ((originalPrice != null && originalPrice > price) 
            ? (((originalPrice - price) / originalPrice) * 100).toInt() 
            : null);
    final name = product['name'] ?? 'Produit';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 160,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            Stack(
              children: [
                Container(
                  height: 140,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppColors.backgroundLight,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                  ),
                  child: const Center(
                    child: Icon(Icons.image, size: 40, color: AppColors.textTertiary),
                  ),
                ),
                if (discount != null)
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
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Text(
                        '${price.toString().replaceAll('.0', '')} FCFA',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                      if (originalPrice != null && originalPrice > price)
                        Padding(
                          padding: const EdgeInsets.only(left: 6),
                          child: Text(
                            '${originalPrice.toString().replaceAll('.0', '')} FCFA',
                            style: TextStyle(
                              fontSize: 11,
                              decoration: TextDecoration.lineThrough,
                              color: AppColors.textTertiary,
                            ),
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