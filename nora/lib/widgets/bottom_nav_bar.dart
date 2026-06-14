import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../config/app_colors.dart';
import '../config/routes.dart';

class BottomNavBar extends StatelessWidget {
  final int currentIndex;

  const BottomNavBar({
    super.key,
    required this.currentIndex,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: currentIndex,
        type: BottomNavigationBarType.fixed,
        backgroundColor: AppColors.background,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textTertiary,
        selectedLabelStyle: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.3,
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w400,
          letterSpacing: 0.3,
        ),
        showSelectedLabels: true,
        showUnselectedLabels: true,
        elevation: 0,
        onTap: (index) {
          switch (index) {
            case 0:
              if (currentIndex != 0) context.go(AppRoutes.home);
              break;
            case 1:
              if (currentIndex != 1) context.go(AppRoutes.categories);
              break;
            case 2:
              if (currentIndex != 2) context.go(AppRoutes.reels);
              break;
            case 3:
              if (currentIndex != 3) context.go(AppRoutes.mbCoins);
              break;
            case 4:
              if (currentIndex != 4) context.go(AppRoutes.cart);
              break;
            case 5:
              if (currentIndex != 5) context.go(AppRoutes.profile);
              break;
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined, size: 24),
            activeIcon: Icon(Icons.home_rounded, size: 24),
            label: 'Accueil',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.store_outlined, size: 24),
            activeIcon: Icon(Icons.store_rounded, size: 24),
            label: 'Boutiques',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.slow_motion_video_outlined, size: 24),
            activeIcon: Icon(Icons.slow_motion_video_rounded, size: 24),
            label: 'Reels',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.monetization_on_outlined, size: 24),
            activeIcon: Icon(Icons.monetization_on_rounded, size: 24),
            label: 'MB Coins',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_bag_outlined, size: 24),
            activeIcon: Icon(Icons.shopping_bag_rounded, size: 24),
            label: 'Panier',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline, size: 24),
            activeIcon: Icon(Icons.person_rounded, size: 24),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}