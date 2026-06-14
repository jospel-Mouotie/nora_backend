import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../config/app_colors.dart';
import '../../../utils/converters.dart';

class AdCard extends StatelessWidget {
  final Map<String, dynamic> ad;
  final VoidCallback onTap;
  final VoidCallback? onStart;
  final VoidCallback? onPause;
  final VoidCallback? onDelete;

  const AdCard({
    super.key,
    required this.ad,
    required this.onTap,
    this.onStart,
    this.onPause,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final title = toStringSafe(ad['title']);
    final description = toStringSafe(ad['description']);
    final type = toStringSafe(ad['type']);
    final position = toStringSafe(ad['position']);
    final status = toStringSafe(ad['status']);
    final imageUrl = ad['image_url'];
    final impressions = toIntSafe(ad['impressions_count']);
    final clicks = toIntSafe(ad['clicks_count']);
    final budget = toDoubleSafe(ad['budget']).toInt();
    final spent = toDoubleSafe(ad['spent_amount']).toInt();
    final isActive = status == 'active';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
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
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              child: imageUrl != null && imageUrl.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: imageUrl,
                      height: 120,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        height: 120,
                        color: AppColors.backgroundLight,
                        child: const Center(
                          child: CircularProgressIndicator(color: AppColors.primary),
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        height: 120,
                        color: AppColors.backgroundLight,
                        child: const Icon(Icons.image, size: 40),
                      ),
                    )
                  : Container(
                      height: 120,
                      color: AppColors.backgroundLight,
                      child: const Icon(Icons.image, size: 40),
                    ),
            ),
            
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Titre et statut
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: isActive
                              ? AppColors.success.withOpacity(0.1)
                              : AppColors.warning.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          isActive ? 'Active' : 'En pause',
                          style: TextStyle(
                            fontSize: 11,
                            color: isActive ? AppColors.success : AppColors.warning,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  
                  // Description
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  
                  // Type et position
                  Wrap(
                    spacing: 8,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          type == 'banner' ? 'Bannière' : type,
                          style: const TextStyle(fontSize: 10, color: AppColors.primary),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.info.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          position == 'top' ? 'Haut de page' : position,
                          style: const TextStyle(fontSize: 10, color: AppColors.info),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  
                  // Statistiques
                  Row(
                    children: [
                      _buildStatItem(Icons.visibility, '$impressions', 'Impressions'),
                      const SizedBox(width: 16),
                      _buildStatItem(Icons.touch_app, '$clicks', 'Clics'),
                      const SizedBox(width: 16),
                      _buildStatItem(
                        Icons.percent,
                        clicks > 0 ? '${((clicks / impressions) * 100).toStringAsFixed(1)}%' : '0%',
                        'CTR',
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  
                  // Budget
                  LinearProgressIndicator(
                    value: budget > 0 ? spent / budget : 0,
                    backgroundColor: AppColors.border,
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Budget: $spent / $budget FCFA',
                        style: const TextStyle(fontSize: 11, color: AppColors.textTertiary),
                      ),
                      Text(
                        '${(((budget - spent) / budget) * 100).toInt()}% restant',
                        style: const TextStyle(fontSize: 11, color: AppColors.success),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  
                  // Boutons d'action
                  Row(
                    children: [
                      if (isActive && onPause != null)
                        Expanded(
                          child: OutlinedButton(
                            onPressed: onPause,
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: AppColors.warning),
                              foregroundColor: AppColors.warning,
                            ),
                            child: const Text('Mettre en pause'),
                          ),
                        ),
                      if (!isActive && onStart != null)
                        Expanded(
                          child: ElevatedButton(
                            onPressed: onStart,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.success,
                            ),
                            child: const Text('Démarrer'),
                          ),
                        ),
                      const SizedBox(width: 8),
                      if (onDelete != null)
                        IconButton(
                          icon: const Icon(Icons.delete, color: AppColors.error),
                          onPressed: onDelete,
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

  Widget _buildStatItem(IconData icon, String value, String label) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppColors.textSecondary),
        const SizedBox(width: 4),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              label,
              style: const TextStyle(
                fontSize: 9,
                color: AppColors.textTertiary,
              ),
            ),
          ],
        ),
      ],
    );
  }
}