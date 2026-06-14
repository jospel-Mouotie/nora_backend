import 'package:flutter/material.dart';
import '../../../config/app_colors.dart';

class CategoryChip extends StatelessWidget {
  final Map<String, dynamic> category;
  final VoidCallback onTap;
  final bool isMoreButton;

  const CategoryChip({
    super.key,
    required this.category,
    required this.onTap,
    this.isMoreButton = false,
  });

  const CategoryChip.more({super.key, required this.onTap})
      : category = const {'name': 'Voir plus'},
        isMoreButton = true;

  IconData _getIconForCategory(String name) {
    switch (name.toLowerCase()) {
      case 'mode': return Icons.checkroom;
      case 'électronique': return Icons.phone_android;
      case 'electronique': return Icons.phone_android;
      case 'maison': return Icons.home;
      case 'beauté': return Icons.spa;
      case 'beaute': return Icons.spa;
      case 'sports': return Icons.sports_soccer;
      default: return Icons.category;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.background,
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(30),
        ),
        child: Row(
          children: [
            if (!isMoreButton)
              Icon(
                _getIconForCategory(category['name']),
                size: 18,
                color: AppColors.textPrimary,
              )
            else
              const Icon(
                Icons.arrow_forward,
                size: 18,
                color: AppColors.textPrimary,
              ),
            const SizedBox(width: 8),
            Text(
              category['name'],
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}