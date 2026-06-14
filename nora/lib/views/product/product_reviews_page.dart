import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../config/app_colors.dart';
import '../../../services/product_api_service.dart';
import '../../../services/storage_service.dart';
import '../../../utils/converters.dart';

class ProductReviewsPage extends StatefulWidget {
  final int productId;

  const ProductReviewsPage({super.key, required this.productId});

  @override
  State<ProductReviewsPage> createState() => _ProductReviewsPageState();
}

class _ProductReviewsPageState extends State<ProductReviewsPage> {
  final ProductApiService _productApiService = ProductApiService();
  List<dynamic> _reviews = [];
  Map<String, dynamic>? _summary;
  bool _isLoading = true;
  String? _token;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    _token = await StorageService().getToken();

    try {
      final result = await _productApiService.getProductReviews(widget.productId);
      if (result['success'] && result['reviews'] != null) {
        // Calculer le résumé des avis
        final reviews = result['reviews'] as List;
        final totalReviews = reviews.length;
        final sumRatings = reviews.fold<int>(0, (sum, review) => sum + (review['rating'] as int));
        final averageRating = totalReviews > 0 ? sumRatings / totalReviews : 0.0;

        // Calculer la distribution des notes
        final distribution = List.generate(5, (i) {
          final rating = i + 1;
          final count = reviews.where((r) => r['rating'] == rating).length;
          return {'rating': rating, 'count': count};
        }).reversed.toList();

        setState(() {
          _reviews = reviews;
          _summary = {
            'average_rating': averageRating,
            'total_reviews': totalReviews,
            'rating_distribution': distribution,
          };
        });
      }
    } catch (e) {
      print('Erreur chargement avis: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              context.pop();
            } else {
              context.go('/home');
            }
          },
        ),
        title: const Text(
          'Avis clients',
          style: TextStyle(color: AppColors.textPrimary),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : _reviews.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.rate_review_outlined, size: 64, color: AppColors.textTertiary),
                      const SizedBox(height: 16),
                      const Text(
                        'Aucun avis pour ce produit',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Soyez le premier à donner votre avis',
                        style: TextStyle(fontSize: 12, color: AppColors.textTertiary),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      if (_summary != null) _buildSummaryCard(),
                      const SizedBox(height: 24),
                      ..._reviews.map((review) => _buildReviewCard(review)),
                    ],
                  ),
                ),
    );
  }

  Widget _buildSummaryCard() {
    final averageRating = toDoubleSafe(_summary?['average_rating']);
    final totalReviews = toIntSafe(_summary?['total_reviews']);
    final fullStars = averageRating.floor();
    final hasHalfStar = averageRating - fullStars >= 0.5;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Text(
                  averageRating.toStringAsFixed(1),
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    ...List.generate(fullStars, (index) => const Icon(
                      Icons.star,
                      size: 16,
                      color: AppColors.starYellow,
                    )),
                    if (hasHalfStar) const Icon(
                      Icons.star_half,
                      size: 16,
                      color: AppColors.starYellow,
                    ),
                    ...List.generate(5 - fullStars - (hasHalfStar ? 1 : 0), (index) => const Icon(
                      Icons.star_border,
                      size: 16,
                      color: AppColors.starYellow,
                    )),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$totalReviews avis',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                if (_summary?['rating_distribution'] != null)
                  ...(_summary!['rating_distribution'] as List).map((dist) {
                    final rating = dist['rating'] as int;
                    final count = dist['count'] as int;
                    final percentage = totalReviews > 0 ? (count / totalReviews * 100) : 0.0;
                    return _buildRatingBar(rating, percentage);
                  }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingBar(int rating, double percentage) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          SizedBox(
            width: 30,
            child: Text(
              '$rating étoile${rating > 1 ? 's' : ''}',
              style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              height: 6,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(3),
              ),
              child: FractionallySizedBox(
                widthFactor: percentage / 100,
                alignment: Alignment.centerLeft,
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.starYellow,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 40,
            child: Text(
              '${percentage.toStringAsFixed(0)}%',
              style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewCard(Map<String, dynamic> review) {
    final rating = toIntSafe(review['rating']);
    final userName = toStringSafe(review['user_name']);
    final comment = toStringSafe(review['comment']);
    final createdAt = toStringSafe(review['created_at']);
    final userAvatar = review['user_avatar'];

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.background,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.primary.withOpacity(0.1),
                backgroundImage: userAvatar != null
                    ? NetworkImage(userAvatar)
                    : null,
                child: userAvatar == null
                    ? Text(
                        userName.isNotEmpty ? userName[0].toUpperCase() : '?',
                        style: const TextStyle(color: AppColors.primary),
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      userName,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: List.generate(5, (index) {
                        return Icon(
                          index < rating ? Icons.star : Icons.star_border,
                          size: 14,
                          color: AppColors.starYellow,
                        );
                      }),
                    ),
                  ],
                ),
              ),
              Text(
                _formatDate(createdAt),
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textTertiary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            comment,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String dateTimeStr) {
    final dateTime = DateTime.tryParse(dateTimeStr);
    if (dateTime == null) return '';
    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inDays > 7) {
      return '${diff.inDays ~/ 7} sem';
    } else if (diff.inDays > 0) {
      return '${diff.inDays} j';
    } else if (diff.inHours > 0) {
      return '${diff.inHours} h';
    } else if (diff.inMinutes > 0) {
      return '${diff.inMinutes} min';
    } else {
      return 'à l\'instant';
    }
  }
}
