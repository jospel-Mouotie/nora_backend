import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../config/app_colors.dart';
import '../../config/app_constants.dart';
import '../../config/routes.dart';
import '../../services/api_service.dart';
import '../../services/storage_service.dart';
import '../../widgets/bottom_nav_bar.dart';
import '../../widgets/custom_app_bar.dart';
import '../../utils/converters.dart';

class CategoriesPage extends StatefulWidget {
  const CategoriesPage({super.key});

  @override
  State<CategoriesPage> createState() => _CategoriesPageState();
}

class _CategoriesPageState extends State<CategoriesPage> {
  final ApiService _apiService = ApiService();
  List<dynamic> _shops = [];
  List<dynamic> _filteredShops = [];
  List<dynamic> _certifiedShops = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _selectedFilter = 'all';

  final List<Map<String, String>> _filters = [
    {'value': 'all', 'label': 'Toutes'},
    {'value': 'certified', 'label': 'Certifiées'},
    {'value': 'non_certified', 'label': 'Non certifiées'},
  ];

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
    _loadShops();
  }

  Future<void> _loadShops() async {
    setState(() => _isLoading = true);

    final token = await StorageService().getToken();

    try {
      final result = await _apiService.getShops(limit: 100);
      if (result['success'] && result['shops'] != null) {
        final shops = result['shops'] as List;

        // Séparer les boutiques certifiées
        final certified = shops
            .where(
              (shop) =>
                  shop['certifiee'] == true || shop['is_verified'] == true,
            )
            .toList();

        // Les autres boutiques
        final others = shops
            .where(
              (shop) =>
                  !(shop['certifiee'] == true || shop['is_verified'] == true),
            )
            .toList();

        // Trier les boutiques certifiées par rating décroissant
        certified.sort((a, b) {
          final ratingA = (a['rating'] ?? 0).toDouble();
          final ratingB = (b['rating'] ?? 0).toDouble();
          return ratingB.compareTo(ratingA);
        });

        setState(() {
          _certifiedShops = certified;
          _shops = [...certified, ...others];
          _filteredShops = _shops;
          _isLoading = false;
        });
      } else {
        _loadTestShops();
      }
    } catch (e) {
      print('Erreur chargement boutiques: $e');
      _loadTestShops();
    }
  }

  void _loadTestShops() {
    setState(() {
      _certifiedShops = [
        {
          'id': 1,
          'name': 'Green Style',
          'description': 'Boutique de mode tendance',
          'logo': null,
          'rating': 4.8,
          'certifiee': true,
          'products_count': 230,
        },
        {
          'id': 2,
          'name': 'Fashion Luxe',
          'description': 'Luxe et élégance',
          'logo': null,
          'rating': 4.7,
          'certifiee': true,
          'products_count': 180,
        },
      ];
      _shops = [
        ..._certifiedShops,
        {
          'id': 3,
          'name': 'Tech Store',
          'description': 'High-tech et gadgets',
          'logo': null,
          'rating': 4.5,
          'certifiee': false,
          'products_count': 95,
        },
        {
          'id': 4,
          'name': 'Beauty Shop',
          'description': 'Cosmétiques naturels',
          'logo': null,
          'rating': 4.3,
          'certifiee': false,
          'products_count': 67,
        },
      ];
      _filteredShops = _shops;
      _isLoading = false;
    });
  }

  void _filterShops() {
    var filtered = List.from(_shops);

    // Filtrer par recherche
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((shop) {
        final name = shop['name'].toLowerCase();
        final query = _searchQuery.toLowerCase();
        return name.contains(query);
      }).toList();
    }

    // Filtrer par certification
    if (_selectedFilter == 'certified') {
      filtered = filtered
          .where(
            (shop) => shop['certifiee'] == true || shop['is_verified'] == true,
          )
          .toList();
    } else if (_selectedFilter == 'non_certified') {
      filtered = filtered
          .where(
            (shop) =>
                !(shop['certifiee'] == true || shop['is_verified'] == true),
          )
          .toList();
    }

    setState(() {
      _filteredShops = filtered;
    });
  }

  void _onSearchChanged(String value) {
    _searchQuery = value;
    _filterShops();
  }

  void _onFilterChanged(String filter) {
    _selectedFilter = filter;
    _filterShops();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final crossAxisCount = screenWidth > 600 ? 3 : 2;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: CustomAppBar(
        showLogo: true,
        showBackButton: false,
        actions: [
          IconButton(
            icon: const Icon(
              Icons.search,
              color: AppColors.textPrimary,
              size: 22,
            ),
            onPressed: () {
              showSearch(
                context: context,
                delegate: ShopSearchDelegate(_shops),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Barre de recherche
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Rechercher une boutique...',
                prefixIcon: const Icon(
                  Icons.search,
                  color: AppColors.textSecondary,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: AppColors.backgroundLight,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
              ),
              onChanged: _onSearchChanged,
            ),
          ),

          // Filtres
          Container(
            height: 50,
            margin: const EdgeInsets.symmetric(horizontal: 16),
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: _filters.map((filter) {
                final isSelected = _selectedFilter == filter['value'];
                return GestureDetector(
                  onTap: () => _onFilterChanged(filter['value']!),
                  child: Container(
                    margin: const EdgeInsets.only(right: 12),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.backgroundLight,
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.border,
                      ),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Text(
                      filter['label']!,
                      style: TextStyle(
                        color: isSelected
                            ? Colors.white
                            : AppColors.textSecondary,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.w400,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 8),

          // Section boutiques certifiées (en vedette)
          if (_certifiedShops.isNotEmpty &&
              _selectedFilter == 'all' &&
              _searchQuery.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.verified,
                        color: AppColors.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Boutiques certifiées',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 220,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: _certifiedShops
                          .map((shop) => _buildFeaturedShopCard(shop))
                          .toList(),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),

          // Liste des boutiques
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  )
                : _filteredShops.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.store_outlined,
                          size: 64,
                          color: AppColors.textTertiary,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Aucune boutique trouvée',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  )
                : GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 0.8,
                    ),
                    itemCount: _filteredShops.length,
                    itemBuilder: (context, index) {
                      final shop = _filteredShops[index];
                      return _buildShopCard(shop);
                    },
                  ),
          ),
        ],
      ),
      bottomNavigationBar: const BottomNavBar(currentIndex: 1),
    );
  }

  Widget _buildFeaturedShopCard(Map<String, dynamic> shop) {
    final shopName = toStringSafe(shop['name']);
    final rating = toDoubleSafe(shop['rating']);
    final logo = shop['logo'] ?? shop['photo'];
    final isCertified =
        shop['certifiee'] == true || shop['is_verified'] == true;

    return GestureDetector(
      onTap: () {
        context.push('${AppRoutes.shopDetail}/${shop['id']}');
      },
      child: Container(
        width: 160,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(40),
              ),
              child: logo != null && logo.toString().isNotEmpty
                  ? ClipOval(
                      child: CachedNetworkImage(
                        imageUrl: _getFullImageUrl(logo),
                        fit: BoxFit.cover,
                        errorWidget: (context, url, error) => const Icon(
                          Icons.store,
                          color: Colors.white,
                          size: 40,
                        ),
                      ),
                    )
                  : const Icon(Icons.store, color: Colors.white, size: 40),
            ),
            const SizedBox(height: 12),
            // Nom
            Text(
              shopName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            // Étoiles
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.star, size: 12, color: AppColors.starYellow),
                const SizedBox(width: 2),
                Text(
                  rating.toStringAsFixed(1),
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Badge certification
            if (isCertified)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Certifiée',
                  style: TextStyle(
                    fontSize: 10,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildShopCard(Map<String, dynamic> shop) {
    final shopName = toStringSafe(shop['name']);
    final description = toStringSafe(shop['description']);
    final rating = toDoubleSafe(shop['rating']);
    final productsCount = toIntSafe(shop['products_count']);
    final logo = shop['logo'] ?? shop['photo'];
    final isCertified =
        shop['certifiee'] == true || shop['is_verified'] == true;

    return GestureDetector(
      onTap: () {
        context.push('${AppRoutes.shopDetail}/${shop['id']}');
      },
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Logo
            Container(
              height: 120,
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.backgroundLight,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
              ),
              child: logo != null && logo.toString().isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: _getFullImageUrl(logo),
                      fit: BoxFit.cover,
                      width: double.infinity,
                      placeholder: (context, url) => const Center(
                        child: Icon(
                          Icons.store,
                          size: 40,
                          color: AppColors.textTertiary,
                        ),
                      ),
                      errorWidget: (context, url, error) => const Center(
                        child: Icon(
                          Icons.store,
                          size: 40,
                          color: AppColors.textTertiary,
                        ),
                      ),
                    )
                  : const Center(
                      child: Icon(
                        Icons.store,
                        size: 40,
                        color: AppColors.textTertiary,
                      ),
                    ),
            ),
            // Badge certification
            if (isCertified)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 3,
                  ),
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
                        'Certifiée',
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
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    shopName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                        Icons.star,
                        size: 12,
                        color: AppColors.starYellow,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        rating.toStringAsFixed(1),
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.inventory,
                        size: 12,
                        color: AppColors.textTertiary,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        '$productsCount produits',
                        style: const TextStyle(
                          fontSize: 10,
                          color: AppColors.textTertiary,
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

// Delegate pour la recherche
class ShopSearchDelegate extends SearchDelegate {
  final List<dynamic> shops;

  ShopSearchDelegate(this.shops);

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    final results = shops.where((shop) {
      final name = shop['name'].toLowerCase();
      return name.contains(query.toLowerCase());
    }).toList();

    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (context, index) {
        final shop = results[index];
        return ListTile(
          leading: const Icon(Icons.store),
          title: Text(shop['name']),
          subtitle: Text(shop['description'] ?? ''),
          onTap: () {
            close(context, null);
            context.push('${AppRoutes.shopDetail}/${shop['id']}');
          },
        );
      },
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    final suggestions = shops.where((shop) {
      final name = shop['name'].toLowerCase();
      return name.contains(query.toLowerCase());
    }).toList();

    return ListView.builder(
      itemCount: suggestions.length,
      itemBuilder: (context, index) {
        final shop = suggestions[index];
        return ListTile(
          leading: const Icon(Icons.store),
          title: Text(shop['name']),
          subtitle: Text(shop['description'] ?? ''),
          onTap: () {
            query = shop['name'];
            showResults(context);
          },
        );
      },
    );
  }
}
