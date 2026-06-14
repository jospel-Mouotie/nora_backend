import 'package:flutter/material.dart';
import '../../../config/app_colors.dart';
import '../../../utils/converters.dart';

class MissionCard extends StatelessWidget {
  final Map<String, dynamic> mission;
  final VoidCallback? onAccept;
  final VoidCallback? onComplete;
  final VoidCallback? onTrack;

  const MissionCard({
    super.key,
    required this.mission,
    this.onAccept,
    this.onComplete,
    this.onTrack,
  });

  @override
  Widget build(BuildContext context) {
    final orderNumber = toStringSafe(mission['order_number']);
    final customerName = toStringSafe(mission['customer_name']);
    final customerAddress = toStringSafe(mission['customer_address']);
    final distance = toStringSafe(mission['distance']);
    final estimatedTime = toStringSafe(mission['estimated_time']);
    final deliveryFee = toIntSafe(mission['delivery_fee']);
    final status = toStringSafe(mission['status']);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                orderNumber,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getStatusColor(status).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  _getStatusLabel(status),
                  style: TextStyle(
                    fontSize: 11,
                    color: _getStatusColor(status),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Client
          Row(
            children: [
              const Icon(Icons.person, size: 16, color: AppColors.textSecondary),
              const SizedBox(width: 8),
              Text(
                customerName,
                style: const TextStyle(color: AppColors.textPrimary),
              ),
            ],
          ),
          const SizedBox(height: 8),
          
          // Adresse
          Row(
            children: [
              const Icon(Icons.location_on, size: 16, color: AppColors.textSecondary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  customerAddress,
                  style: const TextStyle(color: AppColors.textPrimary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          
          // Distance
          Row(
            children: [
              const Icon(Icons.straighten, size: 16, color: AppColors.textSecondary),
              const SizedBox(width: 8),
              Text(
                distance,
                style: const TextStyle(color: AppColors.textPrimary),
              ),
              const SizedBox(width: 16),
              const Icon(Icons.access_time, size: 16, color: AppColors.textSecondary),
              const SizedBox(width: 8),
              Text(
                estimatedTime,
                style: const TextStyle(color: AppColors.textPrimary),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Prix
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Gain',
                style: TextStyle(color: AppColors.textSecondary),
              ),
              Text(
                '$deliveryFee FCFA',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Boutons
          if (onAccept != null)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onAccept,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                ),
                child: const Text('Accepter la mission'),
              ),
            ),
          if (onComplete != null)
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onTrack,
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: AppColors.primary),
                    ),
                    child: const Text('Suivre'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: onComplete,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                    ),
                    child: const Text('Terminer'),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending': return AppColors.warning;
      case 'in_progress': return AppColors.info;
      case 'completed': return AppColors.success;
      default: return AppColors.textSecondary;
    }
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'pending': return 'En attente';
      case 'in_progress': return 'En cours';
      case 'completed': return 'Terminée';
      default: return status;
    }
  }
}