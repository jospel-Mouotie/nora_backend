import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import '../../../config/app_colors.dart';
import '../../../config/app_constants.dart';
import '../../../services/category_api_service.dart';
import '../../../services/storage_service.dart';

class AdminCategoriesPage extends StatefulWidget {
  const AdminCategoriesPage({super.key});

  @override
  State<AdminCategoriesPage> createState() => _AdminCategoriesPageState();
}

class _AdminCategoriesPageState extends State<AdminCategoriesPage> {
  final CategoryApiService _categoryApiService = CategoryApiService();
  List<dynamic> _categories = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    setState(() => _isLoading = true);
    try {
      final result = await _categoryApiService.getCategories();
      if (result['success']) {
        setState(() {
          _categories = result['categories'] ?? [];
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  String _getImageUrl(String? path) {
    if (path == null || path.isEmpty) return '';
    if (path.startsWith('http')) return path;
    return '${AppConstants.apiBaseUrl.replaceAll('/api', '')}/storage/$path';
  }

  void _showCategoryDialog({Map<String, dynamic>? category, int? parentId}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _CategoryDialog(
        category: category,
        parentId: parentId,
        onSave: (name, description, isActive, sortOrder, imageFile) async {
          final token = await StorageService().getToken();
          if (token == null) return;

          final data = <String, dynamic>{
            'name': name,
            if (description.isNotEmpty) 'description': description,
            'is_active': isActive ? '1' : '0',
            'sort_order': sortOrder.toString(),
            if (parentId != null) 'parent_id': parentId.toString(),
          };

          Map<String, dynamic> result;
          if (category == null) {
            result = await _categoryApiService.createCategory(
              data, token, imageFile: imageFile,
            );
          } else {
            result = await _categoryApiService.updateCategory(
              category['id'], data, token, imageFile: imageFile,
            );
          }

          if (!mounted) return;
          if (result['success']) {
            _loadCategories();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(result['message'] ?? 'Succès'),
                backgroundColor: AppColors.success,
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(result['message'] ?? 'Erreur'),
                backgroundColor: AppColors.error,
              ),
            );
          }
        },
      ),
    );
  }

  Future<void> _deleteCategory(int id, String name) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer la catégorie'),
        content: Text('Voulez-vous vraiment supprimer "$name" ?\nCette action est irréversible.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final token = await StorageService().getToken();
    if (token == null) return;

    setState(() => _isLoading = true);
    final result = await _categoryApiService.deleteCategory(id, token);

    if (mounted) {
      if (result['success']) {
        _loadCategories();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Catégorie supprimée'), backgroundColor: AppColors.success),
        );
      } else {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'] ?? 'Erreur'), backgroundColor: AppColors.error),
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
        title: const Text('Catégories', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle, color: AppColors.primary, size: 28),
            onPressed: () => _showCategoryDialog(),
            tooltip: 'Ajouter une catégorie',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _categories.isEmpty
              ? _buildEmpty()
              : RefreshIndicator(
                  onRefresh: _loadCategories,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _categories.length,
                    itemBuilder: (context, index) {
                      final cat = _categories[index];
                      final children = (cat['children'] as List?) ?? [];
                      return _CategoryCard(
                        category: cat,
                        children: children,
                        getImageUrl: _getImageUrl,
                        onEdit: () => _showCategoryDialog(category: cat),
                        onDelete: () => _deleteCategory(cat['id'], cat['name'] ?? ''),
                        onAddChild: () => _showCategoryDialog(parentId: cat['id']),
                        onEditChild: (child) => _showCategoryDialog(category: child, parentId: cat['id']),
                        onDeleteChild: (child) => _deleteCategory(child['id'], child['name'] ?? ''),
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
          const Icon(Icons.category_outlined, size: 64, color: AppColors.textTertiary),
          const SizedBox(height: 16),
          const Text('Aucune catégorie', style: TextStyle(color: AppColors.textSecondary, fontSize: 16)),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _showCategoryDialog(),
            icon: const Icon(Icons.add),
            label: const Text('Créer une catégorie'),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
          ),
        ],
      ),
    );
  }
}

// ───────────────────────────────────────────────
// Carte catégorie avec expansion pour les enfants
// ───────────────────────────────────────────────
class _CategoryCard extends StatelessWidget {
  final Map<String, dynamic> category;
  final List<dynamic> children;
  final String Function(String?) getImageUrl;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onAddChild;
  final void Function(Map<String, dynamic>) onEditChild;
  final void Function(Map<String, dynamic>) onDeleteChild;

