import 'package:flutter/material.dart';
import '../../config/app_colors.dart';

class SocialLoginButtons extends StatelessWidget {
  const SocialLoginButtons({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            const Expanded(child: Divider(color: AppColors.border)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'ou continuer avec',
                style: TextStyle(color: AppColors.textTertiary, fontSize: 12),
              ),
            ),
            const Expanded(child: Divider(color: AppColors.border)),
          ],
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            _buildSocialButton(
              icon: Icons.g_mobiledata,
              label: 'Google',
              color: Colors.red,
              onTap: () {},
            ),
            const SizedBox(width: 16),
            _buildSocialButton(
              icon: Icons.facebook,
              label: 'Facebook',
              color: Colors.blue,
              onTap: () {},
            ),
            const SizedBox(width: 16),
            _buildSocialButton(
              icon: Icons.apple,
              label: 'Apple',
              color: Colors.black,
              onTap: () {},
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSocialButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}