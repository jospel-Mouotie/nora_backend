import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:nora/views/categories/filters_bottom_sheet.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../config/app_colors.dart';
import '../../config/app_constants.dart';
import '../../config/routes.dart';
import '../../services/api_service.dart';
import '../../services/category_api_service.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/home/product_card.dart';

class CategoryProductsPage extends StatefulWidget {
  final int categoryId;
  final String categoryName;
  final int? subcategoryId;
  final String sortBy;

  const CategoryProductsPage({
    super.key,
    required this.categoryId,
    required this.categoryName,
    this.subcategoryId,
    this.sortBy = 'recent',
  });

  @override
  State<CategoryProductsPage> createState() => _CategoryProductsPageState();
}

class _CategoryProductsPageState extends State<CategoryProductsPage> {
  final ApiService _apiService = ApiService();
  final CategoryApiService _categoryApiService = CategoryApiService();
  List<dynamic> _products = [];
  bool _isLoading = true;
  bool _hasMore = true;
  int _currentPage = 1;
  final int _limit = 20;
  
  Map<String, dynamic>? _category;
  
  late int _currentCategoryId;
  late int? _currentSubcategoryId;
  late String _currentSortBy;

  @override
  void initState() {
    super.initState();
    _currentCategoryId = widget.categoryId;
    _currentSubcategoryId = widget.subcategoryId;
    _currentSortBy = widget.sortBy;
    _loadCategory();
    _loadProducts();
  }

