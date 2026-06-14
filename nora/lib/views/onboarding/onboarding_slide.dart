import 'package:flutter/material.dart';
import '../../config/app_colors.dart';

class OnboardingSlideData {
  final String title;
  final String description;
  final IconData imageIcon;

  OnboardingSlideData({
    required this.title,
    required this.description,
    required this.imageIcon,
  });
}

class OnboardingSlide extends StatelessWidget {
  final OnboardingSlideData data;
  final bool isLastPage;

  const OnboardingSlide({
    super.key,
    required this.data,
    required this.isLastPage,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icône
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: AppColors.backgroundLight,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.border),
            ),
            child: Icon(
              data.imageIcon,
              size: 60,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 40),
          // Titre
          Text(
            data.title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          // Description
          Text(
            data.description,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}