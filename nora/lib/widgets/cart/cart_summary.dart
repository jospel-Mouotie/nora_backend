import 'package:flutter/material.dart';
import '../../../config/app_colors.dart';

class CartSummary extends StatelessWidget {
  final Map<String, dynamic> summary;
  final VoidCallback onCheckout;

  const CartSummary({
    super.key,
    required this.summary,
    required this.onCheckout,
  });

  @override
  Widget build(BuildContext context) {
    final subtotal = summary['subtotal'] as int;
    final deliveryFee = summary['delivery_fee'] as int;
    final total = summary['total'] as int;
    final itemCount = summary['item_count'] as int;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.background,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Column(
        children: [
          // Sous-total
          _buildSummaryRow('Sous-total ($itemCount articles)', subtotal),
          const SizedBox(height: 8),
          _buildSummaryRow('Frais de livraison', deliveryFee),
          const Divider(height: 16),
          _buildSummaryRow('Total à payer', total, isTotal: true),
          const SizedBox(height: 16),
          // Message paiement à la livraison
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.backgroundLight,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.money_outlined, size: 20, color: AppColors.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Paiement à la livraison\nVous payez en espèces à la réception.',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Adresse de livraison (simulation)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.backgroundLight,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.location_on_outlined, size: 20, color: AppColors.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Adresse de livraison',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        'Nkolbisson, Yaoundé',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      Text(
                        'Livraison estimée: Aujourd\'hui, 14h - 16h',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textTertiary,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.edit, size: 18, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Bouton Valider
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onCheckout,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Valider ma commande',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, int amount, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isTotal ? 16 : 14,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            color: isTotal ? AppColors.textPrimary : AppColors.textSecondary,
          ),
        ),
        Text(
          '${amount.toString().replaceAll('.0', '')} FCFA',
          style: TextStyle(
            fontSize: isTotal ? 18 : 14,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            color: isTotal ? AppColors.primary : AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}