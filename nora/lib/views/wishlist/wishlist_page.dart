import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../config/app_colors.dart';
import '../../../services/wishlist_service.dart';
import '../../../services/language_service.dart';

class WishlistPage extends StatefulWidget {
  const WishlistPage({super.key});

  @override
  State<WishlistPage> createState() => _WishlistPageState();
}

class _WishlistPageState extends State<WishlistPage> {
  final WishlistService _wishlistService = WishlistService();
  final LanguageService _languageService = LanguageService();

  List<dynamic> _wishlist = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadWishlist();
  }

  Future<void> _loadWishlist() async {
    setState(() => _isLoading = true);

    final result = await _wishlistService.getWishlist();
    
    if (result['success']) {
      setState(() {
        _wishlist = result['wishlist'] ?? [];
        _isLoading = false;
        _errorMessage = null;
      });
    } else {
      setState(() {
        _isLoading = false;
        _errorMessage = result['message'];
      });
    }
  }

  Future<void> _removeFromWishlist(int productId) async {
    final result = await _wishlistService.removeFromWishlist(productId);
    
    if (result['success']) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message']),
          backgroundColor: AppColors.success,
        ),
      );
      await _loadWishlist();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message']),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _safePop() {
    if (Navigator.of(context).canPop()) {
      context.pop();
    } else {
      context.go('/home');
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
          onPressed: _safePop,
        ),
        title: Text(
          _languageService.translate('wishlist'),
          style: const TextStyle(color: AppColors.textPrimary),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _errorMessage!,
                        style: const TextStyle(color: AppColors.error),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadWishlist,
                        child: Text(_languageService.translate('try_again')),
                      ),
                    ],
                  ),
                )
              : _wishlist.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.favorite_border, size: 80, color: AppColors.textTertiary),
                          const SizedBox(height: 16),
                          Text(
                            _languageService.translate('empty_wishlist'),
                            style: const TextStyle(fontSize: 18, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    )
                  : GridView.builder(
                      padding: const EdgeInsets.all(16),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 0.75,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                      ),
                      itemCount: _wishlist.length,
                      itemBuilder: (context, index) {
                        final item = _wishlist[index];
                        final product = item['product'] ?? item;
                        
                        return Stack(
                          children: [
                            GestureDetector(
                              onTap: () {
                                // Naviguer vers le détail du produit
                              },
                              child: Card(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: CachedNetworkImage(
                                        imageUrl: product['image_url'] ?? '',
                                        fit: BoxFit.cover,
                                        width: double.infinity,
                                        placeholder: (context, url) => const Center(
                                          child: CircularProgressIndicator(),
                                        ),
                                        errorWidget: (context, url, error) => const Icon(Icons.error),
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.all(8),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            product['name'] ?? 'Produit',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12,
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            '${product['price'] ?? 0} FCFA',
                                            style: TextStyle(
                                              color: AppColors.primary,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            Positioned(
                              top: 8,
                              right: 8,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: IconButton(
                                  icon: const Icon(Icons.favorite, color: Colors.red),
                                  onPressed: () => _removeFromWishlist(product['id']),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
    );
  }
}
