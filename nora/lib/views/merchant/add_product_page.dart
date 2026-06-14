import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../config/app_colors.dart';
import '../../../services/category_api_service.dart';
import '../../../services/product_api_service.dart';
import '../../../services/storage_service.dart';

class AddProductPage extends StatefulWidget {
  final Map<String, dynamic>? product;

  const AddProductPage({super.key, this.product});

  @override
  State<AddProductPage> createState() => _AddProductPageState();
}

class _AddProductPageState extends State<AddProductPage> {
  final CategoryApiService _categoryApiService = CategoryApiService();
  final ProductApiService _productApiService = ProductApiService();
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _comparePriceController = TextEditingController();
  final _stockController = TextEditingController();
  final _descriptionController = TextEditingController();

  int? _selectedCategoryId;
  int? _selectedSubcategoryId;
  List<File> _selectedImages = [];
  bool _isLoading = false;
  bool _isActive = true;

  List<dynamic> _categories = [];
  List<dynamic> _subcategories = [];
  final List<Map<String, dynamic>> _variants = [];
  bool _hasVariants = false;

  @override
  void initState() {
    super.initState();
    _loadCategories();
    if (widget.product != null) {
      _loadProductData();
    }
  }

  void _loadProductData() {
    _nameController.text = widget.product!['name'] ?? '';
    _priceController.text = widget.product!['price']?.toString() ?? '';
    _comparePriceController.text =
        widget.product!['compare_price']?.toString() ?? '';
    _stockController.text = widget.product!['stock']?.toString() ?? '';
    _descriptionController.text = widget.product!['description'] ?? '';
    _selectedCategoryId = widget.product!['category_id'];
    _selectedSubcategoryId = widget.product!['subcategory_id'];
    _isActive = widget.product!['is_active'] == true;

    // Load subcategories if category is selected
    if (_selectedCategoryId != null) {
      _loadSubcategories(_selectedCategoryId!);
    }
  }

  Future<void> _loadCategories() async {
    try {
      final result = await _categoryApiService.getCategories();
      if (result['success'] && result['categories'] != null) {
        setState(() {
          _categories = result['categories'];
        });
      }
    } catch (e) {
      print('Erreur chargement catégories: $e');
    }
  }

  Future<void> _loadSubcategories(int categoryId) async {
    try {
      final result = await _categoryApiService.getCategoryChildren(categoryId);
      if (result['success'] && result['subcategories'] != null) {
        // Convertir les IDs en int si nécessaire
        final subcategories = (result['subcategories'] as List).map((sub) {
          final subMap = sub as Map<String, dynamic>;
          if (subMap['id'] is String) {
            subMap['id'] = int.parse(subMap['id'] as String);
          }
          return subMap;
        }).toList();
        setState(() {
          _subcategories = subcategories;
        });
      } else {
        setState(() {
          _subcategories = [];
        });
      }
    } catch (e) {
      print('Erreur chargement sous-catégories: $e');
      setState(() {
        _subcategories = [];
      });
    }
  }

