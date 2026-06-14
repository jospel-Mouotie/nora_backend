import 'package:flutter/material.dart';
import '../../../config/app_colors.dart';
import '../../../services/product_api_service.dart';
import '../../../services/storage_service.dart';
import '../../../widgets/merchant/merchant_product_list.dart';
import 'add_product_page.dart';

class MerchantProductsPage extends StatefulWidget {
  const MerchantProductsPage({super.key});

  @override
  State<MerchantProductsPage> createState() => _MerchantProductsPageState();
}

class _MerchantProductsPageState extends State<MerchantProductsPage> {
  final ProductApiService _productApiService = ProductApiService();
  List<dynamic> _products = [];
  bool _isLoading = true;
  String? _token;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    setState(() => _isLoading = true);
    
    _token = await StorageService().getToken();
    if (_token != null) {
      try {
        final result = await _productApiService.getMyProducts(_token!);
        if (result['success'] && result['products'] != null) {
          setState(() {
            _products = result['products'];
            _isLoading = false;
          });
          return;
        }
      } catch (e) {
        print('Erreur chargement produits: $e');
      }
    }
    
    setState(() => _isLoading = false);
  }

  void _addProduct() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddProductPage()),
    ).then((_) => _loadProducts());
  }

  void _editProduct(Map<String, dynamic> product) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddProductPage(product: product),
      ),
    ).then((_) => _loadProducts());
  }

  Future<void> _deleteProduct(int productId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer le produit'),
        content: const Text('Voulez-vous vraiment supprimer ce produit ?'),
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
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    
    if (confirm != true) return;
    
    if (_token != null) {
      try {
        final result = await _productApiService.deleteProduct(productId, _token!);
        if (result['success']) {
          _loadProducts();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Produit supprimé'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      } catch (e) {
        print('Erreur suppression: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text(
          'Mes produits',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: AppColors.primary),
            onPressed: _addProduct,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : _products.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.inventory, size: 64, color: AppColors.textTertiary),
                      const SizedBox(height: 16),
                      const Text(
                        'Aucun produit',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _addProduct,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                        ),
                        child: const Text('Ajouter un produit'),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _products.length,
                  itemBuilder: (context, index) {
                    final product = _products[index];
                    return MerchantProductCard(
                      product: product,
                      onEdit: () => _editProduct(product),
                      onDelete: () => _deleteProduct(product['id']),
                    );
                  },
                ),
    );
  }
}