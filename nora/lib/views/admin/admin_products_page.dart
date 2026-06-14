import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../config/app_colors.dart';
import '../../config/app_constants.dart';
import '../../services/product_api_service.dart';
import '../../services/category_api_service.dart';
import '../../services/storage_service.dart';
import '../../services/language_service.dart';

class AdminProductsPage extends StatefulWidget {
  const AdminProductsPage({super.key});

  @override
  State<AdminProductsPage> createState() => _AdminProductsPageState();
}

class _AdminProductsPageState extends State<AdminProductsPage> {
  final ProductApiService _productApiService = ProductApiService();
  final CategoryApiService _categoryApiService = CategoryApiService();
  final LanguageService _languageService = LanguageService();
  
  List<dynamic> _products = [];
  List<dynamic> _categories = [];
  bool _isLoading = true;
  String? _token;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    _token = await StorageService().getToken();
    
    await Future.wait([
      _loadProducts(),
      _loadCategories(),
    ]);
    
    setState(() => _isLoading = false);
  }

  Future<void> _loadProducts() async {
    if (_token == null) return;
    
    try {
      final result = await _productApiService.getMyProducts(_token!);
      if (result['success']) {
        setState(() {
          _products = result['products'] ?? [];
        });
      }
    } catch (e) {
      debugPrint('Erreur chargement produits: $e');
    }
  }

  Future<void> _loadCategories() async {
    try {
      final result = await _categoryApiService.getCategories();
      if (result['success']) {
        setState(() {
          _categories = result['categories'] ?? [];
        });
      }
    } catch (e) {
      debugPrint('Erreur chargement catégories: $e');
    }
  }

  String _getImageUrl(String? imagePath) {
    if (imagePath == null || imagePath.isEmpty) return '';
    if (imagePath.startsWith('http')) return imagePath;
    if (imagePath.startsWith('/storage')) {
      return '${AppConstants.apiBaseUrl.replaceAll('/api', '')}$imagePath';
    }
    return '${AppConstants.apiBaseUrl.replaceAll('/api', '')}/storage/$imagePath';
  }

  void _showProductDialog({Map<String, dynamic>? product}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _ProductDialog(
        product: product,
        categories: _categories,
        languageService: _languageService,
        onSave: (data, images, variants) async {
          if (_token == null) return;
          
          Map<String, dynamic> result;
          if (product == null) {
            result = await _productApiService.createProduct(
              name: data['name'],
              price: data['price'],
              description: data['description'],
              categoryId: data['category_id'],
              images: images,
              variants: variants,
              stock: data['stock'] ?? 0,
              comparePrice: data['compare_price'],
              token: _token!,
            );
          } else {
            result = await _productApiService.updateProduct(
              productId: product['id'],
              name: data['name'],
              price: data['price'],
              description: data['description'],
              categoryId: data['category_id'],
              stock: data['stock'],
              comparePrice: data['compare_price'],
              isActive: data['is_active'],
              variants: variants,
              token: _token!,
            );
          }

          if (!mounted) return;
          if (result['success']) {
            _loadProducts();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(result['message'] ?? _languageService.translate('success')),
                backgroundColor: AppColors.success,
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(result['message'] ?? _languageService.translate('error')),
                backgroundColor: AppColors.error,
              ),
            );
          }
        },
      ),
    );
  }

  Future<void> _deleteProduct(int id, String name) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_languageService.translate('delete_product')),
        content: Text('${_languageService.translate('confirm_delete')} "$name"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(_languageService.translate('cancel')),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(context, true),
            child: Text(_languageService.translate('delete')),
          ),
        ],
      ),
    );

    if (confirm != true || _token == null) return;

    setState(() => _isLoading = true);
    final result = await _productApiService.deleteProduct(id, _token!);

    if (mounted) {
      if (result['success']) {
        _loadProducts();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_languageService.translate('product_deleted')),
            backgroundColor: AppColors.success,
          ),
        );
      } else {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? _languageService.translate('error')),
            backgroundColor: AppColors.error,
          ),
        );
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
        title: Text(
          _languageService.translate('products'),
          style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle, color: AppColors.primary, size: 28),
            onPressed: () => _showProductDialog(),
            tooltip: _languageService.translate('add_product'),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _products.isEmpty
              ? _buildEmpty()
              : RefreshIndicator(
                  onRefresh: _loadData,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _products.length,
                    itemBuilder: (context, index) {
                      final product = _products[index];
                      return _ProductCard(
                        product: product,
                        getImageUrl: _getImageUrl,
                        onEdit: () => _showProductDialog(product: product),
                        onDelete: () => _deleteProduct(product['id'], product['name'] ?? ''),
                      );
                    },
                  ),
                ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.inventory_2_outlined, size: 64, color: AppColors.textTertiary),
          const SizedBox(height: 16),
          Text(
            _languageService.translate('no_products'),
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 16),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _showProductDialog(),
            icon: const Icon(Icons.add),
            label: Text(_languageService.translate('add_first_product')),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
          ),
        ],
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final Map<String, dynamic> product;
  final String Function(String?) getImageUrl;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ProductCard({
    required this.product,
    required this.getImageUrl,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final images = product['images'] as List? ?? [];
    final firstImage = images.isNotEmpty ? getImageUrl(images[0]) : '';
    final isActive = product['is_active'] != false;
    final inPromotion = product['in_promotion'] == true;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image du produit
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: firstImage.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: firstImage,
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => _buildImagePlaceholder(),
                    )
                  : _buildImagePlaceholder(),
            ),
            const SizedBox(width: 12),
            // Informations du produit
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          product['name'] ?? '',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (!isActive)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.textTertiary.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text('Inactif', style: TextStyle(fontSize: 10, color: AppColors.textTertiary)),
                        ),
                      if (inPromotion)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.promotion.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text('Promo', style: TextStyle(fontSize: 10, color: AppColors.promotion)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${product['price'] ?? 0} FCFA',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                  if (product['category_name'] != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        product['category_name'],
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, size: 20, color: AppColors.primary),
                        onPressed: onEdit,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.delete, size: 20, color: AppColors.error),
                        onPressed: onDelete,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
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

  Widget _buildImagePlaceholder() {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(Icons.image_outlined, size: 32, color: AppColors.textTertiary),
    );
  }
}