  Future<void> _loadCategory() async {
    try {
      final result = await _categoryApiService.getCategories();
      if (result['success'] && result['categories'] != null) {
        final categories = result['categories'] as List;
        for (var cat in categories) {
          if (cat['id'] == _currentCategoryId) {
            setState(() {
              _category = cat;
            });
            return;
          }
          // Vérifier aussi dans les sous-catégories
          if (cat['children'] != null) {
            for (var child in cat['children']) {
              if (child['id'] == _currentCategoryId) {
                setState(() {
                  _category = child;
                });
                return;
              }
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Erreur chargement catégorie: $e');
    }
  }

  String _getFullImageUrl(String? path) {
    if (path == null || path.isEmpty) return '';
    if (path.startsWith('http')) return path;
    if (path.startsWith('/storage')) {
      return '${AppConstants.apiBaseUrl.replaceAll('/api', '')}$path';
    }
    return '${AppConstants.apiBaseUrl.replaceAll('/api', '')}/storage/$path';
  }

  Future<void> _loadProducts({bool refresh = false}) async {
    if (refresh) {
      _currentPage = 1;
      _hasMore = true;
      setState(() => _products = []);
    }
    
    if (!_hasMore) return;
    
    setState(() => _isLoading = true);
    
    try {
      final result = await _apiService.getProducts(
        limit: _limit,
        categoryId: _currentSubcategoryId ?? _currentCategoryId,
        sort: _currentSortBy,
      );
      
      if (result['success'] && result['products'] != null) {
        final newProducts = result['products'] as List;
        setState(() {
          if (refresh) {
            _products = newProducts;
          } else {
            _products.addAll(newProducts);
          }
          _hasMore = newProducts.length >= _limit;
          _isLoading = false;
        });
      } else {
        // Données de test
        setState(() {
          _products = _getTestProducts();
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _products = _getTestProducts();
        _isLoading = false;
      });
    }
  }

  List<Map<String, dynamic>> _getTestProducts() {
    return [
      {'id': 1, 'name': 'Sac à main élégant', 'price': 32000, 'original_price': 40000, 'discount': 20, 'rating': 4.8, 'reviews_count': 123, 'shop_name': 'Green Style', 'images': []},
      {'id': 2, 'name': 'Robe longue plissée', 'price': 18700, 'original_price': 22000, 'discount': 15, 'rating': 4.6, 'reviews_count': 98, 'shop_name': 'Fashion Luxe', 'images': []},
      {'id': 3, 'name': 'Baskets blanches', 'price': 15000, 'original_price': null, 'discount': null, 'rating': 4.7, 'reviews_count': 156, 'shop_name': 'Sport Style', 'images': []},
      {'id': 4, 'name': 'Veste en jean oversize', 'price': 16200, 'original_price': 18000, 'discount': 10, 'rating': 4.5, 'reviews_count': 76, 'shop_name': 'Street Wear', 'images': []},
      {'id': 5, 'name': 'Lunettes de soleil', 'price': 7500, 'original_price': null, 'discount': null, 'rating': 4.4, 'reviews_count': 64, 'shop_name': 'Fashion Luxe', 'images': []},
      {'id': 6, 'name': 'Parfum féminin', 'price': 12000, 'original_price': null, 'discount': null, 'rating': 4.7, 'reviews_count': 88, 'shop_name': 'Beauty Shop', 'images': []},
    ];
  }

  void _showFilters() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => FiltersBottomSheet(
        categoryId: _currentCategoryId,
        categoryName: widget.categoryName,
        onApplyFilters: (subcategoryId, sortBy) {
          setState(() {
            _currentSubcategoryId = subcategoryId;
            _currentSortBy = sortBy;
          });
          _loadProducts(refresh: true);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final crossAxisCount = screenWidth > 600 ? 3 : 2;
    final childAspectRatio = screenWidth > 600 ? 0.75 : 0.72;
    final categoryImageUrl = _category != null ? _getFullImageUrl(_category!['image']) : '';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            if (categoryImageUrl.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: CachedNetworkImage(
                    imageUrl: categoryImageUrl,
                    width: 32,
                    height: 32,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      width: 32,
                      height: 32,
                      color: AppColors.backgroundLight,
                      child: const Icon(Icons.category, size: 16, color: AppColors.textSecondary),
                    ),
                    errorWidget: (context, url, error) => Container(
                      width: 32,
                      height: 32,
                      color: AppColors.backgroundLight,
                      child: const Icon(Icons.category, size: 16, color: AppColors.textSecondary),
                    ),
                  ),
                ),
              ),
            Expanded(
              child: Text(
                widget.categoryName,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list, color: AppColors.textPrimary),
            onPressed: _showFilters,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => _loadProducts(refresh: true),
        child: _isLoading && _products.isEmpty
            ? const Center(
                child: CircularProgressIndicator(
                  color: AppColors.primary,
                ),
              )
            : Column(
                children: [
                  // Barre d'info des filtres actifs
                  if (_currentSubcategoryId != null || _currentSortBy != 'recent')
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      color: AppColors.backgroundLight,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            const Text(
                              'Filtres actifs: ',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            if (_currentSubcategoryId != null)
                              Container(
                                margin: const EdgeInsets.only(right: 8),
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Text(
                                  'Sous-catégorie',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            if (_currentSortBy != 'recent')
                              Container(
                                margin: const EdgeInsets.only(right: 8),
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  _getSortLabel(_currentSortBy),
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  _currentSubcategoryId = null;
                                  _currentSortBy = 'recent';
                                });
                                _loadProducts(refresh: true);
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.error,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Text(
                                  'Effacer tout',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  
                  // Grille produits
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: GridView.builder(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 16,
                          childAspectRatio: childAspectRatio,
                        ),
                        itemCount: _products.length,
                        itemBuilder: (context, index) {
                          final product = _products[index];
                          return ProductCard(
                            product: product,
                            onTap: () {
                              context.push('${AppRoutes.productDetail}/${product['id']}');
                            },
                            showDiscountBadge: true,
                          );
                        },
                      ),
                    ),
                  ),
                  
                  // Chargement plus
                  if (_isLoading && _products.isNotEmpty)
                    const Padding(
                      padding: EdgeInsets.all(16),
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                      ),
                    ),
                ],
              ),
      ),
    );
  }

  String _getSortLabel(String sortBy) {
    switch (sortBy) {
      case 'price_asc': return 'Prix croissant';
      case 'price_desc': return 'Prix décroissant';
      case 'rating': return 'Mieux notés';
      case 'popular': return 'Les plus vendus';
      default: return 'Plus récents';
    }
  }
}