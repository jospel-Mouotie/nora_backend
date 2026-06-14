import 'package:flutter/material.dart';
import '../../../config/app_colors.dart';

class ShopTabBar extends StatelessWidget {
  final TabController controller;

  const ShopTabBar({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return TabBar(
      controller: controller,
      indicatorColor: AppColors.primary,
      labelColor: AppColors.primary,
      unselectedLabelColor: AppColors.textSecondary,
      tabs: const [
        Tab(text: 'Produits'),
        Tab(text: 'Reels'),
        Tab(text: 'À propos'),
        Tab(text: 'Avis'),
      ],
    );
  }
}