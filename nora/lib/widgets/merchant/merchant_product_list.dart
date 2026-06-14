import 'package:flutter/material.dart';
import '../../../config/app_colors.dart';
import '../../../utils/converters.dart';

class MerchantProductCard extends StatelessWidget {
  final Map<String, dynamic> product;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const MerchantProductCard({
    super.key,
    required this.product,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final name = toStringSafe(product['name']);
    final price = toDoubleSafe(product['price']).toInt();
    final stock = toIntSafe(product['stock']);
    final isActive = product['is_active'] == true;
    final images = product['images'];
    final imageUrl = images != null && images.isNotEmpty
        ? images[0].toString()
        : null;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          // Image
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.backgroundLight,
              borderRadius: BorderRadius.circular(8),
            ),
            child: imageUrl != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.image,
                        size: 30,
                        color: AppColors.textTertiary,
                      ),
                    ),
                  )
                : const Icon(
                    Icons.image,
                    size: 30,
                    color: AppColors.textTertiary,
                  ),
          ),
          const SizedBox(width: 12),
          // Infos
          Expanded(
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
                const SizedBox(height: 4),
                Text(
                  '$price FCFA',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.inventory,
                      size: 14,
                      color: stock > 0 ? AppColors.success : AppColors.error,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Stock: $stock',
                      style: TextStyle(
                        fontSize: 11,
                        color: stock > 0 ? AppColors.success : AppColors.error,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isActive ? AppColors.success : AppColors.error,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isActive ? 'Actif' : 'Inactif',
                      style: TextStyle(
                        fontSize: 11,
                        color: isActive ? AppColors.success : AppColors.error,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Actions
          Column(
            children: [
              IconButton(
                icon: const Icon(Icons.edit, color: AppColors.primary),
                onPressed: onEdit,
              ),
              IconButton(
                icon: const Icon(Icons.delete, color: AppColors.error),
                onPressed: onDelete,
              ),
            ],
          ),
        ],
      ),
    );
  }
}