class _ProductDialog extends StatefulWidget {
  final Map<String, dynamic>? product;
  final List<dynamic> categories;
  final LanguageService languageService;
  final Future<void> Function(Map<String, dynamic>, List<File>, List<Map<String, dynamic>>?) onSave;

  const _ProductDialog({
    this.product,
    required this.categories,
    required this.languageService,
    required this.onSave,
  });

  @override
  State<_ProductDialog> createState() => _ProductDialogState();
}

class _ProductDialogState extends State<_ProductDialog> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _comparePriceController = TextEditingController();
  final _stockController = TextEditingController(text: '0');
  
  int? _selectedCategoryId;
  int? _selectedSubcategoryId;
  List<File> _selectedImages = [];
  List<Map<String, dynamic>> _variants = [];
  bool _isActive = true;
  bool _isSaving = false;
  
  // Controllers pour les champs des variantes
  List<TextEditingController> _variantSizeControllers = [];
  List<TextEditingController> _variantColorControllers = [];
  List<TextEditingController> _variantStockControllers = [];
  
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    if (widget.product != null) {
      _nameController.text = widget.product!['name'] ?? '';
      _descriptionController.text = widget.product!['description'] ?? '';
      _priceController.text = (widget.product!['price'] ?? 0).toString();
      _comparePriceController.text = (widget.product!['compare_price'] ?? '').toString();
      _selectedCategoryId = widget.product!['category_id'];
      _isActive = widget.product!['is_active'] != false;
      
      // Charger les variantes existantes avec des controllers
      if (widget.product!['variants'] != null) {
        _variants = (widget.product!['variants'] as List)
            .map((v) => Map<String, dynamic>.from(v as Map<String, dynamic>))
            .toList();
      }
    }
    _initVariantControllers();
  }

  void _initVariantControllers() {
    // Créer des controllers pour chaque variante existante
    _variantSizeControllers = _variants.map((v) => TextEditingController(text: v['size']?.toString() ?? '')).toList();
    _variantColorControllers = _variants.map((v) => TextEditingController(text: v['color']?.toString() ?? '')).toList();
    _variantStockControllers = _variants.map((v) => TextEditingController(text: (v['stock'] ?? 0).toString())).toList();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _comparePriceController.dispose();
    _stockController.dispose();
    for (final c in _variantSizeControllers) c.dispose();
    for (final c in _variantColorControllers) c.dispose();
    for (final c in _variantStockControllers) c.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final List<XFile>? picked = await _picker.pickMultiImage(
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );
    if (picked != null) {
      setState(() {
        _selectedImages.addAll(picked.map((x) => File(x.path)));
      });
    }
  }

  void _addVariant() {
    setState(() {
      _variants.add({
        'size': '',
        'color': '',
        'material': '',
        'stock': 0,
        'sku': 'VAR-${DateTime.now().millisecondsSinceEpoch}-${_variants.length}',
        'price_adjustment': 0,
      });
      _variantSizeControllers.add(TextEditingController());
      _variantColorControllers.add(TextEditingController());
      _variantStockControllers.add(TextEditingController(text: '0'));
    });
  }

  void _removeVariant(int index) {
    setState(() {
      _variants.removeAt(index);
      _variantSizeControllers[index].dispose();
      _variantColorControllers[index].dispose();
      _variantStockControllers[index].dispose();
      _variantSizeControllers.removeAt(index);
      _variantColorControllers.removeAt(index);
      _variantStockControllers.removeAt(index);
    });
  }

  Future<void> _save() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(widget.languageService.translate('name_required')), backgroundColor: AppColors.error),
      );
      return;
    }

    if (_priceController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(widget.languageService.translate('price_required')), backgroundColor: AppColors.error),
      );
      return;
    }

    if (_selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(widget.languageService.translate('category_required')), backgroundColor: AppColors.error),
      );
      return;
    }

    // Vérifier si une sous-catégorie est requise
    final subcategories = _getSubcategories(_selectedCategoryId!);
    if (subcategories.isNotEmpty && _selectedSubcategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.languageService.translate('subcategory_required')),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    // Synchroniser les controllers des variantes avant de sauvegarder
    for (var i = 0; i < _variants.length; i++) {
      _variants[i]['size'] = _variantSizeControllers[i].text;
      _variants[i]['color'] = _variantColorControllers[i].text;
      _variants[i]['stock'] = int.tryParse(_variantStockControllers[i].text) ?? 0;
    }

    setState(() => _isSaving = true);
    Navigator.pop(context);

    // Utiliser la sous-catégorie si sélectionnée, sinon la catégorie principale
    final effectiveCategoryId = _selectedSubcategoryId ?? _selectedCategoryId!;

    final data = <String, dynamic>{
      'name': _nameController.text.trim(),
      'description': _descriptionController.text.trim(),
      'price': double.tryParse(_priceController.text) ?? 0,
      'category_id': effectiveCategoryId,
      'is_active': _isActive,
    };

    if (_comparePriceController.text.trim().isNotEmpty) {
      data['compare_price'] = double.tryParse(_comparePriceController.text);
    }

    if (_stockController.text.trim().isNotEmpty) {
      data['stock'] = int.tryParse(_stockController.text) ?? 0;
    }

    await widget.onSave(data, _selectedImages, _variants.isEmpty ? null : _variants);
  }

  List<dynamic> _getSubcategories(int categoryId) {
    final idx = widget.categories.indexWhere((cat) => cat['id'] == categoryId);
    if (idx != -1) {
      final category = widget.categories[idx];
      if (category['children'] != null) {
        return category['children'] as List;
      }
    }
    return [];
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.product != null;

    return AlertDialog(
      title: Text(
        isEdit
            ? widget.languageService.translate('edit_product')
            : widget.languageService.translate('add_product'),
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
      ),
      contentPadding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Images
            GestureDetector(
              onTap: _pickImages,
              child: Container(
                width: double.infinity,
                height: 120,
                decoration: BoxDecoration(
                  color: AppColors.backgroundLight,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: _selectedImages.isNotEmpty ? AppColors.primary : AppColors.border,
                    width: _selectedImages.isNotEmpty ? 2 : 1,
                  ),
                ),
                child: _selectedImages.isNotEmpty
                    ? Stack(
                        fit: StackFit.expand,
                        children: [
                          ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: _selectedImages.length,
                            itemBuilder: (context, index) {
                              return Padding(
                                padding: const EdgeInsets.all(4),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.file(_selectedImages[index], fit: BoxFit.cover),
                                ),
                              );
                            },
                          ),
                          Positioned(
                            bottom: 4,
                            right: 4,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.black54,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.edit, size: 14, color: Colors.white),
                            ),
                          ),
                        ],
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_photo_alternate_outlined, size: 36, color: AppColors.textTertiary),
                          const SizedBox(height: 6),
                          Text(widget.languageService.translate('add_images'), style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 14),

            // Nom
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: '${widget.languageService.translate('name')} *',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.label_outline),
                isDense: true,
              ),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 12),

            // Description
            TextField(
              controller: _descriptionController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: '${widget.languageService.translate('description')} *',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.notes),
                isDense: true,
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 12),

            // Prix
            TextField(
              controller: _priceController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: '${widget.languageService.translate('price')} *',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.attach_money),
                isDense: true,
              ),
            ),
            const SizedBox(height: 12),

            // Prix de comparaison (optionnel)
            TextField(
              controller: _comparePriceController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: widget.languageService.translate('compare_price'),
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.local_offer),
                isDense: true,
              ),
            ),
            const SizedBox(height: 12),

            // Catégorie
            DropdownButtonFormField<int>(
              value: _selectedCategoryId,
              decoration: InputDecoration(
                labelText: '${widget.languageService.translate('category')} *',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.category),
                isDense: true,
              ),
              items: widget.categories.map((cat) {
                return DropdownMenuItem<int>(
                  value: cat['id'],
                  child: Text(cat['name'] ?? ''),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedCategoryId = value;
                  _selectedSubcategoryId = null;
                });
              },
            ),
            const SizedBox(height: 12),

            // Sous-catégorie (si disponible)
            if (_selectedCategoryId != null && _getSubcategories(_selectedCategoryId!).isNotEmpty)
              DropdownButtonFormField<int>(
                value: _selectedSubcategoryId,
                decoration: InputDecoration(
                  labelText: '${widget.languageService.translate('subcategory')} *',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.subdirectory_arrow_right),
                  isDense: true,
                ),
                items: _getSubcategories(_selectedCategoryId!).map((sub) {
                  return DropdownMenuItem<int>(
                    value: sub['id'],
                    child: Text(sub['name'] ?? ''),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() => _selectedSubcategoryId = value);
                },
              ),
            const SizedBox(height: 12),

            // Stock
            TextField(
              controller: _stockController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: widget.languageService.translate('stock'),
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.inventory),
                isDense: true,
              ),
            ),
            const SizedBox(height: 12),

            // Variantes
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.languageService.translate('variants'),
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                TextButton.icon(
                  onPressed: _addVariant,
                  icon: const Icon(Icons.add, size: 16),
                  label: Text(widget.languageService.translate('add_variant')),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ..._variants.asMap().entries.map((entry) {
              final index = entry.key;
              final variant = entry.value;
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Variante ${index + 1}', style: const TextStyle(fontWeight: FontWeight.w500)),
                      IconButton(
                        icon: const Icon(Icons.delete, size: 18, color: AppColors.error),
                        onPressed: () => _removeVariant(index),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _variantSizeControllers[index],
                              decoration: const InputDecoration(
                                labelText: 'Taille',
                                isDense: true,
                                contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: _variantColorControllers[index],
                              decoration: const InputDecoration(
                                labelText: 'Couleur',
                                isDense: true,
                                contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _variantStockControllers[index],
                        decoration: const InputDecoration(
                          labelText: 'Stock',
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
            const SizedBox(height: 12),

            // Actif
            SwitchListTile(
              title: Text(widget.languageService.translate('active'), style: const TextStyle(fontSize: 14)),
              subtitle: Text(widget.languageService.translate('visible_in_app'), style: const TextStyle(fontSize: 12)),
              value: _isActive,
              onChanged: (v) => setState(() => _isActive = v),
              activeColor: AppColors.primary,
              contentPadding: EdgeInsets.zero,
              dense: true,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(widget.languageService.translate('cancel')),
        ),
        ElevatedButton(
          onPressed: _isSaving ? null : _save,
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
          child: _isSaving
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : Text(isEdit ? widget.languageService.translate('update') : widget.languageService.translate('create')),
        ),
      ],
    );
  }
}
