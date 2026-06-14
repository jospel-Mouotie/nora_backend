import 'package:flutter/material.dart';
import '../../../config/app_colors.dart';
import '../../../utils/converters.dart';

class RewardCard extends StatelessWidget {
  final Map<String, dynamic> reward;
  final VoidCallback onClaim;

  const RewardCard({
    super.key,
    required this.reward,
    required this.onClaim,
  });

  @override
  Widget build(BuildContext context) {
    final title = toStringSafe(reward['title']);
    final description = toStringSafe(reward['description']);
    final amount = toDoubleSafe(reward['amount']);
    final isAvailable = reward['is_available'] ?? true;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.card_giftcard,
              size: 28,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '+${amount.toInt()} MB',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: isAvailable ? onClaim : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: isAvailable ? AppColors.primary : AppColors.border,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: Text(isAvailable ? 'Réclamer' : 'Réclamé'),
          ),
        ],
      ),
    );
  }
}