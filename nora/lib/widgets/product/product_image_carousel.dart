import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../config/app_colors.dart';

class ProductImageCarousel extends StatelessWidget {
  final List<String> images;
  final String Function(String) getFullImageUrl;
  final Function(int)? onImageTap;

  const ProductImageCarousel({
    super.key,
    required this.images,
    required this.getFullImageUrl,
    this.onImageTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasImages = images.isNotEmpty;

    if (!hasImages) {
      return Container(
        color: AppColors.backgroundLight,
        child: const Center(
          child: Icon(Icons.image, size: 80, color: AppColors.textTertiary),
        ),
      );
    }

    return PageView.builder(
      itemCount: images.length,
      onPageChanged: (index) {},
      itemBuilder: (context, index) {
        final imageUrl = getFullImageUrl(images[index]);
        return GestureDetector(
          onTap: () => onImageTap?.call(index),
          child: CachedNetworkImage(
            imageUrl: imageUrl,
            fit: BoxFit.cover,
            width: double.infinity,
            placeholder: (context, url) => Container(
              color: AppColors.backgroundLight,
              child: const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            ),
            errorWidget: (context, url, error) => Container(
              color: AppColors.backgroundLight,
              child: const Center(
                child: Icon(Icons.broken_image, size: 50, color: AppColors.textTertiary),
              ),
            ),
          ),
        );
      },
    );
  }
}