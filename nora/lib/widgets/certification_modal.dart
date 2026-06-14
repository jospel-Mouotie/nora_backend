import 'package:flutter/material.dart';
import '../config/app_colors.dart';
import '../models/shop_model.dart';
import '../providers/shop_provider.dart';
import 'package:provider/provider.dart';

class CertificationModal extends StatefulWidget {
  final Shop shop;

  const CertificationModal({
    super.key,
    required this.shop,
  });

  @override
  State<CertificationModal> createState() => _CertificationModalState();
}

class _CertificationModalState extends State<CertificationModal> {
  bool _isLoading = false;

  Future<void> _requestCertification() async {
    setState(() => _isLoading = true);

    final shopProvider = context.read<ShopProvider>();
    final success = await shopProvider.requestCertification(widget.shop.id);

    if (success) {
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Demande de certification envoyée avec succès!'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } else {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(shopProvider.errorMessage ?? 'Erreur lors de la demande'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.verified,
                size: 40,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 16),

            // Title
            const Text(
              'Certifiez votre boutique',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),

            // Description
            Text(
              'Obtenez le badge de certification pour ${widget.shop.name} et gagnez la confiance de vos clients.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 16),

            // Benefits
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.backgroundLight,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildBenefit(Icons.check_circle, 'Badge de certification visible'),
                  _buildBenefit(Icons.star, 'Meilleure visibilité dans les recherches'),
                  _buildBenefit(Icons.security, 'Confiance accrue des clients'),
                  _buildBenefit(Icons.trending_up, 'Augmentation des ventes'),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: AppColors.border),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('Plus tard'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _requestCertification,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text('Demander la certification'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBenefit(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.success),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

// Fonction utilitaire pour afficher la modal
void showCertificationModal(BuildContext context, Shop shop) {
  showDialog(
    context: context,
    builder: (context) => CertificationModal(shop: shop),
  );
}
