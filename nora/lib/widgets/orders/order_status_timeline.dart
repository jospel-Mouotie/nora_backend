import 'package:flutter/material.dart';
import '../../../config/app_colors.dart';

class OrderStatusTimeline extends StatelessWidget {
  final List<Map<String, dynamic>> timeline;

  const OrderStatusTimeline({super.key, required this.timeline});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (int i = 0; i < timeline.length; i++) ...[
          _buildTimelineItem(timeline[i], i == timeline.length - 1),
          if (i < timeline.length - 1) _buildConnector(timeline[i]['completed']),
        ],
      ],
    );
  }

  Widget _buildTimelineItem(Map<String, dynamic> item, bool isLast) {
    final isCompleted = item['completed'] as bool;
    
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Icône
        SizedBox(
          width: 40,
          child: Column(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isCompleted ? AppColors.primary : AppColors.backgroundLight,
                  border: Border.all(
                    color: isCompleted ? AppColors.primary : AppColors.border,
                    width: 2,
                  ),
                ),
                child: isCompleted
                    ? const Icon(Icons.check, size: 14, color: Colors.white)
                    : null,
              ),
            ],
          ),
        ),
        // Contenu
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item['label'],
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isCompleted ? FontWeight.w600 : FontWeight.normal,
                  color: isCompleted ? AppColors.textPrimary : AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                item['date'],
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textTertiary,
                ),
              ),
              if (!isLast) const SizedBox(height: 16),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildConnector(bool isCompleted) {
    return Row(
      children: [
        SizedBox(
          width: 40,
          child: Column(
            children: [
              Container(
                width: 2,
                height: 30,
                color: isCompleted ? AppColors.primary : AppColors.border,
              ),
            ],
          ),
        ),
        const Expanded(child: SizedBox()),
      ],
    );
  }
}