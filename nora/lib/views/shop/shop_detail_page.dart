import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../config/app_colors.dart';
import '../../../config/app_constants.dart';
import '../../../config/routes.dart';
import '../../../services/shop_api_service.dart';
import '../../../services/product_api_service.dart';
import '../../../services/video_api_service.dart';
import '../../../services/storage_service.dart';
import '../../../services/ad_service.dart';

import '../../../widgets/shop/shop_header.dart';
import '../../../widgets/shop/shop_product_card.dart';
import '../../../widgets/product/rating_stars.dart';
import '../../../widgets/ads/ad_card.dart';
import '../../../utils/converters.dart';

class ShopDetailPage extends StatefulWidget {
  final int shopId;

  const ShopDetailPage({super.key, required this.shopId});

  @override
  State<ShopDetailPage> createState() => _ShopDetailPageState();
}

class _ShopDetailPageState extends State<ShopDetailPage>
    with SingleTickerProviderStateMixin {
  final ShopApiService _shopApiService = ShopApiService();
  final ProductApiService _productApiService = ProductApiService();
  final VideoApiService _videoApiService = VideoApiService();
  final AdService _adService = AdService();
  late TabController _tabController;
  late PageController _adsCarouselController;

  Map<String, dynamic>? _shop;
  List<dynamic> _products = [];
  List<dynamic> _reels = [];
  List<dynamic> _reviews = [];
  List<dynamic> _shopAds = [];
  final List<dynamic> _shopStories = [];
  bool _isLoading = true;
  bool _isFollowing = false;
  bool _isLiking = false;
  bool _isLoadingReviews = true;
  bool _isSubmittingReview = false;
  bool _isLoadingAds = true;
  final bool _isLoadingStories = true;
  String? _token;

  int _currentPage = 1;
  bool _hasMoreProducts = true;
  bool _isLoadingMore = false;
  String _currentSort = 'recent';
  int? _selectedCategoryId;

  int _currentAdIndex = 0;
  Timer? _adsTimer;

  final TextEditingController _commentController = TextEditingController();

  void _safePop() {
    if (Navigator.of(context).canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.home);
    }
  }

  void _shareShop() {
    if (_shop == null) return;
    
    final shopName = _shop!['name'] ?? 'Boutique';
    final shopId = _shop!['id'];
    final shopDescription = _shop!['description'] ?? '';
    
    // Générer le lien de la boutique
    final shopLink = '${AppConstants.apiBaseUrl.replaceAll('/api', '')}/shop/$shopId';
    
    final shareText = 'Découvrez la boutique $shopName sur Nora! 🛒\n\n$shopDescription\n\n🔗 $shopLink';
    
    Share.share(shareText, subject: 'Boutique $shopName sur Nora');
  }

  void _showStoryViewer(Map<String, dynamic> story, int index) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Stack(
          children: [
            // Story content
            GestureDetector(
              onTap: () {
                Navigator.of(context).pop();
              },
              child: Container(
                width: double.infinity,
                height: double.infinity,
                color: Colors.black,
                child: Center(
                  child: story['type'] == 'video'
                      ? const Icon(Icons.play_circle_outline, size: 80, color: Colors.white)
                      : CachedNetworkImage(
                          imageUrl: _getFullImageUrl(story['content'] ?? story['image_url'] ?? ''),
                          fit: BoxFit.contain,
                        ),
                ),
              ),
            ),
            // Caption overlay
            if (story['caption'] != null && story['caption'].toString().isNotEmpty)
              Positioned(
                bottom: 100,
                left: 16,
                right: 16,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    story['caption'],
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                  ),
                ),
              ),
            // Close button
            Positioned(
              top: 16,
              right: 16,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            // Shop info
            Positioned(
              top: 16,
              left: 16,
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundImage: CachedNetworkImageProvider(
                      _getFullImageUrl(_shop?['photo']),
                    ),
                    radius: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _shop?['name'] ?? '',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
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
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _adsCarouselController = PageController();
    _loadToken();
    _loadShopData();
  }

  void _startAdsCarousel() {
    _adsTimer?.cancel();
    if (_shopAds.isEmpty) return;
    _adsTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (_shopAds.isNotEmpty && mounted && _adsCarouselController.hasClients) {
        final nextIndex = (_currentAdIndex + 1) % _shopAds.length;
        _adsCarouselController.animateToPage(
          nextIndex,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
        if (mounted) {
          setState(() => _currentAdIndex = nextIndex);
        }
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _adsCarouselController.dispose();
    _adsTimer?.cancel();
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _loadToken() async {
    final token = await StorageService().getToken();
    if (mounted) {
      setState(() => _token = token);
    }
  }

  Future<void> _loadShopData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final result = await _shopApiService.getShop(widget.shopId);
      if (mounted && result['success'] && result['shop'] != null) {
        setState(() {
          _shop = result['shop'];
          _isFollowing = _shop?['is_following'] ?? false;
          _isLiking = _shop?['is_liking'] ?? false;
          _isLoading = false;
        });
        await Future.wait([
          _loadShopProducts(refresh: true),
          _loadShopVideos(),
          _loadShopReviews(),
          _loadShopAds(),
        ]);
      } else if (mounted) {
        _loadTestShop();
      }
    } catch (e) {
      print('Erreur loadShopData: $e');
      if (mounted) _loadTestShop();
    }
  }

  Future<void> _loadShopProducts({bool refresh = false}) async {
    if (!mounted) return;
    if (refresh) {
      _currentPage = 1;
      _hasMoreProducts = true;
      setState(() => _products = []);
    }
    if (!_hasMoreProducts || _isLoadingMore) return;
    setState(() => _isLoadingMore = true);

    try {
      final result = await _productApiService.getProducts(
        shopId: widget.shopId,
        limit: 10,
        categoryId: _selectedCategoryId,
        sort: _currentSort,
      );
      if (mounted && result['success'] && result['products'] != null) {
        final newProducts = result['products'] as List;
        setState(() {
          if (refresh) {
            _products = newProducts;
          } else {
            _products.addAll(newProducts);
          }
          _hasMoreProducts = newProducts.length >= 10;
          _currentPage++;
        });
      }
    } catch (e) {
      print('Erreur produits: $e');
    } finally {
      if (mounted) setState(() => _isLoadingMore = false);
    }
  }

  Future<void> _loadShopVideos() async {
    try {
      final result = await _videoApiService.getVideos(shopId: widget.shopId);
      if (mounted && result['success'] && result['videos'] != null) {
        setState(() => _reels = result['videos']);
      }
    } catch (e) {
      print('Erreur vidéos: $e');
    }
  }

  Future<void> _loadShopAds() async {
    if (!mounted) return;
    setState(() => _isLoadingAds = true);
    try {
      final result = await _adService.getShopAds(widget.shopId);
      if (mounted && result['success'] && result['ads'] != null) {
        setState(() {
          _shopAds = result['ads'];
          _isLoadingAds = false;
        });
        _startAdsCarousel();
      } else if (mounted) {
        setState(() {
          _shopAds = [];
          _isLoadingAds = false;
        });
      }
    } catch (e) {
      print('Erreur publicités: $e');
      if (mounted) {
        setState(() {
          _shopAds = [];
          _isLoadingAds = false;
        });
      }
    }
  }

  
  Future<void> _loadShopReviews() async {
    if (!mounted) return;
    setState(() => _isLoadingReviews = true);
    try {
      final result = await _shopApiService.getShopReviews(widget.shopId);
      if (mounted && result['success'] && result['reviews'] != null) {
        setState(() {
          _reviews = result['reviews'];
          _isLoadingReviews = false;
        });
      } else if (mounted) {
        setState(() {
          _reviews = [];
          _isLoadingReviews = false;
        });
      }
    } catch (e) {
      print('Erreur avis: $e');
      if (mounted) {
        setState(() {
          _reviews = [];
          _isLoadingReviews = false;
        });
      }
    }
  }

  void _loadTestShop() {
    if (!mounted) return;
    setState(() {
      _shop = {
        'id': widget.shopId,
        'name': 'Green Style',
        'description': 'Votre boutique mode préférée.',
        'logo': null,
        'banner': null,
        'rating': 4.8,
        'followers_count': 12500,
        'is_following': false,
        'is_liking': false,
      };
      _isLoading = false;
    });
    _loadTestProducts();
    _loadTestReviews();
  }

  void _loadTestProducts() {
    if (!mounted) return;
    setState(() {
      _products = [
        {'id': 1, 'name': 'Sac à main élégant', 'price': 32000, 'rating': 4.8},
        {'id': 2, 'name': 'Robe longue plissée', 'price': 18700, 'rating': 4.6},
        {'id': 3, 'name': 'Baskets blanches', 'price': 15000, 'rating': 4.7},
        {'id': 4, 'name': 'Veste en jean oversize', 'price': 16200, 'rating': 4.5},
      ];
    });
  }

  void _loadTestReviews() {
    if (!mounted) return;
    setState(() {
      _reviews = [
        {'user_name': 'Marie Laurent', 'rating': 5, 'comment': 'Très belle boutique !', 'created_at': DateTime.now().subtract(const Duration(days: 2)).toIso8601String()},
        {'user_name': 'Jean Dupont', 'rating': 4, 'comment': 'Livraison rapide.', 'created_at': DateTime.now().subtract(const Duration(days: 5)).toIso8601String()},
      ];
      _isLoadingReviews = false;
    });
  }

  Future<void> _toggleFollow() async {
    if (_token == null) {
      _showLoginRequired();
      return;
    }
    setState(() => _isFollowing = !_isFollowing);
    try {
      if (_isFollowing) {
        await _shopApiService.followShop(widget.shopId, _token!);
      } else {
        await _shopApiService.unfollowShop(widget.shopId, _token!);
      }
      if (mounted) {
        _showSnackBar(_isFollowing ? 'Vous suivez cette boutique' : 'Vous ne suivez plus cette boutique');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isFollowing = !_isFollowing);
        _showSnackBar('Erreur');
      }
    }
  }

  Future<void> _toggleLike() async {
    if (_token == null) {
      _showLoginRequired();
      return;
    }
    setState(() => _isLiking = !_isLiking);
    try {
      if (_isLiking) {
        await _shopApiService.likeShop(widget.shopId, _token!);
      } else {
        await _shopApiService.unlikeShop(widget.shopId, _token!);
      }
      if (mounted) {
        _showSnackBar(_isLiking ? 'Vous aimez cette boutique' : 'Vous n\'aimez plus cette boutique');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLiking = !_isLiking);
        _showSnackBar('Erreur');
      }
    }
  }

  void _openChat() {
    if (mounted) {
      context.push('${AppRoutes.chatDelivery}/${widget.shopId}');
    }
  }

  void _showLoginRequired() {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Connexion requise'),
        content: const Text('Connectez-vous pour interagir avec la boutique'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              if (mounted) context.push(AppRoutes.login);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('Se connecter'),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(String message, {bool isSuccess = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isSuccess ? AppColors.success : AppColors.error,
      ),
    );
  }

  void _showSortOptions() {
    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Trier par', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _buildSortOption('Plus récents', 'recent'),
            _buildSortOption('Prix croissant', 'price_asc'),
            _buildSortOption('Prix décroissant', 'price_desc'),
            _buildSortOption('Mieux notés', 'rating'),
          ],
        ),
      ),
    );
  }

  Widget _buildSortOption(String label, String value) {
    final isSelected = _currentSort == value;
    return ListTile(
      leading: isSelected ? const Icon(Icons.check, color: AppColors.primary) : null,
      title: Text(label),
      onTap: () {
        setState(() => _currentSort = value);
        Navigator.pop(context);
        _loadShopProducts(refresh: true);
      },
    );
  }

  void _showAddReviewDialog() {
    if (!mounted) return;
    int rating = 5;
    _commentController.clear();
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          title: const Text('Donner votre avis'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  final starValue = index + 1;
                  return IconButton(
                    icon: Icon(starValue <= rating ? Icons.star : Icons.star_border, color: AppColors.starYellow, size: 32),
                    onPressed: () => setStateDialog(() => rating = starValue),
                  );
                }),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _commentController,
                maxLines: 3,
                decoration: const InputDecoration(hintText: 'Votre avis...', border: OutlineInputBorder()),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _submitReview(rating, _commentController.text.trim());
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              child: const Text('Publier'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitReview(int rating, String comment) async {
    if (_token == null) {
      _showLoginRequired();
      return;
    }
    setState(() => _isSubmittingReview = true);
    try {
      final result = await _shopApiService.addShopReview(widget.shopId, rating, comment, _token!);
      if (result['success'] && mounted) {
        _showSnackBar('Avis ajouté !', isSuccess: true);
        await _loadShopReviews();
      }
    } catch (e) {
      if (mounted) _showSnackBar('Erreur');
    } finally {
      if (mounted) setState(() => _isSubmittingReview = false);
    }
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      final diff = DateTime.now().difference(date);
      if (diff.inDays > 7) return '${diff.inDays ~/ 7} sem';
      if (diff.inDays > 0) return '${diff.inDays} j';
      if (diff.inHours > 0) return '${diff.inHours} h';
      return 'à l\'instant';
    } catch (e) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    final crossAxisCount = isTablet ? 3 : 2;
    final adHeight = isTablet ? 220.0 : 180.0;
    final storySize = isTablet ? 90.0 : 70.0;
    final paddingHorizontal = isTablet ? 24.0 : 16.0;

    if (_isLoading || _shop == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
            onPressed: _safePop,
          ),
          title: const Text('Boutique', style: TextStyle(color: AppColors.textPrimary)),
        ),
        body: const Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    final shop = _shop!;
    final isLoggedIn = _token != null;

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
            onPressed: _safePop,
          ),
          title: Text(
            shop['name'] ?? 'Boutique',
            style: const TextStyle(color: AppColors.textPrimary),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.share, color: AppColors.primary),
              onPressed: _shareShop,
              tooltip: 'Partager la boutique',
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Produits'),
              Tab(text: 'Vidéos'),
              Tab(text: 'Avis'),
              Tab(text: 'Infos'),
            ],
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textSecondary,
            indicatorColor: AppColors.primary,
          ),
        ),
        body: Column(
          children: [
            // Header de la boutique
            ShopHeader(
              shop: shop,
              isFollowing: _isFollowing,
              onFollow: _toggleFollow,
              onLike: _toggleLike,
              onMessage: _openChat,
            ),

            // Carrousel des publicités (défilement automatique)
            if (_shopAds.isNotEmpty && !_isLoadingAds)
              Container(
                margin: EdgeInsets.symmetric(vertical: 12),
                height: adHeight,
                child: PageView.builder(
                  controller: _adsCarouselController,
                  onPageChanged: (index) {
                    if (mounted) setState(() => _currentAdIndex = index);
                  },
                  itemCount: _shopAds.length,
                  itemBuilder: (context, index) {
                    final ad = _shopAds[index];
                    return Padding(
                      padding: EdgeInsets.symmetric(horizontal: paddingHorizontal),
                      child: AdCard(
                        ad: ad,
                        onTap: () => context.push('${AppRoutes.adDetail}/${ad['id']}'),
                      ),
                    );
                  },
                ),
              ),

            // Stories (carrousel horizontal)
            if (_shopStories.isNotEmpty && !_isLoadingStories)
              Container(
                height: storySize + 20,
                margin: const EdgeInsets.symmetric(vertical: 8),
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: EdgeInsets.symmetric(horizontal: paddingHorizontal),
                  itemCount: _shopStories.length,
                  itemBuilder: (context, index) {
                    final story = _shopStories[index];
                    final imageUrl = story['content'] ?? story['image_url'] ?? story['image'] ?? '';
                    final isViewed = story['is_viewed'] ?? false;
                    final caption = story['caption'] ?? '';
                    final type = story['type'] ?? 'image';
                    
                    return GestureDetector(
                      onTap: () {
                        _showStoryViewer(story, index);
                      },
                      child: Container(
                        margin: const EdgeInsets.only(right: 12),
                        width: storySize,
                        child: Column(
                          children: [
                            Container(
                              width: storySize,
                              height: storySize,
                              padding: const EdgeInsets.all(3),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: isViewed ? null : AppColors.primaryGradient,
                                color: isViewed ? Colors.grey.shade300 : null,
                              ),
                              child: Stack(
                                children: [
                                  CircleAvatar(
                                    radius: storySize / 2 - 3,
                                    backgroundImage: CachedNetworkImageProvider(
                                      _getFullImageUrl(imageUrl),
                                    ),
                                    backgroundColor: AppColors.backgroundLight,
                                  ),
                                  if (type == 'video')
                                    Positioned(
                                      bottom: 0,
                                      right: 0,
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.play_arrow,
                                          size: 12,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              caption.isNotEmpty ? caption : 'Story',
                              style: const TextStyle(fontSize: 11),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

            // TabBarView
            Expanded(
              child: TabBarView(
                children: [
                  _buildProductsTab(crossAxisCount),
                  _buildReelsTab(),
                  _buildReviewsTab(isLoggedIn),
                  _buildAboutTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductsTab(int crossAxisCount) {
    if (_products.isEmpty) {
      return const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.inventory, size: 64, color: AppColors.textTertiary),
        SizedBox(height: 16),
        Text('Aucun produit disponible'),
      ]));
    }
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 12,
        mainAxisSpacing: 16,
        childAspectRatio: 0.7,
      ),
      itemCount: _products.length,
      itemBuilder: (context, index) {
        final product = _products[index];
        return ShopProductCard(
          product: product,
          onTap: () => context.push('${AppRoutes.productDetail}/${product['id']}'),
        );
      },
    );
  }

  Widget _buildReelsTab() {
    if (_reels.isEmpty) {
      return const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.video_library, size: 64, color: AppColors.textTertiary),
        SizedBox(height: 16),
        Text('Aucune vidéo disponible'),
      ]));
    }
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.8,
      ),
      itemCount: _reels.length,
      itemBuilder: (context, index) {
        final reel = _reels[index];
        final thumbnail = reel['thumbnail'];
        return GestureDetector(
          onTap: () => context.push('${AppRoutes.videoPlayer}/${reel['id']}'),
          child: Container(
            decoration: BoxDecoration(color: AppColors.backgroundLight, borderRadius: BorderRadius.circular(12)),
            child: Column(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                    child: thumbnail != null && thumbnail.toString().isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: _getFullImageUrl(thumbnail),
                            fit: BoxFit.cover,
                            width: double.infinity,
                          )
                        : const Center(child: Icon(Icons.play_circle_outline, size: 50)),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Text(
                    reel['title'] ?? 'Vidéo',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildReviewsTab(bool isLoggedIn) {
    if (_isLoadingReviews) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }

    if (_reviews.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.rate_review, size: 64, color: AppColors.textTertiary),
            const SizedBox(height: 16),
            const Text('Aucun avis'),
            if (isLoggedIn) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _showAddReviewDialog,
                icon: const Icon(Icons.rate_review),
                label: const Text('Donner votre avis'),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              ),
            ],
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _reviews.length,
      itemBuilder: (context, index) {
        final review = _reviews[index];
        final userName = review['user_name'] ?? 'Anonyme';
        final rating = (review['rating'] ?? 0).toDouble();
        final comment = review['comment'] ?? '';
        final createdAt = review['created_at'] ?? '';
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: AppColors.primary,
                      child: Text(userName.isNotEmpty ? userName[0].toUpperCase() : '?'),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: Text(userName, style: const TextStyle(fontWeight: FontWeight.bold))),
                    Text(_formatDate(createdAt), style: const TextStyle(fontSize: 11)),
                  ],
                ),
                const SizedBox(height: 8),
                RatingStars(rating: rating, size: 12),
                const SizedBox(height: 8),
                Text(comment, style: const TextStyle(fontSize: 14)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAboutTab() {
    final shop = _shop!;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('À propos', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Text(shop['description'] ?? 'Aucune description', style: const TextStyle(fontSize: 14)),
          const SizedBox(height: 24),
          _buildInfoRow('Ville', shop['city'] ?? 'Non renseigné'),
          _buildInfoRow('Pays', shop['country'] ?? 'Non renseigné'),
          _buildInfoRow('Téléphone', shop['phone'] ?? 'Non renseigné'),
          _buildInfoRow('Email', shop['email'] ?? 'Non renseigné'),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 80, child: Text(label, style: const TextStyle(color: AppColors.textSecondary))),
          Expanded(child: Text(value, style: const TextStyle(color: AppColors.textPrimary))),
        ],
      ),
    );
  }
}
