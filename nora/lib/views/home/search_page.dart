import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../config/app_colors.dart';
import '../../config/routes.dart';
import '../../services/product_api_service.dart';
import '../../services/user_habit_api_service.dart';
import '../../services/storage_service.dart';
import '../../widgets/home/product_card.dart';
import '../../widgets/tracking_behavior.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> with SearchTrackingMixin {
  final ProductApiService _productApiService = ProductApiService();
  final UserHabitApiService _habitApiService = UserHabitApiService();
  final TextEditingController _searchController = TextEditingController();
  
  List<dynamic> _searchResults = [];
  List<String> _recentSearches = [];
  List<dynamic> _trendingProducts = [];
  
  bool _isSearching = false;
  bool _isLoading = false;
  String? _token;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _loadToken();
    _loadRecentSearches();
    _loadTrendingProducts();
  }

  Future<void> _loadToken() async {
    _token = await StorageService().getToken();
  }

  Future<void> _loadRecentSearches() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final searches = prefs.getStringList('recent_searches') ?? [];
      setState(() {
        _recentSearches = searches.take(5).toList();
      });
    } catch (e) {
      debugPrint('Erreur chargement recherches récentes: $e');
    }
  }

  Future<void> _saveRecentSearch(String query) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      List<String> searches = prefs.getStringList('recent_searches') ?? [];
      
      // Supprimer si déjà présent
      searches.remove(query);
      // Ajouter au début
      searches.insert(0, query);
      // Garder seulement les 10 dernières
      if (searches.length > 10) {
        searches = searches.sublist(0, 10);
      }
      
      await prefs.setStringList('recent_searches', searches);
      _loadRecentSearches();
    } catch (e) {
      debugPrint('Erreur sauvegarde recherche: $e');
    }
  }

  Future<void> _clearRecentSearches() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('recent_searches');
      setState(() {
        _recentSearches = [];
      });
    } catch (e) {
      debugPrint('Erreur effacement recherches: $e');
    }
  }

  Future<void> _loadTrendingProducts() async {
    try {
      final result = await _productApiService.getTrendingByInterests(
        limit: 5,
        token: _token,
      );
      if (result['success'] && result['products'] != null) {
        setState(() {
          _trendingProducts = result['products'];
        });
      }
    } catch (e) {
      debugPrint('Erreur chargement tendances: $e');
    }
  }

  void _onSearchChanged(String query) {
    if (_debounceTimer?.isActive ?? false) _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      if (query.isNotEmpty) {
        _performSearch(query);
      }
    });
  }

  Future<void> _performSearch(String query) async {
    if (query.isEmpty) return;
    
    setState(() {
      _isSearching = true;
      _isLoading = true;
    });
    
    // Sauvegarder la recherche localement
    await _saveRecentSearch(query);
    
    // Tracker la recherche via le mixin
    await trackSearch(
      query: query,
      source: 'search_page',
    );
    
    try {
      final result = await _productApiService.getProducts(search: query);
      if (result['success'] && result['products'] != null) {
        final results = result['products'];
        setState(() {
          _searchResults = results;
          _isLoading = false;
        });
        
        // Tracker avec le nombre de résultats
        await trackSearch(
          query: query,
          resultsCount: results.length,
          source: 'search_page',
        );
      } else {
        setState(() {
          _searchResults = [];
          _isLoading = false;
        });
        
        // Tracker avec 0 résultat
        await trackSearch(
          query: query,
          resultsCount: 0,
          source: 'search_page',
        );
      }
    } catch (e) {
      debugPrint('Erreur recherche: $e');
      setState(() {
        _searchResults = [];
        _isLoading = false;
      });
    }
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _isSearching = false;
      _searchResults = [];
    });
  }

  void _onProductTap(int productId) async {
    // Tracker le clic sur produit via le mixin ProductTrackingMixin
    // Mais on peut aussi utiliser directement le service
    if (_token != null) {
      await _habitApiService.trackAction(
        token: _token!,
        actionType: 'click',
        entityType: 'product',
        entityId: productId.toString(),
        context: {'source': 'search_page'},
      );
    }
    context.push('${AppRoutes.productDetail}/$productId');
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
          onPressed: () => context.pop(),
        ),
        title: Container(
          height: 45,
          decoration: BoxDecoration(
            color: AppColors.backgroundLight,
            borderRadius: BorderRadius.circular(12),
          ),
          child: TextField(
            controller: _searchController,
            autofocus: true,
            onChanged: _onSearchChanged,
            onSubmitted: _performSearch,
            decoration: InputDecoration(
              hintText: 'Rechercher un produit, une boutique...',
              hintStyle: TextStyle(color: AppColors.textTertiary),
              prefixIcon: const Icon(Icons.search, color: AppColors.textTertiary),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, color: AppColors.textTertiary),
                      onPressed: _clearSearch,
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isSearching) {
      if (_isLoading) {
        return const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        );
      }
      
      if (_searchResults.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.search_off, size: 64, color: AppColors.textTertiary),
              const SizedBox(height: 16),
              Text(
                'Aucun résultat trouvé',
                style: TextStyle(
                  fontSize: 16,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Essayez avec d\'autres mots-clés',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textTertiary,
                ),
              ),
            ],
          ),
        );
      }
      
      return _buildResultsList();
    }
    
    return _buildInitialContent();
  }

  Widget _buildInitialContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Recherches récentes
          if (_recentSearches.isNotEmpty) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Recherches récentes',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                GestureDetector(
                  onTap: _clearRecentSearches,
                  child: const Text(
                    'Effacer tout',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textTertiary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: _recentSearches.map((search) => GestureDetector(
                onTap: () {
                  _searchController.text = search;
                  _performSearch(search);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.backgroundLight,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.history, size: 16, color: AppColors.textSecondary),
                      const SizedBox(width: 8),
                      Text(
                        search,
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              )).toList(),
            ),
            const SizedBox(height: 24),
          ],
          
          // Produits tendances
          if (_trendingProducts.isNotEmpty) ...[
            const Text(
              'Tendances actuelles',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 250,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: _trendingProducts.map((product) => SizedBox(
                  width: 160,
                  child: ProductCard(
                    product: product,
                    onTap: () => _onProductTap(product['id']),
                  ),
                )).toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildResultsList() {
    final screenWidth = MediaQuery.of(context).size.width;
    final crossAxisCount = screenWidth > 600 ? 3 : 2;
    final childAspectRatio = screenWidth > 600 ? 0.75 : 0.72;

    return Padding(
      padding: const EdgeInsets.all(12),
      child: GridView.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: 12,
          mainAxisSpacing: 16,
          childAspectRatio: childAspectRatio,
        ),
        itemCount: _searchResults.length,
        itemBuilder: (context, index) {
          final product = _searchResults[index];
          return ProductCard(
            product: product,
            onTap: () => _onProductTap(product['id']),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }
}