  Future<void> _pickImages() async {
    final ImagePicker picker = ImagePicker();
    final List<XFile> images = await picker.pickMultiImage();

    setState(() {
      _selectedImages = images.map((img) => File(img.path)).toList();
    });
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;

    // Vérifier si une sous-catégorie est requise mais non sélectionnée
    if (_subcategories.isNotEmpty && _selectedSubcategoryId == null) {
      _showError('Veuillez sélectionner une sous-catégorie');
      return;
    }

    setState(() => _isLoading = true);

    final token = await StorageService().getToken();
    if (token == null) {
      _showError('Veuillez vous reconnecter');
      setState(() => _isLoading = false);
      return;
    }

    try {
      // Utiliser la sous-catégorie si sélectionnée, sinon la catégorie principale
      final int effectiveCategoryId =
          _selectedSubcategoryId ?? _selectedCategoryId!;

      Map<String, dynamic> result;
      if (widget.product != null) {
        // Mise à jour
        result = await _productApiService.updateProduct(
          productId: widget.product!['id'],
          name: _nameController.text.trim(),
          price: double.parse(_priceController.text),
          description: _descriptionController.text.trim(),
          categoryId: effectiveCategoryId,
          stock: _stockController.text.isEmpty ? 0 : int.parse(_stockController.text),
          comparePrice: _comparePriceController.text.isEmpty
              ? null
              : double.parse(_comparePriceController.text),
          isActive: _isActive,
          variants: _hasVariants ? _variants : null,
          token: token,
        );
      } else {
        // Création
        result = await _productApiService.createProduct(
          name: _nameController.text.trim(),
          price: double.parse(_priceController.text),
          description: _descriptionController.text.trim(),
          categoryId: effectiveCategoryId,
          stock: _stockController.text.isEmpty ? 0 : int.parse(_stockController.text),
          comparePrice: _comparePriceController.text.isEmpty
              ? null
              : double.parse(_comparePriceController.text),
          images: _selectedImages,
          variants: _hasVariants ? _variants : null,
          token: token,
        );
      }

      if (result['success']) {
        _showSuccess(
          widget.product != null ? 'Produit modifié' : 'Produit créé',
        );
        Navigator.pop(context, true);
      } else {
        _showError(result['message'] ?? 'Erreur lors de l\'enregistrement');
      }
    } catch (e) {
      debugPrint('Erreur création produit: $e');
      _showError('Erreur de connexion: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.error),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.success),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text(
          widget.product != null ? 'Modifier le produit' : 'Ajouter un produit',
          style: const TextStyle(color: AppColors.textPrimary),
        ),
        actions: [
          TextButton(
            onPressed: _saveProduct,
            child: Text(
              'Enregistrer',
              style: TextStyle(
                color: _isLoading ? AppColors.textTertiary : AppColors.primary,
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Images
                    GestureDetector(
                      onTap: _pickImages,
                      child: Container(
                        height: 120,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: AppColors.backgroundLight,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: _selectedImages.isEmpty
                            ? const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.add_photo_alternate, size: 40),
                                  SizedBox(height: 8),
                                  Text('Ajouter des images'),
                                ],
                              )
                            : ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: _selectedImages.length,
                                itemBuilder: (context, index) {
                                  return Padding(
                                    padding: const EdgeInsets.all(8),
                                    child: Image.file(
                                      _selectedImages[index],
                                      width: 100,
                                      height: 100,
                                      fit: BoxFit.cover,
                                    ),
                                  );
                                },
                              ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Nom
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Nom du produit',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Nom requis';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Prix
                    TextFormField(
                      controller: _priceController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Prix',
                        prefixText: 'FCFA ',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Prix requis';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Prix promo
                    TextFormField(
                      controller: _comparePriceController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Prix promotion (optionnel)',
                        prefixText: 'FCFA ',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Stock
                    TextFormField(
                      controller: _stockController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Stock',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Catégorie
                    DropdownButtonFormField<int>(
                      value: _selectedCategoryId,
                      decoration: const InputDecoration(
                        labelText: 'Catégorie',
                        border: OutlineInputBorder(),
                      ),
                      items: _categories.map<DropdownMenuItem<int>>((cat) {
                        return DropdownMenuItem<int>(
                          value: cat['id'] as int,
                          child: Text(cat['name'] as String),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedCategoryId = value;
                          _selectedSubcategoryId = null;
                          _subcategories = [];
                        });
                        if (value != null) {
                          _loadSubcategories(value);
                        }
                      },
                      validator: (value) {
                        if (value == null) return 'Catégorie requise';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Sous-catégorie
                    if (_subcategories.isNotEmpty)
                      DropdownButtonFormField<int>(
                        value: _selectedSubcategoryId,
                        decoration: const InputDecoration(
                          labelText: 'Sous-catégorie *',
                          border: OutlineInputBorder(),
                        ),
                        items: _subcategories.map<DropdownMenuItem<int>>((sub) {
                          return DropdownMenuItem<int>(
                            value: sub['id'] as int,
                            child: Text(sub['name'] as String),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() => _selectedSubcategoryId = value);
                        },
                        validator: (value) {
                          if (_subcategories.isNotEmpty && value == null) {
                            return 'Sous-catégorie requise';
                          }
                          return null;
                        },
                      ),
                    if (_subcategories.isNotEmpty) const SizedBox(height: 16),

                    // Description
                    TextFormField(
                      controller: _descriptionController,
                      maxLines: 5,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        border: OutlineInputBorder(),
                        alignLabelWithHint: true,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Actif
                    SwitchListTile(
                      title: const Text('Produit actif'),
                      subtitle: const Text('Visible dans la boutique'),
                      value: _isActive,
                      onChanged: (value) => setState(() => _isActive = value),
                      activeColor: AppColors.primary,
                    ),

                    const SizedBox(height: 24),
                    const Divider(),
                    const SizedBox(height: 24),

                    // Variantes
                    SwitchListTile(
                      title: const Text('Ce produit a des variantes'),
                      subtitle: const Text('Taille, couleur, matière, etc.'),
                      value: _hasVariants,
                      onChanged: (value) => setState(() => _hasVariants = value),
                      activeColor: AppColors.primary,
                    ),

                    if (_hasVariants) ...[
                      const SizedBox(height: 16),
                      ..._buildVariantsSection(),
                    ],
                  ],
                ),
              ),
            ),
    );
  }

  List<Widget> _buildVariantsSection() {
    return [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Variantes',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          ElevatedButton.icon(
            onPressed: _addVariant,
            icon: const Icon(Icons.add),
            label: const Text('Ajouter'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
      const SizedBox(height: 16),
      ..._variants.asMap().entries.map((entry) {
        final index = entry.key;
        final variant = entry.value;
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Variante ${index + 1}'),
                    IconButton(
                      icon: const Icon(Icons.delete, color: AppColors.error),
                      onPressed: () => _removeVariant(index),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                TextFormField(
                  initialValue: variant['size'] ?? '',
                  decoration: const InputDecoration(
                    labelText: 'Taille',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  onChanged: (value) => _updateVariant(index, 'size', value),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  initialValue: variant['color'] ?? '',
                  decoration: const InputDecoration(
                    labelText: 'Couleur',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  onChanged: (value) => _updateVariant(index, 'color', value),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  initialValue: variant['material'] ?? '',
                  decoration: const InputDecoration(
                    labelText: 'Matière',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  onChanged: (value) => _updateVariant(index, 'material', value),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  initialValue: variant['stock']?.toString() ?? '',
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Stock',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  onChanged: (value) => _updateVariant(index, 'stock', value),
                ),
              ],
            ),
          ),
        );
      }),
    ];
  }

  void _addVariant() {
    setState(() {
      _variants.add({
        'size': '',
        'color': '',
        'material': '',
        'stock': 0,
      });
    });
  }

  void _removeVariant(int index) {
    setState(() {
      _variants.removeAt(index);
    });
  }

  void _updateVariant(int index, String field, String value) {
    setState(() {
      if (field == 'stock') {
        _variants[index][field] = int.tryParse(value) ?? 0;
      } else {
        _variants[index][field] = value;
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _comparePriceController.dispose();
    _stockController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
}
