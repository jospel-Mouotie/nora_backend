import 'package:flutter/material.dart';
import '../../../config/app_colors.dart';
import '../../../utils/converters.dart';

class CoinBalanceCard extends StatelessWidget {
  final Map<String, dynamic>? balance;

  const CoinBalanceCard({super.key, this.balance});

  @override
  Widget build(BuildContext context) {
    final formattedBalance = balance != null
        ? (balance!['formatted_balance'] ?? '${toDoubleSafe(balance!['balance']).toInt()} MB')
        : '0 MB';
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Votre solde',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            formattedBalance,
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.info_outline, size: 16, color: Colors.white70),
              const SizedBox(width: 8),
              const Text(
                'Gagnez des MB Coins en regardant des vidéos, en likant et en commentant',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}