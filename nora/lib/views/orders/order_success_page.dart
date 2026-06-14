import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../config/app_colors.dart';
import '../../../config/routes.dart';

class OrderSuccessPage extends StatelessWidget {
  final String orderId;

  const OrderSuccessPage({super.key, required this.orderId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.success.withOpacity(0.2),
                      AppColors.success.withOpacity(0.05),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check_circle,
                  size: 60,
                  color: AppColors.success,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Commande confirmée !',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Votre commande N°$orderId a été enregistrée',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.backgroundLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Column(
                  children: [
                    Text(
                      '📦 Livraison prévue sous 24h-48h',
                      style: TextStyle(fontSize: 14),
                    ),
                    SizedBox(height: 8),
                    Text(
                      '💰 Paiement à la livraison',
                      style: TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    context.go(AppRoutes.home);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Retour à l\'accueil'),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () {
                  context.push('${AppRoutes.orderDetail}/$orderId');
                },
                child: const Text('Voir le détail de ma commande'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}