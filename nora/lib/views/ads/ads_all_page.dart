import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../config/app_colors.dart';
import '../../config/app_constants.dart';
import '../../config/routes.dart';
import '../../services/ad_service.dart';

class AdsAllPage extends StatefulWidget {
  const AdsAllPage({super.key});

  @override
  State<AdsAllPage> createState() => _AdsAllPageState();
}

class _AdsAllPageState extends State<AdsAllPage> {
  final AdService _adService = AdService();
  List<dynamic> _ads = [];
  bool _isLoading = true;
  String? _errorMessage;

  String _getFullImageUrl(String? path) {
    if (path == null || path.isEmpty) return '';
    if (path.startsWith('http')) return path;
    if (path.startsWith('/storage')) {
      return '${AppConstants.apiBaseUrl.replaceAll('/api', '')}$path';
    }
    return '${AppConstants.apiBaseUrl.replaceAll('/api', '')}/storage/$path';
  }

  @override
  void initState() {
    super.initState();
    _loadAds();
  }

  Future<void> _loadAds() async {
    setState(() => _isLoading = true);
    
    try {
      final result = await _adService.getActiveAds();
      if (result['success'] && result['ads'] != null) {
        setState(() {
          _ads = result['ads'];
          _isLoading = false;
        });
      } else {
        setState(() {
          _ads = [];
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Erreur chargement pubs: $e');
      setState(() {
        _errorMessage = 'Erreur de connexion';
        _isLoading = false;
      });
    }
  }

  void _onAdTap(Map<String, dynamic> ad) {
    final shopId = ad['shop_id'];
    if (shopId != null) {
      context.push('${AppRoutes.shopDetail}/$shopId');
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
          'Toutes les publicités',
          style: TextStyle(color: AppColors.textPrimary),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 64, color: AppColors.error),
                      const SizedBox(height: 16),
                      Text(
                        _errorMessage!,
                        style: const TextStyle(color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: _loadAds,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                        ),
                        child: const Text('Réessayer'),
                      ),
                    ],
                  ),
                )
              : _ads.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.campaign_outlined, size: 64, color: AppColors.textTertiary),
                          const SizedBox(height: 16),
                          const Text(
                            'Aucune publicité',
                            style: TextStyle(color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadAds,
                      child: GridView.builder(
                        padding: const EdgeInsets.all(16),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.8,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                        ),
                        itemCount: _ads.length,
                        itemBuilder: (context, index) {
                          final ad = _ads[index];
                          return _buildAdCard(ad);
                        },
                      ),
                    ),
    );
  }

  Widget _buildAdCard(Map<String, dynamic> ad) {
    final imageUrl = ad['image_url'] ?? ad['image'] ?? '';
    final shopName = ad['shop']?['name'] ?? ad['shop_name'] ?? '';
    final title = ad['title'] ?? '';
    final description = ad['description'] ?? '';

    return GestureDetector(
      onTap: () => _onAdTap(ad),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                child: imageUrl.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: _getFullImageUrl(imageUrl),
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
                          child: const Icon(Icons.image_not_supported, size: 40),
                        ),
                      )
                    : Container(
                        color: AppColors.backgroundLight,
                        child: const Icon(Icons.image, size: 40),
                      ),
              ),
            ),
            // Info
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (shopName.isNotEmpty)
                    Text(
                      shopName,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  if (title.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  if (description.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
