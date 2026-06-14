import 'package:flutter/material.dart';
import '../../../config/app_colors.dart';

class RatingStars extends StatelessWidget {
  final double rating;
  final double size;
  final bool showNumber;

  const RatingStars({
    super.key,
    required this.rating,
    this.size = 14,
    this.showNumber = false,
  });

  @override
  Widget build(BuildContext context) {
    final safeRating = rating.clamp(0.0, 5.0);
    final fullStars = safeRating.floor();
    final hasHalfStar = safeRating - fullStars >= 0.5;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ...List.generate(fullStars, (index) => Icon(
          Icons.star,
          size: size,
          color: AppColors.starYellow,
        )),
        if (hasHalfStar)
          Icon(
            Icons.star_half,
            size: size,
            color: AppColors.starYellow,
          ),
        ...List.generate(5 - fullStars - (hasHalfStar ? 1 : 0), (index) => Icon(
          Icons.star_border,
          size: size,
          color: AppColors.starYellow,
        )),
        if (showNumber)
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Text(
              safeRating.toStringAsFixed(1),
              style: TextStyle(
                fontSize: size,
                color: AppColors.textSecondary,
              ),
            ),
          ),
      ],
    );
  }
}