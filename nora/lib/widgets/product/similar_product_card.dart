import 'dart:async';

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../config/app_colors.dart';
import '../../../config/app_constants.dart';
import '../../../utils/converters.dart';

class SimilarProductCard extends StatelessWidget {
  final Map<String, dynamic> product;
  final VoidCallback onTap;

  const SimilarProductCard({
    super.key,
    required this.product,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final price = toDoubleSafe(product['price']);
    final originalPrice = toDoubleSafe(product['original_price'] ?? product['compare_price']);
    final rating = toDoubleSafe(product['rating']);
    final reviewsCount = toIntSafe(product['reviews_count']);
    final name = toStringSafe(product['name']);
    
    // Récupération des images
    final images = product['images'];
    final hasImages = images != null && images is List && images.isNotEmpty;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 150,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image avec carrousel si plusieurs images
            hasImages
                ? _ImageCarousel(
                    images: images,
                    height: 120,
                    autoPlay: true,
                    autoPlayInterval: const Duration(seconds: 5),
                  )
                : Container(
                    height: 120,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: AppColors.backgroundLight,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                    ),
                    child: const Center(
                      child: Icon(Icons.image, size: 40, color: AppColors.textTertiary),
                    ),
                  ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.star, size: 10, color: AppColors.starYellow),
                      const SizedBox(width: 2),
                      Text(
                        rating.toStringAsFixed(1),
                        style: const TextStyle(fontSize: 10),
                      ),
                      const SizedBox(width: 2),
                      Text(
                        '($reviewsCount)',
                        style: TextStyle(fontSize: 9, color: AppColors.textTertiary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${price.toInt().toString().replaceAll('.0', '')} FCFA',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  if (originalPrice > 0 && originalPrice > price)
                    Text(
                      '${originalPrice.toInt().toString().replaceAll('.0', '')} FCFA',
                      style: TextStyle(
                        fontSize: 10,
                        decoration: TextDecoration.lineThrough,
                        color: AppColors.textTertiary,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Widget carrousel pour les images
class _ImageCarousel extends StatefulWidget {
  final List<dynamic> images;
  final double height;
  final bool autoPlay;
  final Duration autoPlayInterval;

  const _ImageCarousel({
    required this.images,
    required this.height,
    this.autoPlay = false,
    this.autoPlayInterval = const Duration(seconds: 5),
  });

  @override
  State<_ImageCarousel> createState() => _ImageCarouselState();
}

class _ImageCarouselState extends State<_ImageCarousel> {
  late PageController _pageController;
  int _currentPage = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    if (widget.autoPlay && widget.images.length > 1) {
      _startAutoPlay();
    }
  }

  void _startAutoPlay() {
    _timer = Timer.periodic(widget.autoPlayInterval, (timer) {
      if (_pageController.hasClients && widget.images.length > 1) {
        final nextPage = (_currentPage + 1) % widget.images.length;
        _pageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  String _getFullImageUrl(String? path) {
    if (path == null || path.isEmpty) return '';
    if (path.startsWith('http')) return path;
    if (path.startsWith('/storage')) {
      return '${AppConstants.apiBaseUrl.replaceAll('/api', '')}$path';
    }
    return '${AppConstants.apiBaseUrl.replaceAll('/api', '')}/storage/$path';
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        SizedBox(
          height: widget.height,
          width: double.infinity,
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() => _currentPage = index);
            },
            itemCount: widget.images.length,
            itemBuilder: (context, index) {
              final imageUrl = _getFullImageUrl(widget.images[index].toString());
              return ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                child: CachedNetworkImage(
                  imageUrl: imageUrl,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  placeholder: (context, url) => Container(
                    color: AppColors.backgroundLight,
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: AppColors.backgroundLight,
                    child: const Center(
                      child: Icon(Icons.broken_image, size: 30, color: AppColors.textTertiary),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        // Indicateurs de page
        if (widget.images.length > 1)
          Positioned(
            bottom: 8,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                widget.images.length,
                (index) => Container(
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _currentPage == index
                        ? AppColors.primary
                        : Colors.white.withOpacity(0.5),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}