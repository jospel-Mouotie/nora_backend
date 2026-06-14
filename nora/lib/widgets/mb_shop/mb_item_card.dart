import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../config/app_colors.dart';
import '../../../utils/converters.dart';

class MbItemCard extends StatelessWidget {
  final Map<String, dynamic> item;
  final VoidCallback onTap;
  final int userBalance;

  const MbItemCard({
    super.key,
    required this.item,
    required this.onTap,
    required this.userBalance,
  });

  @override
  Widget build(BuildContext context) {
    final name = toStringSafe(item['name']);
    final price = toDoubleSafe(item['price_mb_coins']).toInt();
    final imageUrl = item['image_url'];
    final type = toStringSafe(item['type']);
    final isAvailable = item['is_available'] == true && userBalance >= price;
    final isDigital = type == 'digital';

    return GestureDetector(
      onTap: isAvailable ? onTap : null,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isAvailable ? AppColors.border : AppColors.border.withOpacity(0.5),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            Container(
              height: 120,
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.backgroundLight,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: imageUrl != null && imageUrl.isNotEmpty
                  ? ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                      child: CachedNetworkImage(
                        imageUrl: imageUrl,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        placeholder: (context, url) => const Center(
                          child: CircularProgressIndicator(color: AppColors.primary),
                        ),
                        errorWidget: (context, url, error) => Icon(
                          isDigital ? Icons.card_giftcard : Icons.shopping_bag,
                          size: 40,
                          color: AppColors.textTertiary,
                        ),
                      ),
                    )
                  : Center(
                      child: Icon(
                        isDigital ? Icons.card_giftcard : Icons.shopping_bag,
                        size: 40,
                        color: AppColors.textTertiary,
                      ),
                    ),
            ),
            
            // Badge type
            if (isDigital)
              Positioned(
                top: 8,
                left: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.info,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'Digital',
                    style: TextStyle(
                      fontSize: 9,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.monetization_on, size: 16, color: AppColors.primary),
                      const SizedBox(width: 4),
                      Text(
                        '$price MB',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (!isAvailable)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.error.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Center(
                        child: Text(
                          userBalance < price ? 'Solde insuffisant' : 'Indisponible',
                          style: const TextStyle(
                            fontSize: 10,
                            color: AppColors.error,
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