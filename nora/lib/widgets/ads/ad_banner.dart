
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../config/app_colors.dart';
import '../../../services/ad_service.dart';
import '../../../utils/converters.dart';

class AdBanner extends StatefulWidget {
  final String position;
  final Function(String)? onAdClicked;

  const AdBanner({
    super.key,
    required this.position,
    this.onAdClicked,
  });

  @override
  State<AdBanner> createState() => _AdBannerState();
}

class _AdBannerState extends State<AdBanner> {
  final AdService _adService = AdService();
  List<dynamic> _ads = [];
  bool _isLoading = true;
  int _currentIndex = 0;
  late PageController _pageController;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _loadAds();
  }
// Dans la méthode _loadAds(), assure-toi de bien parser la réponse
Future<void> _loadAds() async {
  setState(() => _isLoading = true);
  
  try {
    final result = await _adService.getActiveAds(position: widget.position);
    if (result['success'] && result['ads'] != null) {
      final adsData = result['ads'];
      // S'assurer que adsData est une liste
      if (adsData is List) {
        setState(() {
          _ads = adsData;
          _isLoading = false;
        });
      } else if (adsData is Map && adsData['data'] is List) {
        setState(() {
          _ads = adsData['data'];
          _isLoading = false;
        });
      } else {
        setState(() {
          _ads = [];
          _isLoading = false;
        });
      }
      
      if (_ads.length > 1) {
        _startAutoPlay();
      }
    } else {
      setState(() => _isLoading = false);
    }
  } catch (e) {
    print('Erreur chargement publicités: $e');
    setState(() => _isLoading = false);
  }
}
  void _startAutoPlay() {
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (_pageController.hasClients && _ads.length > 1) {
        final nextPage = (_currentIndex + 1) % _ads.length;
        _pageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  Future<void> _onAdTap(Map<String, dynamic> ad) async {
    final adId = ad['id'];
    final linkUrl = toStringSafe(ad['link_url']);
    
    // Enregistrer le clic
    await _adService.recordClick(adId);
    
    if (widget.onAdClicked != null) {
      widget.onAdClicked!(linkUrl);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        height: 120,
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.backgroundLight,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    if (_ads.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      height: 120,
      margin: const EdgeInsets.all(8),
      child: PageView.builder(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() => _currentIndex = index);
        },
        itemCount: _ads.length,
        itemBuilder: (context, index) {
          final ad = _ads[index];
          final imageUrl = ad['image_url'];
          final title = toStringSafe(ad['title']);
          
          return GestureDetector(
            onTap: () => _onAdTap(ad),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Stack(
                  children: [
                    if (imageUrl != null && imageUrl.isNotEmpty)
                      CachedNetworkImage(
                        imageUrl: imageUrl,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: 120,
                        placeholder: (context, url) => Container(
                          color: AppColors.primary,
                          child: const Center(
                            child: CircularProgressIndicator(color: Colors.white),
                          ),
                        ),
                        errorWidget: (context, url, error) => Container(
                          color: AppColors.primary,
                          child: Center(
                            child: Text(
                              title,
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                        ),
                      )
                    else
                      Container(
                        color: AppColors.primary,
                        child: Center(
                          child: Text(
                            title,
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                    // Overlay pour le texte
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withOpacity(0.7),
                            ],
                          ),
                        ),
                        child: Text(
                          title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    // Badge "Sponsorisé"
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'Sponsorisé',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}