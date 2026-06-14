import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../config/app_colors.dart';
import '../../../config/routes.dart';
import '../../../services/shop_api_service.dart';
import '../../../services/mb_coins_api_service.dart';
import '../../../services/storage_service.dart';
import '../../../widgets/mb_shop/mb_item_card.dart';
import '../../../utils/converters.dart';

class MbShopPage extends StatefulWidget {
  const MbShopPage({super.key});

  @override
  State<MbShopPage> createState() => _MbShopPageState();
}

class _MbShopPageState extends State<MbShopPage> with SingleTickerProviderStateMixin {
  final ShopApiService _shopApiService = ShopApiService();
  final MbCoinsApiService _mbCoinsApiService = MbCoinsApiService();
  late TabController _tabController;
  
  List<dynamic> _items = [];
  List<dynamic> _trendingItems = [];
  List<dynamic> _promotionalItems = [];
  Map<String, dynamic>? _balance;
  bool _isLoading = true;
  String? _token;
  String _selectedCategory = 'all';
  
  final List<Map<String, String>> _categories = [
    {'id': 'all', 'name': 'Tous', 'icon': 'category'},
    {'id': 'badges', 'name': 'Badges', 'icon': 'emoji_events'},
    {'id': 'avatars', 'name': 'Avatars', 'icon': 'person'},
    {'id': 'themes', 'name': 'Thèmes', 'icon': 'palette'},
    {'id': 'vouchers', 'name': 'Bons', 'icon': 'card_giftcard'},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    _token = await StorageService().getToken();
    
    try {
      await Future.wait([
        _loadBalance(),
        _loadItems(),
        _loadTrendingItems(),
        _loadPromotionalItems(),
      ]);
    } catch (e) {
      print('Erreur chargement boutique MB: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadBalance() async {
    if (_token == null) return;
    try {
      final result = await _mbCoinsApiService.getMbCoinsBalance(_token!);
      if (result['success'] && result['balance'] != null) {
        setState(() {
          _balance = result['balance'];
        });
      }
    } catch (e) {
      print('Erreur solde MB: $e');
    }
  }

  Future<void> _loadItems() async {
    try {
      final result = await _shopApiService.getMbShopItems(
        category: _selectedCategory == 'all' ? null : _selectedCategory,
      );
      if (result['success'] && result['items'] != null) {
        setState(() {
          _items = result['items'];
        });
      } else {
        _loadTestItems();
      }
    } catch (e) {
      _loadTestItems();
    }
  }

  void _loadTestItems() {
    setState(() {
      _items = [
        {
          'id': 1,
          'name': 'Badge Premium',
          'description': 'Badge exclusif pour votre profil',
          'price_mb_coins': 500,
          'type': 'digital',
          'category': 'badges',
          'image_url': null,
          'is_available': true,
        },
        {
          'id': 2,
          'name': 'Avatar Ninja',
          'description': 'Avatar Ninja pour votre profil',
          'price_mb_coins': 300,
          'type': 'digital',
          'category': 'avatars',
          'image_url': null,
          'is_available': true,
        },
        {
          'id': 3,
          'name': 'Thème Sombre',
          'description': 'Thème sombre pour l\'application',
          'price_mb_coins': 1000,
          'type': 'digital',
          'category': 'themes',
          'image_url': null,
          'is_available': true,
        },
        {
          'id': 4,
          'name': 'Bon de réduction 10%',
          'description': 'Réduction de 10% sur votre prochain achat',
          'price_mb_coins': 750,
          'type': 'voucher',
          'category': 'vouchers',
          'image_url': null,
          'is_available': true,
        },
      ];
      _trendingItems = _items.take(2).toList();
      _promotionalItems = _items.take(2).toList();
    });
  }

  Future<void> _loadTrendingItems() async {
    try {
      final result = await _shopApiService.getTrendingMbItems();
      if (result['success'] && result['items'] != null) {
        setState(() {
          _trendingItems = result['items'];
        });
      }
    } catch (e) {
      print('Erreur chargement tendances: $e');
    }
  }

  Future<void> _loadPromotionalItems() async {
    try {
      final result = await _shopApiService.getPromotionalMbItems();
      if (result['success'] && result['items'] != null) {
        setState(() {
          _promotionalItems = result['items'];
        });
      }
    } catch (e) {
      print('Erreur chargement promos: $e');
    }
  }

  void _onCategorySelected(String categoryId) {
    setState(() {
      _selectedCategory = categoryId;
    });
    _loadItems();
  }

  void _navigateToItemDetail(Map<String, dynamic> item) {
    context.push('${AppRoutes.mbShopItem}/${item['id']}');
  }

  String _getCategoryIcon(String categoryId) {
    switch (categoryId) {
      case 'badges': return '🏆';
      case 'avatars': return '👤';
      case 'themes': return '🎨';
      case 'vouchers': return '🎁';
      default: return '📦';
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentBalance = toDoubleSafe(_balance?['balance']).toInt();
    final screenWidth = MediaQuery.of(context).size.width;
    final crossAxisCount = screenWidth > 600 ? 3 : 2;

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
          'Boutique MB',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        actions: [
          // Solde MB Coins
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                const Icon(Icons.monetization_on, size: 16, color: Colors.white),
                const SizedBox(width: 4),
                Text(
                  '$currentBalance MB',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          // Historique des achats
          IconButton(
            icon: const Icon(Icons.history, color: AppColors.textPrimary),
            onPressed: () {
              context.push(AppRoutes.mbPurchases);
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : DefaultTabController(
              length: 3,
              child: Column(
                children: [
                  // Catégories
                  Container(
                    height: 50,
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      children: _categories.map((category) {
                        final categoryId = category['id'] ?? 'all';
                        final categoryName = category['name'] ?? 'Tous';
                        final isSelected = _selectedCategory == categoryId;
                        return GestureDetector(
                          onTap: () => _onCategorySelected(categoryId),
                          child: Container(
                            margin: const EdgeInsets.only(right: 12),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: isSelected ? AppColors.primary : AppColors.backgroundLight,
                              border: Border.all(
                                color: isSelected ? AppColors.primary : AppColors.border,
                              ),
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: Row(
                              children: [
                                Text(
                                  _getCategoryIcon(categoryId),
                                  style: const TextStyle(fontSize: 16),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  categoryName,
                                  style: TextStyle(
                                    color: isSelected ? Colors.white : AppColors.textSecondary,
                                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  
                  // TabBar
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    child: TabBar(
                      controller: _tabController,
                      indicatorColor: AppColors.primary,
                      labelColor: AppColors.primary,
                      unselectedLabelColor: AppColors.textSecondary,
                      tabs: const [
                        Tab(text: 'Tendances'),
                        Tab(text: 'Promotions'),
                        Tab(text: 'Tous'),
                      ],
                    ),
                  ),
                  
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        // Tendances
                        _buildItemsGrid(_trendingItems, crossAxisCount),
                        // Promotions
                        _buildItemsGrid(_promotionalItems, crossAxisCount),
                        // Tous les articles
                        _buildItemsGrid(_items, crossAxisCount),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildItemsGrid(List<dynamic> items, int crossAxisCount) {
    if (items.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.shopping_bag_outlined, size: 64, color: AppColors.textTertiary),
            SizedBox(height: 16),
            Text(
              'Aucun article disponible',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.75,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return MbItemCard(
          item: item,
          onTap: () => _navigateToItemDetail(item),
          userBalance: toDoubleSafe(_balance?['balance']).toInt(),
        );
      },
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}