  const _CategoryCard({
    required this.category,
    required this.children,
    required this.getImageUrl,
    required this.onEdit,
    required this.onDelete,
    required this.onAddChild,
    required this.onEditChild,
    required this.onDeleteChild,
  });

  @override
  Widget build(BuildContext context) {
    final imageUrl = getImageUrl(category['image']);
    final isActive = category['is_active'] != false;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          leading: _CategoryAvatar(imageUrl: imageUrl, name: category['name'] ?? ''),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  category['name'] ?? '',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
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
            ],
          ),
          subtitle: Text(
            '${children.length} sous-catégorie${children.length > 1 ? 's' : ''}',
            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.edit, size: 20, color: AppColors.primary),
                onPressed: onEdit,
                tooltip: 'Modifier',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: 4),
              IconButton(
                icon: const Icon(Icons.delete, size: 20, color: AppColors.error),
                onPressed: onDelete,
                tooltip: 'Supprimer',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: 4),
            ],
          ),
          children: [
            // Sous-catégories
            if (children.isNotEmpty)
              ...children.map((child) => _ChildTile(
                    child: child,
                    getImageUrl: getImageUrl,
                    onEdit: () => onEditChild(child),
                    onDelete: () => onDeleteChild(child),
                  )),
            // Bouton ajouter sous-catégorie
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: OutlinedButton.icon(
                onPressed: onAddChild,
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Ajouter une sous-catégorie', style: TextStyle(fontSize: 13)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChildTile extends StatelessWidget {
  final Map<String, dynamic> child;
  final String Function(String?) getImageUrl;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ChildTile({
    required this.child,
    required this.getImageUrl,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final imageUrl = getImageUrl(child['image']);
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.subdirectory_arrow_right, size: 16, color: AppColors.textSecondary),
          const SizedBox(width: 8),
          _CategoryAvatar(imageUrl: imageUrl, name: child['name'] ?? '', size: 32),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(child['name'] ?? '', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                if ((child['description'] ?? '').toString().isNotEmpty)
                  Text(
                    child['description'],
                    style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit, size: 18, color: AppColors.primary),
            onPressed: onEdit,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          const SizedBox(width: 4),
          IconButton(
            icon: const Icon(Icons.delete, size: 18, color: AppColors.error),
            onPressed: onDelete,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }
}

class _CategoryAvatar extends StatelessWidget {
  final String imageUrl;
  final String name;
  final double size;

  const _CategoryAvatar({required this.imageUrl, required this.name, this.size = 42});

  @override
  Widget build(BuildContext context) {
    if (imageUrl.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(size / 4),
        child: CachedNetworkImage(
          imageUrl: imageUrl,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorWidget: (_, __, ___) => _fallback(),
          placeholder: (_, __) => Container(
            width: size,
            height: size,
            color: AppColors.backgroundLight,
          ),
        ),
      );
    }
    return _fallback();
  }

  Widget _fallback() {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(size / 4),
      ),
      child: Center(
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : '?',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: size * 0.4),
        ),
      ),
    );
  }
}

// ───────────────────────────────────────────────
// Dialog de création / édition de catégorie
// ───────────────────────────────────────────────
class _CategoryDialog extends StatefulWidget {
  final Map<String, dynamic>? category;
  final int? parentId;
  final Future<void> Function(String name, String description, bool isActive, int sortOrder, File? imageFile) onSave;

