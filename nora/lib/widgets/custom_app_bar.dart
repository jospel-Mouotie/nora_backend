import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../config/app_colors.dart';
import '../config/routes.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool showBackButton;
  final List<Widget>? actions;
  final Color? backgroundColor;
  final bool centerTitle;
  final VoidCallback? onBackPressed;
  final bool showLogo;
  final VoidCallback? onMenuPressed;

  const CustomAppBar({
    super.key,
    this.title = '',
    this.showBackButton = true,
    this.actions,
    this.backgroundColor,
    this.centerTitle = true,
    this.onBackPressed,
    this.showLogo = false,
    this.onMenuPressed,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
       
      title: showLogo
          ? Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.asset(
                      'assets/images/logo.png',
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(
                          Icons.shopping_bag,
                          size: 18,
                          color: Colors.white,
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'NORA CMR',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                    letterSpacing: 1,
                  ),
                ),
              ],
            )
          : Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
      centerTitle: centerTitle,
      backgroundColor: backgroundColor ?? AppColors.background,
      elevation: 0,
      leading: showBackButton
          ? IconButton(
              icon: const Icon(Icons.arrow_back_ios, size: 20, color: AppColors.textPrimary),
              onPressed: onBackPressed ?? () {
                if (Navigator.of(context).canPop()) {
                  context.pop();
                } else {
                  context.go(AppRoutes.home);
                }
              },
            )
          : (onMenuPressed != null
              ? IconButton(
                  icon: const Icon(Icons.menu, color: AppColors.textPrimary, size: 24),
                  onPressed: onMenuPressed,
                )
              : null),
      actions: actions,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}