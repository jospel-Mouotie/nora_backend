import 'package:flutter/material.dart';
import '../../../config/app_colors.dart';
import '../../../utils/converters.dart';

class ShopInfoCard extends StatelessWidget {
  final List<dynamic> badges;

  const ShopInfoCard({super.key, required this.badges});

  @override
  Widget build(BuildContext context) {
    if (badges.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.backgroundLight,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: badges.map((badge) {
            final icon = badge['icon'];
            final label = toStringSafe(badge['label']);
            
            return Column(
              children: [
                Icon(
                  icon is IconData ? icon : Icons.star,
                  size: 24,
                  color: AppColors.primary,
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}