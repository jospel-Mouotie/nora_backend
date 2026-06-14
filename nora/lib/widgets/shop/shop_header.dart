import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../config/app_colors.dart';
import '../../../config/app_constants.dart';
import '../../../widgets/product/rating_stars.dart';
import '../../../utils/converters.dart';

class ShopHeader extends StatelessWidget {
  final Map<String, dynamic> shop;
  final bool isFollowing;
  final VoidCallback onFollow;
  final VoidCallback onLike;
  final VoidCallback onMessage;

  const ShopHeader({
    super.key,
    required this.shop,
    required this.isFollowing,
    required this.onFollow,
    required this.onLike,
    required this.onMessage,
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
    final shopName = toStringSafe(shop['name']);
    final isVerified = shop['is_verified'] == true || shop['certifiee'] == true;
    final rating = toDoubleSafe(shop['rating']);
    final reviewsCount = toIntSafe(shop['reviews_count']);
    final followersCount = toIntSafe(shop['followers_count']);
    final productsCount = toIntSafe(shop['products_count'] ?? shop['total_products'] ?? shop['productsCount'] ?? 0);
    final videosCount = toIntSafe(shop['videos_count'] ?? shop['total_videos'] ?? shop['videosCount'] ?? 0);
    final banner = shop['photo'] ?? shop['banner'];
    final logo = shop['logo'] ?? shop['photo'];

    // Utiliser un Container simple au lieu de SliverAppBar pour éviter les problèmes
    return Column(
      children: [
        // Bannière
        SizedBox(
          height: 200,
          width: double.infinity,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (banner != null && banner.toString().isNotEmpty)
                CachedNetworkImage(
                  imageUrl: _getFullImageUrl(banner),
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                  placeholder: (context, url) => Container(
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                    ),
                  ),
                  errorWidget: (context, url, error) => Container(
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                    ),
                    child: const Center(
                      child: Icon(Icons.store, size: 60, color: Colors.white),
                    ),
                  ),
                )
              else
                Container(
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                  ),
                  child: const Center(
                    child: Icon(Icons.store, size: 60, color: Colors.white),
                  ),
                ),
              // Overlay
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.3),
                      AppColors.background.withOpacity(0.9),
                    ],
                    stops: const [0.0, 0.5, 0.9],
                  ),
                ),
              ),
            ],
          ),
        ),
        // Section logo + infos
        Container(
          color: AppColors.background,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Logo
                Container(
                  width: 80,
                  height: 80,
                    padding: const EdgeInsets.only(top: 0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white, width: 3),
                    boxShadow: AppColors.cardShadow,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: logo != null && logo.toString().isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: _getFullImageUrl(logo),
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(
                              color: AppColors.primary,
                              child: const Icon(
                                Icons.store,
                                color: Colors.white,
                                size: 40,
                              ),
                            ),
                            errorWidget: (context, url, error) => Container(
                              color: AppColors.primary,
                              child: const Icon(
                                Icons.store,
                                color: Colors.white,
                                size: 40,
                              ),
                            ),
                          )
                        : Container(
                            color: AppColors.primary,
                            child: const Icon(
                              Icons.store,
                              color: Colors.white,
                              size: 40,
                            ),
                          ),
                  ),
                ),
                const SizedBox(width: 16),
                // Infos
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              shopName,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isVerified)
                            const Padding(
                              padding: EdgeInsets.only(left: 4),
                              child: Icon(
                                Icons.verified,
                                size: 16,
                                color: AppColors.primary,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          RatingStars(rating: rating, size: 12),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              '${rating.toStringAsFixed(1)} (${_formatNumber(reviewsCount)})',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '| ${_formatNumber(followersCount)} abonnés',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '$productsCount produits • $videosCount vidéos',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                // Boutons
                Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    ElevatedButton(
                      onPressed: onFollow,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isFollowing ? AppColors.primaryLight : AppColors.primary,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(90, 36),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                      ),
                      child: Text(
                        isFollowing ? 'Suivi' : 'Suivre',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                    ),
                    const SizedBox(height: 10),
                    OutlinedButton(
                      onPressed: onMessage,
                      style: OutlinedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppColors.primary,
                        side: const BorderSide(color: AppColors.primary),
                        minimumSize: const Size(90, 36),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                      ),
                      child: const Text(
                        'Message',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _formatNumber(int number) {
    if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toString();
  }
}
