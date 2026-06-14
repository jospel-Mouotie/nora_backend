import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../config/app_colors.dart';
import '../../../config/app_constants.dart';
import '../../../utils/converters.dart';

class ShopProductCard extends StatelessWidget {
  final Map<String, dynamic> product;
  final VoidCallback onTap;

  const ShopProductCard({
    super.key,
    required this.product,
    required this.onTap,
  });

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
    final price = toDoubleSafe(product['price']);
    final originalPrice = toDoubleSafe(product['original_price'] ?? product['compare_price']);
    final discount = product['discount'];
    final rating = toDoubleSafe(product['rating']);
    final reviewsCount = toIntSafe(product['reviews_count']);
    final name = toStringSafe(product['name']);
    final isShopVerified = product['shop']?['is_verified'] == true || 
                          product['shop']?['certifiee'] == true;

    // Récupération des images
    List<String> imageUrls = [];
    final imagesData = product['images'];
    
    if (imagesData is List) {
      imageUrls = imagesData.map((e) => e.toString()).toList();
    } else if (imagesData is String && imagesData.isNotEmpty) {
      try {
        if (imagesData.startsWith('[')) {
          final parsed = jsonDecode(imagesData);
          if (parsed is List) {
            imageUrls = parsed.map((e) => e.toString()).toList();
          } else {
            imageUrls = [imagesData];
          }
        } else {
          imageUrls = [imagesData];
        }
      } catch (e) {
        imageUrls = [imagesData];
      }
    }
    
    final hasImages = imageUrls.isNotEmpty;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border.withOpacity(0.5)),
          boxShadow: AppColors.cardShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                // Image
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  child: hasImages
                      ? _ShopImageCarousel(
                          images: imageUrls,
                          height: 140,
                          autoPlay: true,
                          autoPlayInterval: const Duration(seconds: 5),
                          getFullImageUrl: _getFullImageUrl,
                        )
                      : Container(
                          height: 140,
                          width: double.infinity,
                          color: AppColors.backgroundLight,
                          child: const Center(
                            child: Icon(Icons.image, size: 40, color: AppColors.textTertiary),
                          ),
                        ),
                ),
                if (discount != null)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.promotion,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '-$discount%',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                if (isShopVerified)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.verified, size: 10, color: Colors.white),
                          SizedBox(width: 2),
                          Text(
                            'Certifié',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.star, size: 12, color: AppColors.starYellow),
                      const SizedBox(width: 2),
                      Text(
                        rating.toStringAsFixed(1),
                        style: const TextStyle(fontSize: 11, color: AppColors.textPrimary),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '($reviewsCount)',
                        style: TextStyle(fontSize: 10, color: AppColors.textTertiary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Text(
                        '${price.toInt().toString().replaceAll('.0', '')} FCFA',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                        ),
                      ),
                      if (originalPrice > 0 && originalPrice > price)
                        Padding(
                          padding: const EdgeInsets.only(left: 6),
                          child: Text(
                            '${originalPrice.toInt().toString().replaceAll('.0', '')} FCFA',
                            style: TextStyle(
                              fontSize: 11,
                              decoration: TextDecoration.lineThrough,
                              color: AppColors.textTertiary,
                            ),
                          ),
                        ),
                    ],
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

// Widget carrousel pour les images de la boutique
class _ShopImageCarousel extends StatefulWidget {
  final List<String> images;
  final double height;
  final bool autoPlay;
  final Duration autoPlayInterval;
  final String Function(String) getFullImageUrl;

  const _ShopImageCarousel({
    required this.images,
    required this.height,
    this.autoPlay = false,
    this.autoPlayInterval = const Duration(seconds: 5),
    required this.getFullImageUrl,
  });

  @override
  State<_ShopImageCarousel> createState() => _ShopImageCarouselState();
}

class _ShopImageCarouselState extends State<_ShopImageCarousel> {
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

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.height,
      width: double.infinity,
      child: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() => _currentPage = index);
            },
            itemCount: widget.images.length,
            itemBuilder: (context, index) {
              final imageUrl = widget.getFullImageUrl(widget.images[index]);
              return CachedNetworkImage(
                imageUrl: imageUrl,
                fit: BoxFit.cover,
                width: double.infinity,
                placeholder: (context, url) => Container(
                  color: AppColors.backgroundLight,
                ),
                errorWidget: (context, url, error) => Container(
                  color: AppColors.backgroundLight,
                  child: const Icon(Icons.broken_image, size: 30, color: AppColors.textTertiary),
                ),
              );
            },
          ),
          if (widget.images.length > 1)
            Positioned(
              bottom: 8,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  widget.images.length,
                  (index) => AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: _currentPage == index ? 10 : 5,
                    height: 5,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(3),
                      color: _currentPage == index
                          ? AppColors.primary
                          : Colors.white.withOpacity(0.5),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}