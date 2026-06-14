import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:nora/config/app_constants.dart';
import '../../config/app_colors.dart';
import '../../config/routes.dart';
import '../../services/storage_service.dart';
import '../../services/category_api_service.dart';
import '../../services/user_api_service.dart';
import '../../utils/converters.dart';

class InterestsPage extends StatefulWidget {
  const InterestsPage({super.key});

  @override
  State<InterestsPage> createState() => _InterestsPageState();
}

class _InterestsPageState extends State<InterestsPage> with SingleTickerProviderStateMixin {
  final Map<int, int> _selectedInterests = {};
  List<dynamic> _categories = [];
  bool _isLoading = true;
  bool _isSaving = false;
  bool _hasShownTip = false;
  String? _errorMessage;

  String _getFullImageUrl(String? path) {
    if (path == null || path.isEmpty) return '';
    if (path.startsWith('http')) return path;
    return '${AppConstants.apiBaseUrl.replaceAll('/api', '')}$path';
  }

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final categoryApiService = CategoryApiService();
      final result = await categoryApiService.getCategories();
      
      if (result['success'] && result['categories'] != null && result['categories'].isNotEmpty) {
        setState(() {
          _categories = result['categories'];
          _isLoading = false;
        });
        // Show tip modal on first load
        if (!_hasShownTip && mounted) {
          _hasShownTip = true;
          Future.delayed(const Duration(milliseconds: 600), () {
            if (mounted) _showTipModal(context); // ✅ CORRECTION: context passé ici
          });
        }
      } else {
        setState(() {
          _categories = [];
          _isLoading = false;
          _errorMessage = 'Aucune catégorie disponible';
        });
      }
    } catch (e) {
      print('❌ Erreur: $e');
      setState(() {
        _categories = [];
        _isLoading = false;
        _errorMessage = 'Erreur de connexion au serveur';
      });
    }
  }

  void _toggleInterest(int categoryId, String categoryName) {
    setState(() {
      if (_selectedInterests.containsKey(categoryId)) {
        _selectedInterests.remove(categoryId);
      } else {
        _selectedInterests[categoryId] = 3;
      }
    });
  }

  /// Modal d'explication de la fonctionnalité
  void _showTipModal(BuildContext context) { // ✅ CORRECTION: paramètre context ajouté
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              color: AppColors.background,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icône animée
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.3),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.tune_rounded, size: 36, color: Colors.white),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Personnalisez votre expérience',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Vos choix nous aident à vous proposer les produits et boutiques qui vous correspondent le mieux.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 24),
                // Astuce 1 : Appui simple
                _buildTipRow(
                  icon: Icons.touch_app_rounded,
                  title: 'Appui simple',
                  subtitle: 'Sélectionnez ou désélectionnez une catégorie',
                  color: AppColors.primary,
                ),
                const SizedBox(height: 14),
                // Astuce 2 : Appui long
                _buildTipRow(
                  icon: Icons.back_hand_rounded,
                  title: 'Maintenir appuyé',
                  subtitle: 'Choisissez la priorité d\'une catégorie (faible, moyenne, haute)',
                  color: AppColors.accent,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'C\'est compris !',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTipRow({required IconData icon, required String title, required String subtitle, required Color color}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, size: 22, color: color),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
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
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showPriorityDialog(int categoryId, String categoryName) {
    // Auto-select if not yet selected
    if (!_selectedInterests.containsKey(categoryId)) {
      setState(() {
        _selectedInterests[categoryId] = 3;
      });
    }
    int currentPriority = _selectedInterests[categoryId] ?? 3;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      backgroundColor: AppColors.background,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateBottomSheet) {
            return Container(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Poignée de glissement
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.tune_rounded, color: Colors.white, size: 24),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Priorité pour « $categoryName »',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Plus la priorité est haute, plus vous verrez de contenu lié à cette catégorie.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildPriorityButton(1, 'Faible', currentPriority, (value) {
                        setStateBottomSheet(() => currentPriority = value);
                      }, AppColors.secondary),
                      _buildPriorityButton(3, 'Moyenne', currentPriority, (value) {
                        setStateBottomSheet(() => currentPriority = value);
                      }, AppColors.primary),
                      _buildPriorityButton(5, 'Haute', currentPriority, (value) {
                        setStateBottomSheet(() => currentPriority = value);
                      }, AppColors.accent),
                    ],
                  ),
                  const SizedBox(height: 28),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _selectedInterests[categoryId] = currentPriority;
                        });
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Confirmer',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildPriorityButton(int value, String label, int currentPriority, Function(int) onChanged, Color color) {
    final isSelected = currentPriority == value;
    return GestureDetector(
      onTap: () => onChanged(value),
      child: Column(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: isSelected ? color : AppColors.backgroundLight,
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? color : AppColors.border,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Center(
              child: Text(
                value.toString(),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.white : AppColors.textPrimary,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: isSelected ? color : AppColors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }

  String _getPriorityLabel(int priority) {
    switch (priority) {
      case 1: return 'Faible';
      case 2: return 'Moyen-';
      case 3: return 'Moyenne';
      case 4: return 'Moyen+';
      case 5: return 'Haute';
      default: return 'Moyenne';
    }
  }

  Color _getPriorityColor(int priority) {
    if (priority <= 2) return AppColors.secondary;
    if (priority <= 4) return AppColors.primary;
    return AppColors.primaryDark;
  }

  Future<void> _saveInterests() async {
    if (_selectedInterests.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sélectionnez au moins un centre d\'intérêt'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final interestsList = _selectedInterests.entries.map((entry) => ({
        'category_id': entry.key,
        'priority_level': entry.value,
      })).toList();
      
      await StorageService().saveLocalInterests(interestsList);
      await StorageService().setInterestsSelected(true);
      
      final token = await StorageService().getToken();
      
      if (token != null && token.isNotEmpty) {
        try {
          final userApiService = UserApiService();
          await userApiService.selectInterests(interestsList, token);
          print('✅ Intérêts synchronisés avec l\'API');
        } catch (e) {
          print('⚠️ Synchronisation différée: $e');
        }
      }
      
      if (mounted) {
        context.go(AppRoutes.home);
      }
    } catch (e) {
      print('❌ Erreur sauvegarde: $e');
      await StorageService().setInterestsSelected(true);
      if (mounted) {
        context.go(AppRoutes.home);
      }
    } finally {
      setState(() => _isSaving = false);
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
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(Icons.favorite, size: 14, color: Colors.white),
            ),
            const SizedBox(width: 8),
            const Text(
              'Centres d\'intérêt',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Quels sont vos centres d\'intérêt ?',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Sélectionnez vos catégories préférées pour personnaliser votre expérience',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  if (_errorMessage != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: AppColors.error.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.error_outline, size: 20, color: AppColors.error),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: TextStyle(color: AppColors.error),
                            ),
                          ),
                          TextButton(
                            onPressed: _loadCategories,
                            style: TextButton.styleFrom(
                              foregroundColor: AppColors.primary,
                            ),
                            child: const Text('Réessayer'),
                          ),
                        ],
                      ),
                    ),
                  
                  if (_isLoading)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(40),
                        child: CircularProgressIndicator(
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  
                  if (!_isLoading && _categories.isEmpty && _errorMessage == null)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(40),
                        child: Text('Aucune catégorie disponible'),
                      ),
                    ),
                  
                  if (!_isLoading && _categories.isNotEmpty)
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 1.3,
                      ),
                      itemCount: _categories.length,
                      itemBuilder: (context, index) {
                        final category = _categories[index];
                        final categoryId = category['id'] as int;
                        final categoryName = toStringSafe(category['name']);
                        final imageUrl = _getFullImageUrl(category['image']);
                        final isSelected = _selectedInterests.containsKey(categoryId);
                        final priority = _selectedInterests[categoryId];

                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.primary.withOpacity(0.05)
                                : AppColors.background,
                            border: Border.all(
                              color: isSelected ? AppColors.primary : AppColors.border,
                              width: isSelected ? 2 : 1,
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: AppColors.primary.withOpacity(0.2),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ]
                                : null,
                          ),
                          child: InkWell(
                            onTap: () => _toggleInterest(categoryId, categoryName),
                            onLongPress: () {
                              _showPriorityDialog(categoryId, categoryName);
                            },
                            borderRadius: BorderRadius.circular(16),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // Image de la catégorie
                                if (imageUrl.isNotEmpty)
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: CachedNetworkImage(
                                      imageUrl: imageUrl,
                                      width: 60,
                                      height: 60,
                                      fit: BoxFit.cover,
                                      placeholder: (context, url) => Container(
                                        width: 60,
                                        height: 60,
                                        decoration: BoxDecoration(
                                          color: AppColors.backgroundLight,
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Icon(
                                          _getIconForCategory(categoryName),
                                          size: 30,
                                          color: isSelected ? AppColors.primary : AppColors.textTertiary,
                                        ),
                                      ),
                                      errorWidget: (context, url, error) => Container(
                                        width: 60,
                                        height: 60,
                                        decoration: BoxDecoration(
                                          color: AppColors.backgroundLight,
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Icon(
                                          _getIconForCategory(categoryName),
                                          size: 30,
                                          color: isSelected ? AppColors.primary : AppColors.textTertiary,
                                        ),
                                      ),
                                    ),
                                  )
                                else
                                  Container(
                                    width: 60,
                                    height: 60,
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? AppColors.primary.withOpacity(0.1)
                                          : AppColors.backgroundLight,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(
                                      _getIconForCategory(categoryName),
                                      size: 30,
                                      color: isSelected ? AppColors.primary : AppColors.textTertiary,
                                    ),
                                  ),
                                
                                const SizedBox(height: 12),
                                
                                Text(
                                  categoryName,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                                    color: isSelected ? AppColors.primary : AppColors.textSecondary,
                                  ),
                                ),
                                
                                if (isSelected && priority != null)
                                  Container(
                                    margin: const EdgeInsets.only(top: 8),
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      gradient: _getPriorityColor(priority) == AppColors.secondary
                                          ? AppColors.secondaryGradient
                                          : AppColors.primaryGradient,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      _getPriorityLabel(priority),
                                      style: const TextStyle(
                                        fontSize: 10,
                                        color: Colors.white,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  
                  const SizedBox(height: 16),
                  
                  if (_categories.isNotEmpty)
                    GestureDetector(
                      onTap: () => _showTipModal(context), // ✅ CORRECTION: context passé ici aussi
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppColors.primary.withOpacity(0.08),
                              AppColors.accent.withOpacity(0.06),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.primary.withOpacity(0.2)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.back_hand_rounded, size: 18, color: AppColors.primary),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Maintenez appuyé pour définir la priorité',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Appuyez ici pour en savoir plus',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.primary.withOpacity(0.6)),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          
          if (_categories.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.background,
                border: Border(top: BorderSide(color: AppColors.border)),
              ),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveInterests,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Continuer',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  IconData _getIconForCategory(String categoryName) {
    switch (categoryName.toLowerCase()) {
      case 'mode': return Icons.checkroom;
      case 'électronique': return Icons.phone_android;
      case 'electronique': return Icons.phone_android;
      case 'maison': return Icons.home;
      case 'beauté': return Icons.spa;
      case 'beaute': return Icons.spa;
      case 'sports': return Icons.sports_soccer;
      case 'jeux & jouets': return Icons.videogame_asset;
      case 'sacs & accessoires': return Icons.shopping_bag;
      case 'bijoux & montres': return Icons.watch;
      case 'automobile': return Icons.car_repair;
      case 'bébé & puériculture': return Icons.child_care;
      case 'livres & papeterie': return Icons.book;
      default: return Icons.category;
    }
  }
}