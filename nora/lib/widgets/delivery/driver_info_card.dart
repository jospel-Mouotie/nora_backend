import 'package:flutter/material.dart';
import '../../../config/app_colors.dart';
import '../../../utils/converters.dart';

class DriverInfoCard extends StatelessWidget {
  final Map<String, dynamic> delivery;
  final VoidCallback onCall;
  final VoidCallback onChat;

  const DriverInfoCard({
    super.key,
    required this.delivery,
    required this.onCall,
    required this.onChat,
  });

  @override
  Widget build(BuildContext context) {
    final driver = delivery['driver'] ?? {};
    final driverName = toStringSafe(driver['name']);
    final driverPhone = toStringSafe(driver['phone']);
    final driverAvatar = driver['avatar'];
    final estimatedTime = toStringSafe(delivery['estimated_time']);
    final distance = toStringSafe(delivery['distance']);

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '🚚 Livreur assigné',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              // Avatar
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AppColors.primaryGradient,
                ),
                child: ClipOval(
                  child: driverAvatar != null
                      ? Image.network(
                          driverAvatar,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(
                            Icons.person,
                            color: Colors.white,
                            size: 30,
                          ),
                        )
                      : const Icon(
                          Icons.person,
                          color: Colors.white,
                          size: 30,
                        ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      driverName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.star, size: 14, color: AppColors.starYellow),
                        const SizedBox(width: 4),
                        Text(
                          '4.8 (128 avis)',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Boutons d'action
              Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.phone, color: AppColors.primary),
                      onPressed: onCall,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.chat, color: AppColors.primary),
                      onPressed: onChat,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(),
          const SizedBox(height: 12),
          // Infos livraison
          Row(
            children: [
              _buildInfoItem(
                icon: Icons.schedule,
                label: 'Livraison estimée',
                value: estimatedTime,
              ),
              const SizedBox(width: 16),
              _buildInfoItem(
                icon: Icons.location_on,
                label: 'Distance',
                value: distance,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Expanded(
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.textTertiary,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}