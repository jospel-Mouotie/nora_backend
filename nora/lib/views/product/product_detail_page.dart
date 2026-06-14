import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../config/app_colors.dart';
import '../../../config/app_constants.dart';
import '../../../config/routes.dart';
import '../../../services/api_service.dart';
import '../../../services/user_habit_api_service.dart';
import '../../../services/storage_service.dart';
import '../../../widgets/product/product_image_carousel.dart';
import '../../../widgets/product/quantity_selector.dart';
import '../../../widgets/product/price_widget.dart';
import '../../../widgets/product/rating_stars.dart';
import '../../../widgets/product/similar_product_card.dart';
import '../../../widgets/tracking_behavior.dart';
import '../../../utils/converters.dart';

class ProductDetailPage extends StatefulWidget {
  final int productId;

  const ProductDetailPage({super.key, required this.productId});

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage>
    with SingleTickerProviderStateMixin, ProductTrackingMixin {
  final ApiService _apiService = ApiService();
  final UserHabitApiService _habitApiService = UserHabitApiService();
  late TabController _tabController;
  
  Map<String, dynamic>? _product;
  List<dynamic> _similarProducts = [];
  List<dynamic> _reviews = [];
  bool _isLoading = true;
  bool _isInCart = false;
  bool _isLoadingReviews = true;
  String? _token;
  
  int _selectedQuantity = 1;
  
  List<dynamic> _variants = [];
  Map<String, List<dynamic>> _groupedVariants = {};
  Map<String, dynamic>? _selectedVariant;
  
  String? _selectedColor;
  String? _selectedSize;
  String? _selectedMaterial;

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
    _tabController = TabController(length: 3, vsync: this);
    _loadToken();
    _loadProductData();
  }

  Future<void> _loadToken() async {
    _token = await StorageService().getToken();
  }

  Future<void> _trackProductView() async {
    await trackProductView(
      productId: widget.productId,
      source: 'product_detail',
    );
  }

