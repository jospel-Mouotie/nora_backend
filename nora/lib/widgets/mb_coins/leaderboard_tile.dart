import 'package:flutter/material.dart';
import '../../../config/app_colors.dart';
import '../../../utils/converters.dart';

class LeaderboardTile extends StatelessWidget {
  final int rank;
  final Map<String, dynamic> user;
  final bool isCurrentUser;

  const LeaderboardTile({
    super.key,
    required this.rank,
    required this.user,
    this.isCurrentUser = false,
  });

  @override
  Widget build(BuildContext context) {
    final userName = toStringSafe(user['name']);
    final balance = toDoubleSafe(user['balance']).toInt();
    final avatar = user['avatar'];
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isCurrentUser ? AppColors.primary.withOpacity(0.1) : AppColors.background,
        border: Border.all(
          color: isCurrentUser ? AppColors.primary : AppColors.border,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          // Classement
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _getRankColor(rank).withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Center(
              child: Text(
                '$rank',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: _getRankColor(rank),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Avatar
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.backgroundLight,
            ),
            child: avatar != null && avatar.isNotEmpty
                ? ClipOval(
                    child: Image.network(
                      avatar,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(Icons.person),
                    ),
                  )
                : const Icon(Icons.person, size: 28),
          ),
          const SizedBox(width: 12),
          // Nom
          Expanded(
            child: Text(
              userName,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isCurrentUser ? FontWeight.bold : FontWeight.normal,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          // Points
          Text(
            '$balance MB',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: isCurrentUser ? AppColors.primary : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Color _getRankColor(int rank) {
    switch (rank) {
      case 1: return Colors.amber;
      case 2: return Colors.grey;
      case 3: return Colors.brown;
      default: return AppColors.textSecondary;
    }
  }
}