import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../config/app_colors.dart';
import '../../../config/app_constants.dart';
import '../../../utils/converters.dart';

class ProductCard extends StatelessWidget {
  final Map<String, dynamic> product;
  final VoidCallback onTap;
  final bool showDiscountBadge;
  final bool showMbCoinsPrice;

  const ProductCard({
    super.key,
    required this.product,
    required this.onTap,
    this.showDiscountBadge = false,
    this.showMbCoinsPrice = false,
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
    // Utilisation des propriétés de promotion
    final price = toDoubleSafe(product['price']);
    final promotionPrice = product['promotion_price'] != null
        ? toDoubleSafe(product['promotion_price'])
        : null;
    final inPromotion = product['in_promotion'] == true;
    final hasDiscount = showDiscountBadge && inPromotion && promotionPrice != null && promotionPrice < price;

    // Calcul du pourcentage de réduction
    int discountPercentage = 0;
    if (hasDiscount && price > 0) {
      discountPercentage = ((price - promotionPrice!) / price * 100).round();
    }

    final rating = toDoubleSafe(product['rating']);
    final reviewsCount = toIntSafe(product['reviews_count']);
    final name = toStringSafe(product['name']);
    final shopName = toStringSafe(product['shop_name'] ?? product['shop']?['name']);
    final isShopVerified = product['shop']?['is_verified'] == true ||
                          product['shop']?['certifiee'] == true;

    // Prix actuel (promotion ou normal)
    final currentPrice = hasDiscount ? promotionPrice! : price;

    // Récupération des images
    dynamic imagesData = product['images'];
    List<String> imageUrls = [];

    if (imagesData is List) {
      imageUrls = imagesData.map((e) => e.toString()).toList();
    } else if (imagesData is String && imagesData.isNotEmpty) {
      imageUrls = [imagesData];
    }

    final hasImages = imageUrls.isNotEmpty;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: AppColors.cardShadow,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            children: [
              // Image en fond (prend toute la carte)
              Positioned.fill(
                child: hasImages
                    ? _ProductImageCarousel(
                        images: imageUrls,
                        getFullImageUrl: _getFullImageUrl,
                      )
                    : Container(
                        color: AppColors.backgroundLight,
                        child: const Center(
                          child: Icon(Icons.image, size: 40, color: AppColors.textTertiary),
                        ),
                      ),
              ),

              // Overlay gradient pour lisibilité du texte
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.3),
                        Colors.black.withOpacity(0.7),
                      ],
                      stops: const [0.0, 0.5, 1.0],
                    ),
                  ),
                ),
              ),

              // Badges (en haut)
              Positioned(
                top: 8,
                left: 8,
                child: Row(
                  children: [
                    if (hasDiscount)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.promotion,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '-$discountPercentage%',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    if (isShopVerified && hasDiscount) const SizedBox(width: 6),
                    if (isShopVerified)
                      Container(
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
                  ],
                ),
              ),

              // Infos produit en bas
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Nom du produit
                      Text(
                        name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          height: 1.2,
                          shadows: [
                            Shadow(
                              offset: Offset(0, 1),
                              blurRadius: 2,
                              color: Colors.black26,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 4),

                      // Nom boutique + badge
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              shopName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 10,
                                color: Colors.white70,
                                shadows: [
                                  Shadow(
                                    offset: Offset(0, 1),
                                    blurRadius: 2,
                                    color: Colors.black26,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),

                      // Étoiles
                      Row(
                        children: [
                          Icon(Icons.star, size: 12, color: AppColors.starYellow),
                          const SizedBox(width: 4),
                          Text(
                            rating.toStringAsFixed(1),
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '($reviewsCount)',
                            style: TextStyle(
                              fontSize: 9,
                              color: Colors.white.withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),

                      // Prix
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            showMbCoinsPrice
                                ? '${(currentPrice / 2).toInt()} MB'
                                : '${currentPrice.toInt().toString().replaceAll('.0', '')} FCFA',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              shadows: [
                                Shadow(
                                  offset: Offset(0, 1),
                                  blurRadius: 2,
                                  color: Colors.black26,
                                ),
                              ],
                            ),
                          ),
                          if (!showMbCoinsPrice && hasDiscount)
                            Padding(
                              padding: const EdgeInsets.only(left: 6),
                              child: Text(
                                '${price.toInt().toString().replaceAll('.0', '')} FCFA',
                                style: TextStyle(
                                  fontSize: 11,
                                  decoration: TextDecoration.lineThrough,
                                  color: Colors.white.withOpacity(0.6),
                                  shadows: [
                                    Shadow(
                                      offset: Offset(0, 1),
                                      blurRadius: 1,
                                      color: Colors.black26,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Widget carrousel pour les images
class _ProductImageCarousel extends StatefulWidget {
  final List<String> images;
  final String Function(String) getFullImageUrl;

  const _ProductImageCarousel({
    required this.images,
    required this.getFullImageUrl,
  });

  @override
  State<_ProductImageCarousel> createState() => _ProductImageCarouselState();
}

class _ProductImageCarouselState extends State<_ProductImageCarousel> {
  late PageController _pageController;
  int _currentPage = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    if (widget.images.length > 1) {
      _startAutoPlay();
    }
  }

  void _startAutoPlay() {
    _timer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (_pageController.hasClients && widget.images.length > 1 && mounted) {
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
      height: double.infinity,
      width: double.infinity,
      child: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              if (mounted) {
                setState(() => _currentPage = index);
              }
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
                  child: const Icon(Icons.broken_image, size: 40, color: AppColors.textTertiary),
                ),
              );
            },
          ),

          // Indicateur de page
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
                    width: _currentPage == index ? 12 : 6,
                    height: 3,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(2),
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
