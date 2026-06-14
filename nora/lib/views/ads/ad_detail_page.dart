import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../config/app_colors.dart';
import '../../../services/ad_service.dart';
import '../../../services/storage_service.dart';
import '../../../utils/converters.dart';

class AdDetailPage extends StatefulWidget {
  final int adId;

  const AdDetailPage({super.key, required this.adId});

  @override
  State<AdDetailPage> createState() => _AdDetailPageState();
}

class _AdDetailPageState extends State<AdDetailPage> {
  final AdService _adService = AdService();
  Map<String, dynamic>? _ad;
  Map<String, dynamic>? _stats;
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
    if (_token == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final result = await _adService.getMyAds(_token!);
      if (result['success'] && result['ads'] != null) {
        final ad = (result['ads'] as List).firstWhere(
              (a) => a['id'] == widget.adId,
          orElse: () => null,
        );
        setState(() {
          _ad = ad;
        });
      }

      final statsResult = await _adService.getAdStats(widget.adId, _token!);
      if (statsResult['success'] && statsResult['stats'] != null) {
        setState(() {
          _stats = statsResult['stats'];
        });
      }
    } catch (e) {
      print('Erreur chargement: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _ad == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    final ad = _ad!;
    final title = toStringSafe(ad['title']);
    final description = toStringSafe(ad['description']);
    final type = toStringSafe(ad['type']);
    final position = toStringSafe(ad['position']);
    final status = toStringSafe(ad['status']);
    final imageUrl = ad['image_url'];
    final impressions = toIntSafe(_stats?['impressions'] ?? ad['impressions_count']);
    final clicks = toIntSafe(_stats?['clicks'] ?? ad['clicks_count']);
    final ctr = impressions > 0 ? (clicks / impressions * 100).toStringAsFixed(2) : '0';
    final budget = toDoubleSafe(ad['budget']).toInt();
    final spent = toDoubleSafe(ad['spent_amount']).toInt();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Détails publicité',
          style: TextStyle(color: AppColors.textPrimary),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: imageUrl != null && imageUrl.isNotEmpty
                  ? CachedNetworkImage(
                imageUrl: imageUrl,
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  height: 200,
                  color: AppColors.backgroundLight,
                  child: const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  ),
                ),
                errorWidget: (context, url, error) => Container(
                  height: 200,
                  color: AppColors.backgroundLight,
                  child: const Icon(Icons.image, size: 50),
                ),
              )
                  : Container(
                height: 200,
                color: AppColors.backgroundLight,
                child: const Icon(Icons.image, size: 50),
              ),
            ),
            const SizedBox(height: 16),

            // Titre et statut
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: status == 'active'
                        ? AppColors.success.withOpacity(0.1)
                        : AppColors.warning.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    status == 'active' ? 'Active' : 'En pause',
                    style: TextStyle(
                      color: status == 'active' ? AppColors.success : AppColors.warning,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Description
            Text(
              description,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),

            // Type et position
            Wrap(
              spacing: 12,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Type: ${type == 'banner' ? 'Bannière' : type}',
                    style: const TextStyle(fontSize: 12, color: AppColors.primary),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.info.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Position: ${position == 'top' ? 'Haut de page' : position}',
                    style: const TextStyle(fontSize: 12, color: AppColors.info),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Statistiques
            const Text(
              'Statistiques',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _buildStatCard('Impressions', '$impressions', Icons.visibility),
                const SizedBox(width: 12),
                _buildStatCard('Clics', '$clicks', Icons.touch_app),
                const SizedBox(width: 12),
                _buildStatCard('CTR', '$ctr%', Icons.percent),
              ],
            ),
            const SizedBox(height: 24),

            // Budget
            const Text(
              'Budget',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.backgroundLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  LinearProgressIndicator(
                    value: budget > 0 ? spent / budget : 0,
                    backgroundColor: AppColors.border,
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Dépensé: $spent FCFA',
                        style: const TextStyle(fontSize: 14),
                      ),
                      Text(
                        'Budget: $budget FCFA',
                        style: const TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${(((budget - spent) / budget) * 100).toInt()}% restant',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.success,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.backgroundLight,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, size: 28, color: AppColors.primary),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}