  const _CategoryDialog({
    this.category,
    this.parentId,
    required this.onSave,
  });

  @override
  State<_CategoryDialog> createState() => _CategoryDialogState();
}

class _CategoryDialogState extends State<_CategoryDialog> {
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final _sortController = TextEditingController(text: '0');
  bool _isActive = true;
  File? _imageFile;
  bool _isSaving = false;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    if (widget.category != null) {
      _nameController.text = widget.category!['name'] ?? '';
      _descController.text = widget.category!['description'] ?? '';
      _sortController.text = (widget.category!['sort_order'] ?? 0).toString();
      _isActive = widget.category!['is_active'] != false;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _sortController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final XFile? picked = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 85,
    );
    if (picked != null) {
      setState(() => _imageFile = File(picked.path));
    }
  }

  Future<void> _save() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Le nom est requis'), backgroundColor: AppColors.error),
      );
      return;
    }

    final isEdit = widget.category != null;
    final existingUrl = _getExistingImageUrl();
    if (_imageFile == null && (!isEdit || existingUrl.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('L\'image est requise'), backgroundColor: AppColors.error),
      );
      return;
    }

    setState(() => _isSaving = true);
    Navigator.pop(context); // fermer le dialog avant l'appel async

    await widget.onSave(
      _nameController.text.trim(),
      _descController.text.trim(),
      _isActive,
      int.tryParse(_sortController.text) ?? 0,
      _imageFile,
    );
  }

  String _getExistingImageUrl() {
    final path = widget.category?['image'];
    if (path == null || path.toString().isEmpty) return '';
    if (path.toString().startsWith('http')) return path.toString();
    return '${AppConstants.apiBaseUrl.replaceAll('/api', '')}/storage/$path';
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.category != null;
    final existingUrl = _getExistingImageUrl();

    return AlertDialog(
      title: Text(
        isEdit
            ? 'Modifier la catégorie'
            : (widget.parentId != null ? 'Nouvelle sous-catégorie' : 'Nouvelle catégorie'),
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
      ),
      contentPadding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Image de la catégorie
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                width: double.infinity,
                height: 120,
                decoration: BoxDecoration(
                  color: AppColors.backgroundLight,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: _imageFile != null ? AppColors.primary : AppColors.border,
                    width: _imageFile != null ? 2 : 1,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: _imageFile != null
                      ? Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.file(_imageFile!, fit: BoxFit.cover),
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
                      : existingUrl.isNotEmpty
                          ? Stack(
                              fit: StackFit.expand,
                              children: [
                                CachedNetworkImage(
                                  imageUrl: existingUrl,
                                  fit: BoxFit.cover,
                                  errorWidget: (_, __, ___) => _buildImagePlaceholder(),
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
                          : _buildImagePlaceholder(),
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Nom
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Nom *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.label_outline),
                isDense: true,
              ),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 12),

            // Description
            TextField(
              controller: _descController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Description (optionnelle)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.notes),
                isDense: true,
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 12),

            // Ordre d'affichage
            TextField(
              controller: _sortController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Ordre d\'affichage',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.sort),
                isDense: true,
                helperText: '0 = premier',
              ),
            ),
            const SizedBox(height: 4),

            // Actif
            SwitchListTile(
              title: const Text('Catégorie active', style: TextStyle(fontSize: 14)),
              subtitle: const Text('Visible dans l\'application', style: TextStyle(fontSize: 12)),
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
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: _isSaving ? null : _save,
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
          child: _isSaving
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : Text(isEdit ? 'Mettre à jour' : 'Créer'),
        ),
      ],
    );
  }

  Widget _buildImagePlaceholder() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.add_photo_alternate_outlined, size: 36, color: AppColors.textTertiary),
        const SizedBox(height: 6),
        const Text('Ajouter une image', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        const Text('(requise)', style: TextStyle(fontSize: 10, color: AppColors.error)),
      ],
    );
  }
}
