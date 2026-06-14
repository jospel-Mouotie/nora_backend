import 'package:flutter/material.dart';
import '../../../config/app_colors.dart';
import '../../../utils/converters.dart';

class ReelsPreview extends StatelessWidget {
  final Map<String, dynamic>? video;
  final String? testTitle;
  final VoidCallback? onTap;

  const ReelsPreview({
    super.key,
    this.video,
    this.testTitle,
    this.onTap,
  });

  // Factory constructor pour les données de test
  factory ReelsPreview.test(String testTitle, {VoidCallback? onTap}) {
    return ReelsPreview(
      video: null,
      testTitle: testTitle,
      onTap: onTap,
    );
  }

  String get title {
    if (video != null) {
      return toStringSafe(video!['title']);
    }
    return testTitle ?? 'Reel';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap ?? () {},
      child: Container(
        width: 120,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: AppColors.backgroundLight,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 140,
              decoration: BoxDecoration(
                color: AppColors.backgroundLight,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              ),
              child: Center(
                child: Icon(
                  Icons.play_circle_outline,
                  size: 40,
                  color: AppColors.primary,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}