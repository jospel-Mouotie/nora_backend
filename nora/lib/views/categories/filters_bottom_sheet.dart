import 'package:flutter/material.dart';
import '../../config/app_colors.dart';
import '../../services/api_service.dart';
import '../../utils/converters.dart';

class FiltersBottomSheet extends StatefulWidget {
  final int categoryId;
  final String categoryName;
  final Function(int? subcategoryId, String sortBy) onApplyFilters;

  const FiltersBottomSheet({
    super.key,
    required this.categoryId,
    required this.categoryName,
    required this.onApplyFilters,
  });

  @override
  State<FiltersBottomSheet> createState() => _FiltersBottomSheetState();
}

class _FiltersBottomSheetState extends State<FiltersBottomSheet> {
  final ApiService _apiService = ApiService();
  List<dynamic> _subcategories = [];
  bool _isLoading = true;

  int? _selectedSubcategoryId;
  String _selectedSort = 'recent';

  final List<Map<String, dynamic>> _sortOptions = [
    {'value': 'recent', 'label': 'Plus récents', 'icon': Icons.access_time},
    {'value': 'price_asc', 'label': 'Prix croissant', 'icon': Icons.trending_up},
    {'value': 'price_desc', 'label': 'Prix décroissant', 'icon': Icons.trending_down},
    {'value': 'rating', 'label': 'Mieux notés', 'icon': Icons.star},
    {'value': 'popular', 'label': 'Les plus vendus', 'icon': Icons.local_fire_department},
  ];

  @override
  void initState() {
    super.initState();
    _loadSubcategories();
  }

  Future<void> _loadSubcategories() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final result = await _apiService.getCategories();
      if (!mounted) return;

      if (result['success'] && result['categories'] != null) {
        final categories = result['categories'] as List;
        final category = categories.firstWhere(
          (cat) => cat['id'] == widget.categoryId,
          orElse: () => null,
        );

        if (!mounted) return;

        if (category != null && category['children'] != null) {
          final children = category['children'] as List;
          // Trier les sous-catégories par nom
          children.sort((a, b) => (a['name'] ?? '').toString().compareTo((b['name'] ?? '').toString()));

          setState(() {
            _subcategories = children;
            _isLoading = false;
          });
        } else {
          setState(() {
            _subcategories = [];
            _isLoading = false;
          });
        }
      } else {
        if (!mounted) return;
        setState(() {
          _subcategories = [];
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Erreur chargement sous-catégories: $e');
      if (!mounted) return;
      setState(() {
        _subcategories = [];
        _isLoading = false;
      });
    }
  }

  void _resetFilters() {
    setState(() {
      _selectedSubcategoryId = null;
      _selectedSort = 'recent';
    });
  }

  void _applyFilters() {
    widget.onApplyFilters(_selectedSubcategoryId, _selectedSort);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Barre de poignée (drag handle)
          Container(
            margin: const EdgeInsets.only(top: 12),
            height: 4,
            width: 40,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 16, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    widget.categoryName,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Row(
                  children: [
                    TextButton(
                      onPressed: _resetFilters,
                      child: const Text(
                        'Réinitialiser',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.close, color: AppColors.textTertiary),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Divider
          const Divider(height: 1, color: AppColors.border),

          SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Section Sous-catégories
                if (_isLoading)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: CircularProgressIndicator(color: AppColors.primary),
                    ),
                  )
                else if (_subcategories.isNotEmpty) ...[
                  const Text(
                    'Sous-catégories',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Utiliser Wrap pour un meilleur alignement
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      // Option "Tous"
                      _buildSubcategoryChip('Tous', null),
                      // Options des sous-catégories
                      ..._subcategories.map((sub) => _buildSubcategoryChip(
                        toStringSafe(sub['name']),
                        sub['id'],
                      )),
                    ],
                  ),
                  const SizedBox(height: 24),
                ],

                // Section Tri
                const Text(
                  'Trier par',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                // Grille pour les options de tri
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: _sortOptions.map((sort) {
                    final isSelected = _selectedSort == sort['value'];
                    return _buildSortChip(sort, isSelected);
                  }).toList(),
                ),

                const SizedBox(height: 32),

                // Bouton Appliquer
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          side: const BorderSide(color: AppColors.border),
                        ),
                        child: const Text(
                          'Annuler',
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: _applyFilters,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Appliquer les filtres',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubcategoryChip(String label, int? id) {
    final isSelected = _selectedSubcategoryId == id;
    return FilterChip(
      label: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.white : AppColors.textPrimary,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
        ),
      ),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedSubcategoryId = selected ? id : null;
        });
      },
      backgroundColor: AppColors.backgroundLight,
      selectedColor: AppColors.primary,
      checkmarkColor: Colors.white,
      side: BorderSide(
        color: isSelected ? AppColors.primary : AppColors.border,
        width: 1,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      shape: StadiumBorder(
        side: BorderSide(
          color: isSelected ? AppColors.primary : AppColors.border,
        ),
      ),
    );
  }

  Widget _buildSortChip(Map<String, dynamic> sort, bool isSelected) {
    return FilterChip(
      avatar: Icon(
        sort['icon'],
        size: 18,
        color: isSelected ? Colors.white : AppColors.textSecondary,
      ),
      label: Text(
        sort['label'],
        style: TextStyle(
          color: isSelected ? Colors.white : AppColors.textSecondary,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
        ),
      ),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedSort = selected ? sort['value'] : 'recent';
        });
      },
      backgroundColor: AppColors.backgroundLight,
      selectedColor: AppColors.primary,
      checkmarkColor: Colors.white,
      side: BorderSide(
        color: isSelected ? AppColors.primary : AppColors.border,
        width: 1,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      shape: StadiumBorder(
        side: BorderSide(
          color: isSelected ? AppColors.primary : AppColors.border,
        ),
      ),
    );
  }
}
