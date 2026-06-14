import 'package:flutter/material.dart';
import '../../../config/app_colors.dart';

class MbCoinCard extends StatelessWidget {
  final Map<String, dynamic>? balance;

  const MbCoinCard({super.key, this.balance});

  // Factory constructor pour les données de test
  factory MbCoinCard.test() {
    return MbCoinCard(
      balance: {
        'balance': 1250.5,
        'formatted_balance': '1 250,50 MB',
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final formattedBalance = balance?['formatted_balance'] ?? 
        '${balance?['balance']?.toStringAsFixed(0) ?? 0} MB';
    
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  formattedBalance,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Gagnez des récompenses',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'Actif',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}