  Future<void> _loadProductData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    
    try {
      final result = await _apiService.getProduct(widget.productId);
      
      if (!mounted) return;
      
      if (result['success'] && result['product'] != null) {
        setState(() {
          _product = result['product'];
          _variants = result['product']['variants'] ?? [];
          _groupVariants();
          _isLoading = false;
        });
        
        await _trackProductView();
        
        await Future.wait([
          _loadSimilarProducts(),
          _loadReviews(),
        ]);
      } else {
        _loadTestProduct();
      }
    } catch (e) {
      print('Erreur chargement produit: $e');
      if (mounted) {
        _loadTestProduct();
      }
    }
  }

  Future<void> _loadReviews() async {
    setState(() => _isLoadingReviews = true);
    try {
      final result = await _apiService.getProductReviews(widget.productId);
      if (result['success'] && result['reviews'] != null) {
        setState(() {
          _reviews = result['reviews'];
          _isLoadingReviews = false;
        });
      } else {
        setState(() {
          _reviews = [];
          _isLoadingReviews = false;
        });
      }
    } catch (e) {
      print('Erreur chargement avis: $e');
      setState(() {
        _reviews = [];
        _isLoadingReviews = false;
      });
    }
  }

  void _groupVariants() {
    _groupedVariants = {};
    _selectedColor = null;
    _selectedSize = null;
    _selectedMaterial = null;
    
    for (var variant in _variants) {
      final color = variant['color'];
      final size = variant['size'];
      final material = variant['material'];
      
      if (color != null && color.isNotEmpty) {
        _groupedVariants.putIfAbsent('colors', () => []);
        if (!_groupedVariants['colors']!.any((c) => c['value'] == color)) {
          _groupedVariants['colors']!.add({
            'value': color,
            'name': color,
            'code': _getColorCode(color),
          });
        }
      }
      
      if (size != null && size.isNotEmpty) {
        _groupedVariants.putIfAbsent('sizes', () => []);
        if (!_groupedVariants['sizes']!.any((s) => s['value'] == size)) {
          _groupedVariants['sizes']!.add({'value': size, 'name': size});
        }
      }
      
      if (material != null && material.isNotEmpty) {
        _groupedVariants.putIfAbsent('materials', () => []);
        if (!_groupedVariants['materials']!.any((m) => m['value'] == material)) {
          _groupedVariants['materials']!.add({'value': material, 'name': material});
        }
      }
    }
    
    if (_variants.isNotEmpty && _selectedVariant == null) {
      _selectedVariant = _variants.first;
      _selectedColor = _selectedVariant!['color'];
      _selectedSize = _selectedVariant!['size'];
      _selectedMaterial = _selectedVariant!['material'];
    }
  }

  String _getColorCode(String colorName) {
    switch (colorName.toLowerCase()) {
      case 'rouge': return '#EF4444';
      case 'red': return '#EF4444';
      case 'vert': return '#10B981';
      case 'green': return '#10B981';
      case 'bleu': return '#3B82F6';
      case 'blue': return '#3B82F6';
      case 'jaune': return '#F59E0B';
      case 'yellow': return '#F59E0B';
      case 'noir': return '#1F2937';
      case 'black': return '#1F2937';
      case 'blanc': return '#FFFFFF';
      case 'white': return '#FFFFFF';
      default: return '#6B7280';
    }
  }

  void _selectVariant() {
    final matchingVariant = _variants.firstWhere(
      (variant) {
        bool match = true;
        if (_selectedColor != null && variant['color'] != _selectedColor) match = false;
        if (_selectedSize != null && variant['size'] != _selectedSize) match = false;
        if (_selectedMaterial != null && variant['material'] != _selectedMaterial) match = false;
        return match;
      },
      orElse: () => _variants.first,
    );
    
    if (mounted) {
      setState(() => _selectedVariant = matchingVariant);
    }
  }

  void _onColorSelected(String color) {
    setState(() => _selectedColor = color);
    _selectVariant();
  }

  void _onSizeSelected(String size) {
    setState(() => _selectedSize = size);
    _selectVariant();
  }

  void _onMaterialSelected(String material) {
    setState(() => _selectedMaterial = material);
    _selectVariant();
  }

  void _loadTestProduct() {
    setState(() {
      _product = {
        'id': widget.productId,
        'name': 'Sac à main élégant en cuir',
        'description': 'Sac à main élégant en cuir véritable de haute qualité.',
        'price': 32000,
        'compare_price': 40000,
        'rating': 4.8,
        'reviews_count': 123,
        'sales_count': 256,
        'images': [],
        'shop': {
          'id': 1,
          'name': 'Green Style',
          'rating': 4.8,
          'reviews_count': 1234,
          'followers_count': 12500,
          'is_verified': true,
          'products_count': 230,
          'delivery_time': '24h - 48h',
        },
      };
      _variants = [];
      _groupVariants();
      _isLoading = false;
    });
  }

  Future<void> _loadSimilarProducts() async {
    try {
      final result = await _apiService.getProducts(limit: 10);
      if (!mounted) return;
      
      if (result['success'] && result['products'] != null) {
        setState(() {
          _similarProducts = (result['products'] as List)
              .where((p) => p['id'] != widget.productId)
              .take(10)
              .toList();
        });
      }
    } catch (e) {
      print('Erreur chargement produits similaires: $e');
      if (mounted) {
        setState(() => _similarProducts = []);
      }
    }
  }

  Future<void> _addToCart() async {
    final token = await StorageService().getToken();
    if (token == null) {
      _showLoginRequired();
      return;
    }

    if (!mounted) return;
    setState(() => _isInCart = true);

    try {
      final result = await _apiService.addToCart(
        productId: widget.productId,
        quantity: _selectedQuantity,
        productVariantId: null,
        token: token,
      );

      if (!mounted) return;

      if (result['success']) {
        await trackAddToCart(
          productId: widget.productId,
          quantity: _selectedQuantity,
          variantId: _selectedVariant?['id']?.toString(),
          source: 'product_detail',
        );
        _showSnackBar('Ajouté au panier', isSuccess: true);
      } else {
        _showSnackBar(result['message'] ?? 'Erreur lors de l\'ajout');
      }
    } catch (e) {
      _showSnackBar('Erreur de connexion');
    } finally {
      if (mounted) {
        setState(() => _isInCart = false);
      }
    }
  }
  
  void _buyNow() async {
    final token = await StorageService().getToken();
    if (token == null) {
      _showLoginRequired();
      return;
    }
    
    await trackBuyNow(
      productId: widget.productId,
      quantity: _selectedQuantity,
      source: 'product_detail',
    );
    
    await _addToCart();
    if (mounted) {
      context.push(AppRoutes.checkout);
    }
  }

  void _showLoginRequired() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Connexion requise'),
        content: const Text('Veuillez vous connecter pour ajouter au panier'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              context.push(AppRoutes.login);
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
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _navigateToShop() {
    final shopId = _product!['shop']['id'];
    context.push('${AppRoutes.shopDetail}/$shopId');
  }

  double _getVariantPrice() {
    double basePrice = toDoubleSafe(_product!['price']);
    if (_selectedVariant != null) {
      final adjustment = toDoubleSafe(_selectedVariant!['price_adjustment']);
      basePrice += adjustment;
    }
    return basePrice;
  }

  List<String> _getImages() {
    final images = _product?['images'];
    if (images == null) return [];
    if (images is List) {
      return images.map((e) => e.toString()).toList();
    }
    if (images is String && images.isNotEmpty) {
      return [images];
    }
    return [];
  }

  void _showImageZoom(List<String> images, int initialIndex) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          children: [
            PageView.builder(
              controller: PageController(initialPage: initialIndex),
              itemCount: images.length,
              itemBuilder: (context, index) {
                return InteractiveViewer(
                  minScale: 0.5,
                  maxScale: 4.0,
                  child: CachedNetworkImage(
                    imageUrl: _getFullImageUrl(images[index]),
                    fit: BoxFit.contain,
                    placeholder: (context, url) => const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    ),
                    errorWidget: (context, url, error) => const Center(
                      child: Icon(Icons.broken_image, size: 50, color: Colors.white),
                    ),
                  ),
                );
              },
            ),
            Positioned(
              top: 40,
              right: 16,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _product == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    final product = _product!;
    final shop = product['shop'];
    
    final price = _getVariantPrice();
    final comparePrice = toDoubleSafe(product['compare_price']);
    final hasDiscount = comparePrice > 0 && comparePrice > price;
    final rating = toDoubleSafe(product['rating']);
    final reviewsCount = toIntSafe(product['reviews_count']);
    final salesCount = toIntSafe(product['sales_count']);
    final images = _getImages();
    
    final hasColors = _groupedVariants.containsKey('colors') && _groupedVariants['colors']!.isNotEmpty;
    final hasSizes = _groupedVariants.containsKey('sizes') && _groupedVariants['sizes']!.isNotEmpty;
    final hasMaterials = _groupedVariants.containsKey('materials') && _groupedVariants['materials']!.isNotEmpty;
    
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            backgroundColor: AppColors.background,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
              onPressed: () {
                if (Navigator.of(context).canPop()) {
                  context.pop();
                } else {
                  context.go(AppRoutes.home);
                }
              },
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: GestureDetector(
                onTap: () {
                  if (images.isNotEmpty) {
                    _showImageZoom(images, 0);
                  }
                },
                child: ProductImageCarousel(
                  images: images,
                  getFullImageUrl: _getFullImageUrl,
                  onImageTap: (index) {
                    _showImageZoom(images, index);
                  },
                ),
              ),
            ),
          ),
          
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (hasDiscount)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.promotion,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'PROMO',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  
                  const SizedBox(height: 12),
                  
                  Text(
                    toStringSafe(product['name']),
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  
                  const SizedBox(height: 8),
                  
                  GestureDetector(
                    onTap: _navigateToShop,
                    child: Row(
                      children: [
                        Text(
                          toStringSafe(shop['name']),
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        if (shop['is_verified'] == true)
                          const Padding(
                            padding: EdgeInsets.only(left: 4),
                            child: Icon(
                              Icons.verified,
                              size: 14,
                              color: AppColors.primary,
                            ),
                          ),
                        const SizedBox(width: 4),
                        const Icon(Icons.arrow_forward_ios, size: 12, color: AppColors.textTertiary),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 8),
                  
                  Row(
                    children: [
                      RatingStars(rating: rating),
                      const SizedBox(width: 8),
                      Text(
                        '$rating ($reviewsCount avis)',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        )
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '| $salesCount ventes',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  PriceWidget(
                    price: price,
                    comparePrice: hasDiscount ? comparePrice : null,
                  ),
                  
                  const SizedBox(height: 24),
                  
                  if (hasColors)
                    _buildVariantSelector(
                      title: 'Couleurs',
                      variants: _groupedVariants['colors']!,
                      selectedValue: _selectedColor,
                      onSelected: _onColorSelected,
                      type: 'color',
                    ),
                  
                  if (hasSizes)
                    _buildVariantSelector(
                      title: 'Tailles',
                      variants: _groupedVariants['sizes']!,
                      selectedValue: _selectedSize,
                      onSelected: _onSizeSelected,
                      type: 'size',
                    ),
                  
                  if (hasMaterials)
                    _buildVariantSelector(
                      title: 'Matières',
                      variants: _groupedVariants['materials']!,
                      selectedValue: _selectedMaterial,
                      onSelected: _onMaterialSelected,
                      type: 'text',
                    ),
                  
                  const SizedBox(height: 16),
                  
                  QuantitySelector(
                    quantity: _selectedQuantity,
                    onQuantityChanged: (qty) {
                      setState(() => _selectedQuantity = qty);
                    },
                  ),
                  
                  if (_selectedVariant != null && _selectedVariant!['sku'] != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        'SKU: ${_selectedVariant!['sku']}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textTertiary,
                        ),
                      ),
                    ),
                  
                  const SizedBox(height: 24),
                  
                  SizedBox(
                    height: 45,
                    child: TabBar(
                      controller: _tabController,
                      indicatorColor: AppColors.primary,
                      labelColor: AppColors.primary,
                      unselectedLabelColor: AppColors.textSecondary,
                      tabs: const [
                        Tab(text: 'Description'),
                        Tab(text: 'Détails'),
                        Tab(text: 'Avis'),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  SizedBox(
                    height: 400,
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        SingleChildScrollView(
                          child: Text(
                            toStringSafe(product['description']),
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppColors.textSecondary,
                              height: 1.5,
                            ),
                          ),
                        ),
                        SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildDetailItem('Livraison gratuite à partir de 50 000 FCFA'),
                              _buildDetailItem('Retour sous 14 jours'),
                              _buildDetailItem('Garantie 1 an'),
                              _buildDetailItem('Paiement sécurisé'),
                              _buildDetailItem('Service client 7j/7'),
                            ],
                          ),
                        ),
                        _buildReviewsTab(),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.backgroundLight,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                gradient: AppColors.primaryGradient,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.store,
                                color: Colors.white,
                                size: 28,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        toStringSafe(shop['name']),
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                      if (shop['is_verified'] == true)
                                        const Padding(
                                          padding: EdgeInsets.only(left: 4),
                                          child: Icon(
                                            Icons.verified,
                                            size: 14,
                                            color: AppColors.primary,
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      RatingStars(rating: toDoubleSafe(shop['rating']), size: 12),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${toDoubleSafe(shop['rating']).toStringAsFixed(1)} (${toIntSafe(shop['reviews_count'])} avis)',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        '| ${_formatNumber(toIntSafe(shop['followers_count']))} abonnés',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            _buildShopStat('${toIntSafe(shop['products_count'])}', 'Produits'),
                            _buildShopStat(_formatNumber(toIntSafe(shop['followers_count'])), 'Abonnés'),
                            _buildShopStat('98%', 'Avis positifs'),
                            _buildShopStat(toStringSafe(shop['delivery_time']), 'Livraison'),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  if (_similarProducts.isNotEmpty) ...[
                    const Text(
                      'Produits similaires',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 250,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: _similarProducts.map((product) => SimilarProductCard(
                          product: product,
                          onTap: () {
                            context.push('${AppRoutes.productDetail}/${product['id']}');
                          },
                        )).toList(),
                      ),
                    ),
                  ],
                  
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
      
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.background,
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _navigateToShop,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: BorderSide(color: AppColors.border),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.store_outlined, size: 20),
                    SizedBox(width: 8),
                    Text('Boutique'),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: _isInCart ? null : _addToCart,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppColors.primary,
                  side: BorderSide(color: AppColors.primary),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isInCart
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.primary,
                        ),
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.shopping_bag_outlined, size: 20),
                          SizedBox(width: 8),
                          Text('Ajouter'),
                        ],
                      ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: _buyNow,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Acheter',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVariantSelector({
    required String title,
    required List<dynamic> variants,
    required String? selectedValue,
    required Function(String) onSelected,
    required String type,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 12,
          runSpacing: 8,
          children: variants.map((variant) {
            final value = variant['value'];
            final isSelected = selectedValue == value;
            
            if (type == 'color') {
              final colorCode = variant['code'] ?? _getColorCode(value);
              return GestureDetector(
                onTap: () => onSelected(value),
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Color(int.parse('0xFF${colorCode.replaceFirst('#', '')}')),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? AppColors.primary : AppColors.border,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: isSelected
                      ? const Icon(Icons.check, size: 20, color: Colors.white)
                      : null,
                ),
              );
            } else {
              return GestureDetector(
                onTap: () => onSelected(value),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary : AppColors.backgroundLight,
                    border: Border.all(
                      color: isSelected ? AppColors.primary : AppColors.border,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    variant['name'],
                    style: TextStyle(
                      color: isSelected ? Colors.white : AppColors.textPrimary,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                ),
              );
            }
          }).toList(),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildReviewsTab() {
    final isLoggedIn = _token != null;
    
    if (_isLoadingReviews) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }
    
    return Column(
      children: [
        if (isLoggedIn) _buildAddReviewForm(),
        
        Expanded(
          child: _reviews.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.rate_review, size: 64, color: AppColors.textTertiary),
                      const SizedBox(height: 16),
                      Text(
                        isLoggedIn 
                            ? 'Soyez le premier à donner votre avis'
                            : 'Aucun avis pour ce produit',
                        style: const TextStyle(color: AppColors.textSecondary),
                      ),
                      if (!isLoggedIn) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Connectez-vous pour laisser un avis',
                          style: TextStyle(fontSize: 12, color: AppColors.textTertiary),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => context.push(AppRoutes.login),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                          ),
                          child: const Text('Se connecter'),
                        ),
                      ],
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _reviews.length,
                  itemBuilder: (context, index) {
                    final review = _reviews[index];
                    final user = review['user'];
                    final userName = toStringSafe(user?['name'] ?? review['user_name']);
                    final userAvatar = user?['avatar'];
                    final rating = toDoubleSafe(review['rating']);
                    final comment = toStringSafe(review['comment']);
                    final createdAt = toStringSafe(review['created_at']);
                    
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
                                  radius: 20,
                                  backgroundColor: AppColors.primary,
                                  backgroundImage: userAvatar != null
                                      ? NetworkImage(_getFullImageUrl(userAvatar))
                                      : null,
                                  child: userAvatar == null
                                      ? Text(
                                          userName.isNotEmpty ? userName[0].toUpperCase() : '?',
                                          style: const TextStyle(color: Colors.white),
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
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      RatingStars(rating: rating, size: 12),
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
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildAddReviewForm() {
    final formKey = GlobalKey<FormState>();
    int rating = 5;
    final commentController = TextEditingController();
    bool isSubmitting = false;

    void submitReview() async {
      if (!formKey.currentState!.validate()) return;
      
      setState(() => isSubmitting = true);
      
      final token = await StorageService().getToken();
      if (token == null) {
        _showSnackBar('Veuillez vous connecter');
        setState(() => isSubmitting = false);
        return;
      }
      
      try {
        final result = await _apiService.addProductReview(
          widget.productId, 
          rating, 
          commentController.text.trim(),
          token,
        );
        
        if (result['success']) {
          _showSnackBar('Avis ajouté avec succès !', isSuccess: true);
          commentController.clear();
          await _loadReviews();
        } else {
          _showSnackBar(result['message'] ?? 'Erreur lors de l\'ajout');
        }
      } catch (e) {
        _showSnackBar('Erreur de connexion');
      } finally {
        setState(() => isSubmitting = false);
      }
    }

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Donnez votre avis',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            
            Row(
              children: [
                const Text(
                  'Votre note : ',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
                ...List.generate(5, (index) {
                  final starValue = index + 1;
                  return IconButton(
                    icon: Icon(
                      starValue <= rating ? Icons.star : Icons.star_border,
                      color: AppColors.starYellow,
                      size: 28,
                    ),
                    onPressed: () {
                      setState(() => rating = starValue);
                    },
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  );
                }),
              ],
            ),
            
            const SizedBox(height: 12),
            
            TextFormField(
              controller: commentController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Partagez votre expérience avec ce produit...',
                border: OutlineInputBorder(),
                filled: true,
                fillColor: AppColors.background,
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Veuillez écrire un commentaire';
                }
                if (value.length < 10) {
                  return 'Minimum 10 caractères';
                }
                return null;
              },
            ),
            
            const SizedBox(height: 12),
            
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isSubmitting ? null : submitReview,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
                child: isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Publier mon avis'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      final now = DateTime.now();
      final diff = now.difference(date);
      
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
    } catch (e) {
      return '';
    }
  }

  Widget _buildDetailItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(Icons.check_circle, size: 16, color: AppColors.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShopStat(String value, String label) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  String _formatNumber(int number) {
    if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toString();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}