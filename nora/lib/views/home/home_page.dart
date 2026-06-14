// lib/views/home/home_page.dart
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../config/app_colors.dart';
import '../../config/app_constants.dart';
import '../../config/routes.dart';
import '../../services/user_api_service.dart';
import '../../services/product_api_service.dart';
import '../../services/user_habit_api_service.dart';
import '../../services/shop_api_service.dart';
import '../../services/video_api_service.dart';
import '../../services/ad_service.dart';
import '../../services/mb_coins_api_service.dart';
import '../../services/category_api_service.dart';
import '../../services/storage_service.dart';
import '../../widgets/bottom_nav_bar.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/home/product_card.dart';
import '../../widgets/ads/ad_banner.dart';
import '../../widgets/tracking_behavior.dart';
import '../../views/categories/filters_bottom_sheet.dart';
import '../../utils/converters.dart';

// Import des sidebars selon le rôle
import '../../widgets/merchant/merchant_sidebar.dart';
import '../../widgets/delivery_driver/driver_sidebar.dart';
import '../../widgets/admin/admin_sidebar.dart';
import 'package:animate_do/animate_do.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with ProductTrackingMixin {
  final UserApiService _userApiService = UserApiService();
  final CategoryApiService _categoryApiService = CategoryApiService();
  final ProductApiService _productApiService = ProductApiService();
  final ShopApiService _shopApiService = ShopApiService();
  final VideoApiService _videoApiService = VideoApiService();
  final AdService _adService = AdService();
  final MbCoinsApiService _mbCoinsApiService = MbCoinsApiService();
  final UserHabitApiService _habitApiService = UserHabitApiService();

  List<dynamic> _categories = [];
  List<dynamic> _recommendedProducts = [];
  List<dynamic> _promotionProducts = [];
  List<dynamic> _reels = [];
  List<dynamic> _allCertifiedShops = []; // Toutes les boutiques certifiées
  List<dynamic> _certifiedShops = []; // Sélection aléatoire
  final List<dynamic> _stories = [];
  List<dynamic> _recentAds = [];
  Map<String, dynamic>? _mbCoinsBalance;

  bool _isLoading = true;
  String? _token;
  List<int> _userInterestIds = [];
  String? _userRole;
  bool _isSidebarOpen = false;

  late PageController _shopsCarouselController;
  int _currentShopIndex = 0;
  final Random _random = Random();

  String _getFullImageUrl(String? path) {
    if (path == null || path.isEmpty) return '';
    if (path.startsWith('http')) return path;
    if (path.startsWith('/storage')) {
      return '${AppConstants.apiBaseUrl.replaceAll('/api', '')}$path';
    }
    return '${AppConstants.apiBaseUrl.replaceAll('/api', '')}/storage/$path';
  }

  String _getRemainingTime() {
    final now = DateTime.now();
    final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);
    final difference = endOfDay.difference(now);

    final hours = difference.inHours;
    final minutes = difference.inMinutes % 60;
    final seconds = difference.inSeconds % 60;

    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  void initState() {
    super.initState();
    _shopsCarouselController = PageController();
    _loadData();
  }

  @override
  void dispose() {
    _shopsCarouselController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    _token = await StorageService().getToken();
    await _loadUserRole();
    await _loadUserInterests();

    await Future.wait([
      _loadCategories(),
      _loadRecommendedProducts(),
      _loadPromotions(),
      _loadReels(),
      _loadCertifiedShops(),
      _loadMbCoinsBalance(),
      _loadRecentAds(),
    ]);

    if (mounted) {
      setState(() => _isLoading = false);
    }

    if (_certifiedShops.isNotEmpty) {
      _startShopsCarousel();
    }
  }

  /// Sélectionne 5 boutiques aléatoires parmi toutes les boutiques certifiées
  void _selectRandomCertifiedShops() {
    if (_allCertifiedShops.isEmpty) {
      _certifiedShops = [];
      return;
    }
    
    // Si on a moins de 5 boutiques, on les prend toutes
    if (_allCertifiedShops.length <= 5) {
      _certifiedShops = List.from(_allCertifiedShops);
    } else {
      // Mélanger la liste et prendre les 5 premières
      final shuffled = List.from(_allCertifiedShops);
      shuffled.shuffle(_random);
      _certifiedShops = shuffled.take(5).toList();
    }
    
    debugPrint('✅ Boutiques certifiées sélectionnées: ${_certifiedShops.length} sur ${_allCertifiedShops.length} total');
  }

  Future<void> _loadUserRole() async {
    if (_token != null) {
      try {
        final result = await _userApiService.getUserProfile(_token!);
        if (result['success'] && result['user'] != null && mounted) {
          setState(() {
            _userRole = result['user']['role'];
          });
        }
      } catch (e) {
        debugPrint('Erreur chargement rôle: $e');
      }
    }
  }

  Future<void> _loadUserInterests() async {
    try {
      final localInterests = await StorageService().getLocalInterests();
      if (localInterests.isNotEmpty) {
        _userInterestIds = localInterests.map((i) => i['category_id'] as int).toList();
      } else if (_token != null) {
        final result = await _userApiService.getUserInterests(_token!);
        if (result['success'] && result['interests'] != null) {
          _userInterestIds = (result['interests'] as List)
              .map((i) => i['category_id'] as int)
              .toList();
        }
      }
      debugPrint('✅ Centres d\'intérêt: $_userInterestIds');
    } catch (e) {
      debugPrint('Erreur chargement intérêts: $e');
    }
  }

  void _startShopsCarousel() {
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted && _certifiedShops.isNotEmpty) {
        if (_currentShopIndex < _certifiedShops.length - 1) {
          _currentShopIndex++;
        } else {
          _currentShopIndex = 0;
        }
        if (_shopsCarouselController.hasClients) {
          _shopsCarouselController.animateToPage(
            _currentShopIndex,
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOut,
          );
        }
        _startShopsCarousel();
      }
    });
  }

  Future<void> _loadCategories() async {
    try {
      final result = await _categoryApiService.getCategories();
      if (!mounted) return;

      if (result['success'] && result['categories'] != null) {
        final categories = result['categories'] as List;
        if (categories.isNotEmpty) {
          categories.sort((a, b) {
            final aId = a['id'] as int;
            final bId = b['id'] as int;
            final aInInterests = _userInterestIds.contains(aId);
            final bInInterests = _userInterestIds.contains(bId);
            if (aInInterests && !bInInterests) return -1;
            if (!aInInterests && bInInterests) return 1;
            return 0;
          });
          setState(() {
            _categories = categories.take(6).toList();
          });
          return;
        }
      }
      setState(() {
        _categories = [];
      });
    } catch (e) {
      debugPrint('Erreur chargement catégories: $e');
      if (mounted) {
        setState(() {
          _categories = [];
        });
      }
    }
  }

  Future<void> _loadRecommendedProducts() async {
    try {
      final result = await _productApiService.getRecommendedProducts(
        limit: 20,
        token: _token,
      );
      if (!mounted) return;

      if (result['success'] && result['products'] != null) {
        final products = result['products'];
        if (products is List && products.isNotEmpty) {
          final filteredProducts = _userInterestIds.isEmpty
              ? products
              : products.where((product) {
                  final categoryId = product['category_id'];
                  final categoryIdInt = categoryId is String
                      ? int.tryParse(categoryId)
                      : categoryId as int?;
                  return categoryIdInt != null && _userInterestIds.contains(categoryIdInt);
                }).toList();

          setState(() {
            _recommendedProducts = filteredProducts.take(10).toList();
          });
          debugPrint('✅ Produits recommandés: ${_recommendedProducts.length}');
          return;
        }
      }

      final fallbackResult = await _productApiService.getProducts(limit: 20);
      if (fallbackResult['success'] && fallbackResult['products'] != null) {
        final products = fallbackResult['products'];
        if (products is List && products.isNotEmpty) {
          setState(() {
            _recommendedProducts = products.take(10).toList();
          });
          return;
        }
      }

      setState(() {
        _recommendedProducts = [];
      });
    } catch (e) {
      debugPrint('Erreur produits recommandés: $e');
      if (mounted) {
        setState(() {
          _recommendedProducts = [];
        });
      }
    }
  }

  Future<void> _loadPromotions() async {
    try {
      final result = await _productApiService.getPromotions();
      if (!mounted) return;

      if (result['success'] && result['products'] != null) {
        final products = result['products'];
        if (products is List && products.isNotEmpty) {
          setState(() {
            _promotionProducts = products;
          });
          debugPrint('✅ Promotions chargées: ${products.length}');
          return;
        }
      }
      setState(() {
        _promotionProducts = [];
      });
    } catch (e) {
      debugPrint('Erreur promotions: $e');
      if (mounted) {
        setState(() {
          _promotionProducts = [];
        });
      }
    }
  }

  Future<void> _loadReels() async {
    try {
      final result = await _videoApiService.getVideos(limit: 5);
      if (!mounted) return;

      if (result['success'] && result['videos'] != null) {
        final videos = result['videos'];
        if (videos is List) {
          setState(() {
            _reels = videos;
          });
          debugPrint('✅ Reels chargés: ${videos.length}');
          return;
        }
      }
      setState(() {
        _reels = [];
      });
    } catch (e) {
      debugPrint('Erreur reels: $e');
      if (mounted) {
        setState(() {
          _reels = [];
        });
      }
    }
  }

  Future<void> _loadCertifiedShops() async {
    try {
      final result = await _shopApiService.getShops(limit: 50); // Récupérer plus de boutiques
      if (!mounted) return;

      if (result['success'] && result['shops'] != null) {
        final shops = result['shops'];
        if (shops is List && shops.isNotEmpty) {
          // Récupérer TOUTES les boutiques certifiées
          final allCertified = shops.where((shop) =>
              shop['certifiee'] == true || shop['is_verified'] == true
          ).toList();
          
          debugPrint('✅ Total boutiques certifiées trouvées: ${allCertified.length}');
          
          setState(() {
            _allCertifiedShops = allCertified;
          });
          
          // Sélectionner 5 boutiques aléatoires
          _selectRandomCertifiedShops();
          return;
        }
      }
      setState(() {
        _allCertifiedShops = [];
        _certifiedShops = [];
      });
    } catch (e) {
      debugPrint('Erreur boutiques certifiées: $e');
      if (mounted) {
        setState(() {
          _allCertifiedShops = [];
          _certifiedShops = [];
        });
      }
    }
  }

  Future<void> _loadMbCoinsBalance() async {
    if (_token == null) return;
    try {
      final result = await _mbCoinsApiService.getMbCoinsBalance(_token!);
      if (result['success'] && result['balance'] != null && mounted) {
        setState(() {
          _mbCoinsBalance = result['balance'];
        });
      }
    } catch (e) {
      debugPrint('Erreur MB Coins: $e');
    }
  }

  Future<void> _loadRecentAds() async {
    try {
      final result = await _adService.getActiveAds();
      if (result['success'] && result['ads'] != null && mounted) {
        final ads = result['ads'] as List;
        setState(() {
          _recentAds = ads.take(5).toList();
        });
      } else if (mounted) {
        setState(() {
          _recentAds = [];
        });
      }
    } catch (e) {
      debugPrint('Erreur chargement pubs: $e');
      if (mounted) {
        setState(() {
          _recentAds = [];
        });
      }
    }
  }

  void _onReelTap(Map<String, dynamic> reel) {
    context.push('${AppRoutes.reels}?videoId=${reel['id']}');
  }

  void _onShopTap(Map<String, dynamic> shop) {
    context.push('${AppRoutes.shopDetail}/${shop['id']}');
  }

  void _onProductTap(Map<String, dynamic> product, String section) {
    trackProductClick(
      productId: product['id'],
      source: 'home_page',
      section: section,
    );
    context.push('${AppRoutes.productDetail}/${product['id']}');
  }

  void _onCategoryTap(Map<String, dynamic> category) {
    final categoryId = category['id'];
    final categoryName = toStringSafe(category['name']);
    final children = category['children'];
    final hasChildren = children != null && children is List && children.isNotEmpty;

    if (hasChildren) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (context) => FiltersBottomSheet(
          categoryId: categoryId,
          categoryName: categoryName,
          onApplyFilters: (subcategoryId, sortBy) {
            Navigator.pop(context);
            String url = '${AppRoutes.categoryProducts}/$categoryId?name=${Uri.encodeComponent(categoryName)}&sort=$sortBy';
            if (subcategoryId != null) {
              url += '&subcategory=$subcategoryId';
            }
            context.push(url);
          },
        ),
      );
    } else {
      context.push('${AppRoutes.categoryProducts}/$categoryId?name=${Uri.encodeComponent(categoryName)}');
    }
  }

  void _onSeeAllCategories() {
    context.push(AppRoutes.categories);
  }

  void _onSeeAllProducts() {
    context.push(AppRoutes.search);
  }

  void _toggleSidebar() {
    setState(() {
      _isSidebarOpen = !_isSidebarOpen;
    });
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Déconnexion'),
        content: const Text('Voulez-vous vraiment vous déconnecter ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: const Text('Se déconnecter'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    await StorageService().clearAll();

    if (mounted) {
      context.go(AppRoutes.login);
    }
  }

  void _navigateAndCloseSidebar(String route) {
    setState(() {
      _isSidebarOpen = false;
    });
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        context.push(route);
      }
    });
  }

  Future<bool> _onWillPop() async {
    if (_isSidebarOpen) {
      setState(() {
        _isSidebarOpen = false;
      });
      return false;
    }

    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
      return false;
    }

    final shouldExit = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Quitter l\'application'),
        content: const Text('Voulez-vous vraiment quitter MBOA SHOP ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: const Text('Quitter'),
          ),
        ],
      ),
    );

    return shouldExit ?? false;
  }

  Widget _buildSidebar() {
    if (_userRole == 'commercant') {
      return MerchantSidebar(
        selectedIndex: 0,
        onItemSelected: (index) {
          switch (index) {
            case 0:
              _navigateAndCloseSidebar(AppRoutes.merchantDashboard);
              break;
            case 1:
              _navigateAndCloseSidebar(AppRoutes.merchantProducts);
              break;
            case 2:
              _navigateAndCloseSidebar(AppRoutes.merchantOrders);
              break;
            case 3:
              _navigateAndCloseSidebar(AppRoutes.merchantVideos);
              break;
            case 4:
              _navigateAndCloseSidebar(AppRoutes.merchantStats);
              break;
            case 5:
              _navigateAndCloseSidebar(AppRoutes.createAd);
              break;
            case 6:
              _navigateAndCloseSidebar(AppRoutes.settings);
              break;
            case 7:
              _logout();
              break;
          }
        },
      );
    } else if (_userRole == 'livreur') {
      return DriverSidebar(
        selectedIndex: 0,
        onItemSelected: (index) {
          switch (index) {
            case 0:
              _navigateAndCloseSidebar(AppRoutes.driverDashboard);
              break;
            case 1:
              _navigateAndCloseSidebar(AppRoutes.driverMissions);
              break;
            case 2:
              _navigateAndCloseSidebar(AppRoutes.driverEarnings);
              break;
            case 3:
              _navigateAndCloseSidebar(AppRoutes.driverHistory);
              break;
            case 4:
              _navigateAndCloseSidebar(AppRoutes.settings);
              break;
          }
        },
      );
    } else if (_userRole == 'admin') {
      return AdminSidebar(
        selectedIndex: 0,
        onItemSelected: (index) {
          switch (index) {
            case 0:
              _navigateAndCloseSidebar(AppRoutes.adminDashboard);
              break;
            case 1:
              _navigateAndCloseSidebar(AppRoutes.merchantShop);
              break;
            case 2:
              _navigateAndCloseSidebar(AppRoutes.merchantProducts);
              break;
            case 3:
              _navigateAndCloseSidebar(AppRoutes.merchantVideos);
              break;
            case 4:
              _navigateAndCloseSidebar(AppRoutes.merchantOrders);
              break;
            case 5:
              _navigateAndCloseSidebar(AppRoutes.merchantStats);
              break;
            case 6:
              _navigateAndCloseSidebar(AppRoutes.adminUsers);
              break;
            case 7:
              _navigateAndCloseSidebar(AppRoutes.adminShops);
              break;
            case 8:
              _navigateAndCloseSidebar(AppRoutes.adminValidations);
              break;
            case 9:
              _navigateAndCloseSidebar(AppRoutes.adminCategories);
              break;
            case 10:
              _navigateAndCloseSidebar(AppRoutes.createAd);
              break;
            case 11:
              _navigateAndCloseSidebar(AppRoutes.settings);
              break;
            case 12:
              _logout();
              break;
          }
        },
      );
    }
    return const SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final crossAxisCount = screenWidth > 600 ? 3 : 2;
    final childAspectRatio = screenWidth > 600 ? 0.75 : 0.72;
    final showSidebar = _userRole != null && _userRole != 'client';

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: CustomAppBar(
          showLogo: false,
          showBackButton: false,
          onMenuPressed: showSidebar ? _toggleSidebar : null,
          actions: [
            IconButton(
              icon: const Icon(Icons.search, color: AppColors.textPrimary, size: 22),
              onPressed: () {
                context.push(AppRoutes.search);
              },
            ),
            Stack(
              children: [
                IconButton(
                  icon: const Icon(Icons.notifications_none, color: AppColors.textPrimary, size: 22),
                  onPressed: () {},
                ),
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppColors.promotion,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        body: Stack(
          children: [
            RefreshIndicator(
              onRefresh: _loadData,
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                      ),
                    )
                  : SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Carte MB Coins
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                gradient: AppColors.primaryGradient,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _mbCoinsBalance != null
                                            ? '${_mbCoinsBalance!['formatted_balance'] ?? _mbCoinsBalance!['balance']} MB'
                                            : '0 MB',
                                        style: const TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      const Text(
                                        'Gagnez des récompenses',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Colors.white70,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: const Text(
                                      'Actif',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),

                          // Section Stories (si disponible)
                          if (_stories.isNotEmpty) ...[
                            SizedBox(
                              height: 100,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                itemCount: _stories.length,
                                itemBuilder: (context, index) {
                                  final story = _stories[index];
                                  return _buildStoryItem(story);
                                },
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],

                          // BOUTIQUES CERTIFIÉES (sélection aléatoire)
                          if (_certifiedShops.isNotEmpty) ...[
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 16),
                              child: Text(
                                'Boutiques certifiées',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            SizedBox(
                              height: 200,
                              child: PageView.builder(
                                controller: _shopsCarouselController,
                                onPageChanged: (index) {
                                  if (mounted) {
                                    setState(() {
                                      _currentShopIndex = index;
                                    });
                                  }
                                },
                                itemCount: _certifiedShops.length,
                                itemBuilder: (context, index) {
                                  final shop = _certifiedShops[index];
                                  return _buildCertifiedShopCarouselItem(shop);
                                },
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(
                                _certifiedShops.length,
                                (index) => Container(
                                  margin: const EdgeInsets.symmetric(horizontal: 4),
                                  width: _currentShopIndex == index ? 24 : 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(4),
                                    color: _currentShopIndex == index
                                        ? AppColors.primary
                                        : AppColors.border,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                          ],

                          // Catégories
                          if (_categories.isNotEmpty)
                            SizedBox(
                              height: 44,
                              child: ListView(
                                scrollDirection: Axis.horizontal,
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                children: [
                                  ..._categories.map((cat) => _buildCategoryChip(cat)),
                                  _buildSeeAllButton('Voir plus', _onSeeAllCategories),
                                ],
                              ),
                            ),
                          const SizedBox(height: 24),

                          // Reels
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Reels pour vous',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () {
                                    context.push(AppRoutes.reels);
                                  },
                                  child: const Text(
                                    'Voir tout >',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          if (_reels.isNotEmpty)
                            SizedBox(
                              height: 200,
                              child: ListView(
                                scrollDirection: Axis.horizontal,
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                children: _reels.map((reel) => _buildReelPreview(
                                  reel,
                                  () => _onReelTap(reel),
                                )).toList(),
                              ),
                            )
                          else
                            const Padding(
                              padding: EdgeInsets.all(16),
                              child: Center(
                                child: Text(
                                  'Aucun reel disponible',
                                  style: TextStyle(color: AppColors.textSecondary),
                                ),
                              ),
                            ),
                          const SizedBox(height: 24),

                          // PROMOTIONS
                          if (_promotionProducts.isNotEmpty) ...[
                            FadeInLeft(
                              duration: const Duration(milliseconds: 600),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(Icons.timer, color: AppColors.promotion, size: 16),
                                        const SizedBox(width: 4),
                                        Text(
                                          _getRemainingTime(),
                                          style: const TextStyle(
                                            color: AppColors.promotion,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const Text(
                                      'Promotions',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: () {
                                        context.push('/promotions/all');
                                      },
                                      child: const Text(
                                        'Voir plus >',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              height: 220,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                itemCount: _promotionProducts.length,
                                itemBuilder: (context, index) {
                                  final product = _promotionProducts[index];
                                  return Container(
                                    width: 160,
                                    margin: const EdgeInsets.symmetric(horizontal: 4),
                                    child: ProductCard(
                                      product: product,
                                      showDiscountBadge: true,
                                      onTap: () => _onProductTap(product, 'promotions'),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                          const SizedBox(height: 16),

                          // Recommandés pour vous
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Recommandés pour vous',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                GestureDetector(
                                  onTap: _onSeeAllProducts,
                                  child: const Text(
                                    'Voir tout >',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          if (_recommendedProducts.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              child: GridView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: crossAxisCount,
                                  crossAxisSpacing: 12,
                                  mainAxisSpacing: 16,
                                  childAspectRatio: childAspectRatio,
                                ),
                                itemCount: _recommendedProducts.length,
                                itemBuilder: (context, index) {
                                  final product = _recommendedProducts[index];
                                  return ProductCard(
                                    product: product,
                                    onTap: () => _onProductTap(product, 'recommended'),
                                  );
                                },
                              ),
                            )
                          else
                            const Padding(
                              padding: EdgeInsets.all(16),
                              child: Center(
                                child: Text(
                                  'Aucun produit recommandé',
                                  style: TextStyle(color: AppColors.textSecondary),
                                ),
                              ),
                            ),

                          // BANNIÈRE PUBLICITAIRE
                          const AdBanner(position: 'bottom'),
                          const SizedBox(height: 24),

                          // Section dernières publicités
                          if (_recentAds.isNotEmpty) ...[
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Dernières offres et publicités',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () {
                                      context.push(AppRoutes.adsAll);
                                    },
                                    child: const Text(
                                      'Voir plus >',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              height: 180,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                itemCount: _recentAds.length,
                                itemBuilder: (context, index) {
                                  final ad = _recentAds[index];
                                  return _buildAdItem(ad);
                                },
                              ),
                            ),
                          ],
                          const SizedBox(height: 80),
                        ],
                      ),
                    ),
            ),

            // Sidebar overlay
            if (_isSidebarOpen && showSidebar)
              GestureDetector(
                onTap: _toggleSidebar,
                child: Container(
                  color: Colors.black.withOpacity(0.5),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 280,
                        child: _buildSidebar(),
                      ),
                      const Expanded(
                        child: SizedBox(),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
        bottomNavigationBar: const BottomNavBar(currentIndex: 0),
      ),
    );
  }

  Widget _buildCategoryChip(Map<String, dynamic> category) {
    final categoryName = toStringSafe(category['name']);
    final imageUrl = _getFullImageUrl(category['image']);
    final isInInterests = _userInterestIds.contains(category['id']);

    return GestureDetector(
      onTap: () => _onCategoryTap(category),
      child: Container(
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          gradient: isInInterests ? AppColors.primaryGradient : null,
          color: isInInterests ? null : AppColors.background,
          border: Border.all(
            color: isInInterests ? AppColors.primary : AppColors.border,
            width: isInInterests ? 1.5 : 1,
          ),
          borderRadius: BorderRadius.circular(30),
        ),
        child: Row(
          children: [
            if (imageUrl.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: CachedNetworkImage(
                  imageUrl: imageUrl,
                  width: 20,
                  height: 20,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Icon(
                    _getIconForCategory(categoryName),
                    size: 18,
                    color: isInInterests ? Colors.white : AppColors.textPrimary,
                  ),
                  errorWidget: (context, url, error) => Icon(
                    _getIconForCategory(categoryName),
                    size: 18,
                    color: isInInterests ? Colors.white : AppColors.textPrimary,
                  ),
                ),
              )
            else
              Icon(
                _getIconForCategory(categoryName),
                size: 18,
                color: isInInterests ? Colors.white : AppColors.textPrimary,
              ),
            const SizedBox(width: 8),
            Text(
              categoryName,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isInInterests ? Colors.white : AppColors.textPrimary,
              ),
            ),
            if (isInInterests)
              const Padding(
                padding: EdgeInsets.only(left: 6),
                child: Icon(Icons.star, size: 12, color: Colors.white),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSeeAllButton(String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.background,
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(30),
        ),
        child: Row(
          children: [
            const Icon(Icons.arrow_forward, size: 18, color: AppColors.textPrimary),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCertifiedShopCarouselItem(Map<String, dynamic> shop) {
    final shopName = toStringSafe(shop['name']);
    final rating = toDoubleSafe(shop['rating']);
    final description = toStringSafe(shop['description']);
    final banner = shop['photo'] ?? shop['banner'];
    final logo = shop['logo'] ?? shop['photo'];
    final isCertified = shop['certifiee'] == true || shop['is_verified'] == true;

    return GestureDetector(
      onTap: () => _onShopTap(shop),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            children: [
              Positioned.fill(
                child: banner != null && banner.toString().isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: _getFullImageUrl(banner),
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          decoration: BoxDecoration(
                            gradient: AppColors.primaryGradient,
                          ),
                          child: const Center(
                            child: CircularProgressIndicator(color: Colors.white),
                          ),
                        ),
                        errorWidget: (context, url, error) => Container(
                          decoration: BoxDecoration(
                            gradient: AppColors.primaryGradient,
                          ),
                          child: const Center(
                            child: Icon(Icons.store, size: 50, color: Colors.white),
                          ),
                        ),
                      )
                    : Container(
                        decoration: BoxDecoration(
                          gradient: AppColors.primaryGradient,
                        ),
                        child: const Center(
                          child: Icon(Icons.store, size: 50, color: Colors.white),
                        ),
                      ),
              ),
              Container(
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
              ),
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: logo != null && logo.toString().isNotEmpty
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: CachedNetworkImage(
                                      imageUrl: _getFullImageUrl(logo),
                                      fit: BoxFit.cover,
                                      errorWidget: (context, url, error) => const Icon(
                                        Icons.store,
                                        size: 20,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  )
                                : const Icon(
                                    Icons.store,
                                    size: 20,
                                    color: AppColors.primary,
                                  ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  shopName,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(Icons.star, size: 14, color: AppColors.starYellow),
                                    const SizedBox(width: 4),
                                    Text(
                                      rating.toStringAsFixed(1),
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.white70,
                                      ),
                                    ),
                                    if (isCertified) ...[
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: AppColors.primary,
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: const Text(
                                          'Certifiée',
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.white70,
                        ),
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

  Widget _buildReelPreview(Map<String, dynamic> reel, VoidCallback onTap) {
    final title = toStringSafe(reel['title']);
    final thumbnailPath = reel['thumbnail_path'] ?? reel['thumbnail'];
    final thumbnailUrl = _videoApiService.getThumbnailUrl(thumbnailPath?.toString());

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 120,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: AppColors.backgroundLight,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 140,
              width: double.infinity,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                      child: thumbnailUrl.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: thumbnailUrl,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Container(
                                color: AppColors.backgroundLight,
                                child: const Center(
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                              errorWidget: (context, url, error) => Container(
                                color: AppColors.backgroundLight,
                                child: const Icon(
                                  Icons.video_library,
                                  color: AppColors.textTertiary,
                                  size: 32,
                                ),
                              ),
                            )
                          : Container(
                              color: AppColors.backgroundLight,
                              child: const Icon(
                                Icons.video_library,
                                color: AppColors.textTertiary,
                                size: 32,
                              ),
                            ),
                    ),
                  ),
                  Positioned.fill(
                    child: Container(
                      decoration: const BoxDecoration(
                        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                        color: Colors.black26,
                      ),
                    ),
                  ),
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.black45,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white24, width: 1),
                      ),
                      child: const Icon(
                        Icons.play_arrow,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStoryItem(Map<String, dynamic> story) {
    final bool isViewed = story['is_viewed'] ?? false;
    final shop = story['shop'];
    final shopName = shop != null ? shop['name'] : story['shop_name'] ?? '';
    final shopImage = shop != null ? shop['photo'] : story['image'] ?? '';
    final shopId = shop != null ? shop['id'] : story['shop_id'];

    return GestureDetector(
      onTap: () {
        if (shopId != null) {
          context.push('${AppRoutes.shopDetail}/$shopId');
        }
      },
      child: Container(
        margin: const EdgeInsets.only(right: 12),
        width: 70,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: isViewed ? null : AppColors.primaryGradient,
                color: isViewed ? Colors.grey.shade300 : null,
              ),
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                ),
                child: CircleAvatar(
                  radius: 28,
                  backgroundImage: CachedNetworkImageProvider(
                    _getFullImageUrl(shopImage),
                  ),
                  backgroundColor: AppColors.backgroundLight,
                ),
              ),
            ),
            const SizedBox(height: 4),
            SizedBox(
              width: 70,
              child: Text(
                shopName,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdItem(Map<String, dynamic> ad) {
    return GestureDetector(
      onTap: () {
        if (ad['shop_id'] != null) {
          context.push('${AppRoutes.shopDetail}/${ad['shop_id']}');
        } else if (ad['shop'] != null && ad['shop']['id'] != null) {
          context.push('${AppRoutes.shopDetail}/${ad['shop']['id']}');
        }
      },
      child: Container(
        width: 250,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          image: DecorationImage(
            image: CachedNetworkImageProvider(ad['image'] ?? ''),
            fit: BoxFit.cover,
          ),
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.transparent, Colors.black.withOpacity(0.8)],
            ),
          ),
          padding: const EdgeInsets.all(12),
          alignment: Alignment.bottomLeft,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                ad['title'] ?? '',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              Text(
                ad['description'] ?? '',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getIconForCategory(String name) {
    switch (name.toLowerCase()) {
      case 'mode': return Icons.checkroom;
      case 'électronique': return Icons.phone_android;
      case 'electronique': return Icons.phone_android;
      case 'maison': return Icons.home;
      case 'beauté': return Icons.spa;
      case 'beaute': return Icons.spa;
      case 'sports': return Icons.sports_soccer;
      default: return Icons.category;
    }
  }
}