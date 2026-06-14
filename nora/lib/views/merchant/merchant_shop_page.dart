import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:share_plus/share_plus.dart';
import 'package:image_picker/image_picker.dart';
import '../../../config/app_colors.dart';
import '../../../config/app_constants.dart';
import '../../../config/routes.dart';
import '../../../services/category_api_service.dart';
import '../../../services/shop_api_service.dart';
import '../../../services/storage_service.dart';
import '../../../utils/converters.dart';
import '../../../widgets/custom_app_bar.dart';

class MerchantShopPage extends StatefulWidget {
  const MerchantShopPage({super.key});

  @override
  State<MerchantShopPage> createState() => _MerchantShopPageState();
}

class _MerchantShopPageState extends State<MerchantShopPage> {
  final ShopApiService _apiService = ShopApiService();
  final CategoryApiService _categoryApiService = CategoryApiService();

  List<dynamic> _shops = [];
  Map<String, dynamic>? _selectedShop;
  bool _isLoading = true;
  bool _isEditing = false;
  bool _isCreating = false;
  String? _token;

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _cityController = TextEditingController();
  final _postalCodeController = TextEditingController();

  // Catégories
  List<int> _selectedCategoryIds = [];
  List<dynamic> _categories = [];

  // Images
  File? _selectedLogo;
  File? _selectedBanner;
  final ImagePicker _imagePicker = ImagePicker();

  // ✅ Nouveaux champs - Livraison
  final List<String> _availableCities = [
    'Douala', 'Yaoundé', 'Garoua', 'Bamenda', 'Bafoussam',
    'Maroua', 'Ngaoundéré', 'Bertoua', 'Loum', 'Kumba', 'Buea', 'Ebolowa'
  ];
  List<String> _selectedDeliveryCities = [];
  final TextEditingController _deliveryPriceController = TextEditingController();
  final TextEditingController _freeDeliveryMinController = TextEditingController();
  String _selectedDeliveryType = 'standard';

  // ✅ Coordonnées GPS
  final TextEditingController _latitudeController = TextEditingController();
  final TextEditingController _longitudeController = TextEditingController();

  // ✅ Horaires d'ouverture
  Map<String, Map<String, String>> _openingHours = {
    'lundi': {'open': '08:00', 'close': '18:00', 'closed': 'false'},
    'mardi': {'open': '08:00', 'close': '18:00', 'closed': 'false'},
    'mercredi': {'open': '08:00', 'close': '18:00', 'closed': 'false'},
    'jeudi': {'open': '08:00', 'close': '18:00', 'closed': 'false'},
    'vendredi': {'open': '08:00', 'close': '18:00', 'closed': 'false'},
    'samedi': {'open': '09:00', 'close': '14:00', 'closed': 'false'},
    'dimanche': {'open': '00:00', 'close': '00:00', 'closed': 'true'},
  };
  bool _showOpeningHours = false;

  // ✅ Réseaux sociaux
  final TextEditingController _facebookController = TextEditingController();
  final TextEditingController _instagramController = TextEditingController();
  final TextEditingController _whatsappController = TextEditingController();

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
    _loadShops();
    _loadCategories();
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
      debugPrint('Erreur chargement catégories: $e');
    }
  }

  Future<void> _loadShops() async {
    setState(() => _isLoading = true);

    _token = await StorageService().getToken();
    if (_token == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final result = await _apiService.getMyShops(_token!);
      if (result['success'] && result['shops'] != null) {
        setState(() {
          _shops = result['shops'];
          _isLoading = false;
        });
      } else {
        setState(() {
          _shops = [];
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Erreur chargement boutiques: $e');
      setState(() {
        _shops = [];
        _isLoading = false;
      });
    }
  }

  Future<File?> _pickImage(ImageSource source) async {
    final pickedFile = await _imagePicker.pickImage(source: source);
    if (pickedFile != null) {
      return File(pickedFile.path);
    }
    return null;
  }

  Future<void> _pickLogo() async {
    final logo = await _pickImage(ImageSource.gallery);
    if (logo != null) {
      setState(() => _selectedLogo = logo);
    }
  }

  Future<void> _pickBanner() async {
    final banner = await _pickImage(ImageSource.gallery);
    if (banner != null) {
      setState(() => _selectedBanner = banner);
    }
  }

  void _openCreateForm() {
    _clearForm();
    setState(() {
      _selectedShop = null;
      _isCreating = true;
      _isEditing = false;
    });
  }

  void _openEditForm() {
    if (_selectedShop == null) return;

    _nameController.text = toStringSafe(_selectedShop?['name']);
    _descriptionController.text = toStringSafe(_selectedShop?['description']);
    _addressController.text = toStringSafe(_selectedShop?['address']);
    _phoneController.text = toStringSafe(_selectedShop?['phone']);
    _emailController.text = toStringSafe(_selectedShop?['email']);
    _cityController.text = toStringSafe(_selectedShop?['city']);
    _postalCodeController.text = toStringSafe(_selectedShop?['postal_code']);

    // Catégories
    if (_selectedShop?['categories'] != null) {
      _selectedCategoryIds = (_selectedShop!['categories'] as List)
          .map((cat) => cat['id'] as int)
          .toList();
    }

    // Villes de livraison
    if (_selectedShop?['delivery_cities'] != null) {
      final cities = _selectedShop!['delivery_cities'];
      if (cities is List) {
        _selectedDeliveryCities = List<String>.from(cities);
      } else if (cities is String) {
        try {
          final decoded = jsonDecode(cities);
          if (decoded is List) {
            _selectedDeliveryCities = List<String>.from(decoded);
          }
        } catch (e) {}
      }
    }

    _deliveryPriceController.text = (_selectedShop?['delivery_price'] ?? 0).toString();
    _freeDeliveryMinController.text = _selectedShop?['free_delivery_min_amount']?.toString() ?? '';
    _selectedDeliveryType = _selectedShop?['delivery_type'] ?? 'standard';

    // Coordonnées
    _latitudeController.text = _selectedShop?['latitude']?.toString() ?? '';
    _longitudeController.text = _selectedShop?['longitude']?.toString() ?? '';

    // Horaires
    if (_selectedShop?['opening_hours'] != null) {
      final hours = _selectedShop!['opening_hours'];
      if (hours is Map) {
        for (var day in _openingHours.keys) {
          if (hours[day] != null) {
            _openingHours[day] = {
              'open': hours[day]['open'] ?? '08:00',
              'close': hours[day]['close'] ?? '18:00',
              'closed': (hours[day]['closed'] == true || hours[day]['closed'] == 'true').toString(),
            };
          }
        }
      }
    }

    // Réseaux sociaux
    _facebookController.text = _selectedShop?['facebook_url'] ?? '';
    _instagramController.text = _selectedShop?['instagram_url'] ?? '';
    _whatsappController.text = _selectedShop?['whatsapp_number'] ?? '';

    _selectedLogo = null;
    _selectedBanner = null;

    setState(() {
      _isEditing = true;
      _isCreating = false;
    });
  }

  void _clearForm() {
    _nameController.clear();
    _descriptionController.clear();
    _addressController.clear();
    _phoneController.clear();
    _emailController.clear();
    _cityController.clear();
    _postalCodeController.clear();
    _selectedCategoryIds = [];
    _selectedDeliveryCities = [];
    _deliveryPriceController.clear();
    _freeDeliveryMinController.clear();
    _selectedDeliveryType = 'standard';
    _latitudeController.clear();
    _longitudeController.clear();
    _facebookController.clear();
    _instagramController.clear();
    _whatsappController.clear();
    _selectedLogo = null;
    _selectedBanner = null;

    // Réinitialiser les horaires
    _openingHours = {
      'lundi': {'open': '08:00', 'close': '18:00', 'closed': 'false'},
      'mardi': {'open': '08:00', 'close': '18:00', 'closed': 'false'},
      'mercredi': {'open': '08:00', 'close': '18:00', 'closed': 'false'},
      'jeudi': {'open': '08:00', 'close': '18:00', 'closed': 'false'},
      'vendredi': {'open': '08:00', 'close': '18:00', 'closed': 'false'},
      'samedi': {'open': '09:00', 'close': '14:00', 'closed': 'false'},
      'dimanche': {'open': '00:00', 'close': '00:00', 'closed': 'true'},
    };
  }

  void _selectShop(Map<String, dynamic> shop) {
    setState(() {
      _selectedShop = shop;
      _isCreating = false;
      _isEditing = false;
    });
  }

  void _backToList() {
    setState(() {
      _selectedShop = null;
      _isCreating = false;
      _isEditing = false;
    });
    _loadShops();
  }

  void _toggleCategory(int categoryId) {
    setState(() {
      if (_selectedCategoryIds.contains(categoryId)) {
        _selectedCategoryIds.remove(categoryId);
      } else {
        _selectedCategoryIds.add(categoryId);
      }
    });
  }

  void _toggleDeliveryCity(String city) {
    setState(() {
      if (_selectedDeliveryCities.contains(city)) {
        _selectedDeliveryCities.remove(city);
      } else {
        _selectedDeliveryCities.add(city);
      }
    });
  }

  void _updateOpeningHour(String day, String field, String value) {
    setState(() {
      _openingHours[day]?[field] = value;
    });
  }

  void _toggleDayClosed(String day) {
    setState(() {
      final isClosed = _openingHours[day]?['closed'] == 'true';
      _openingHours[day]?['closed'] = (!isClosed).toString();
    });
  }

  Future<void> _createShop() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    // Préparer les horaires
    final Map<String, dynamic> openingHoursData = {};
    for (var entry in _openingHours.entries) {
      if (entry.value['closed'] == 'true') {
        openingHoursData[entry.key] = {'closed': true};
      } else {
        openingHoursData[entry.key] = {
          'open': entry.value['open'],
          'close': entry.value['close'],
          'closed': false,
        };
      }
    }

    try {
      final result = await _apiService.createShop(
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        address: _addressController.text.trim(),
        phone: _phoneController.text.trim(),
        email: _emailController.text.trim(),
        city: _cityController.text.trim(),
        postalCode: _postalCodeController.text.trim(),
        categoryIds: _selectedCategoryIds.isNotEmpty ? _selectedCategoryIds : null,
        token: _token!,
        photo: _selectedLogo,
        banner: _selectedBanner,
        deliveryCities: _selectedDeliveryCities.isNotEmpty ? _selectedDeliveryCities : null,
        deliveryPrice: _deliveryPriceController.text.isNotEmpty ? double.parse(_deliveryPriceController.text) : null,
        freeDeliveryMinAmount: _freeDeliveryMinController.text.isNotEmpty ? double.parse(_freeDeliveryMinController.text) : null,
        deliveryType: _selectedDeliveryType,
        latitude: _latitudeController.text.isNotEmpty ? double.parse(_latitudeController.text) : null,
        longitude: _longitudeController.text.isNotEmpty ? double.parse(_longitudeController.text) : null,
        openingHours: openingHoursData,
        facebookUrl: _facebookController.text.trim().isNotEmpty ? _facebookController.text.trim() : null,
        instagramUrl: _instagramController.text.trim().isNotEmpty ? _instagramController.text.trim() : null,
        whatsappNumber: _whatsappController.text.trim().isNotEmpty ? _whatsappController.text.trim() : null,
      );

      if (result['success']) {
        _showSuccess('Boutique créée avec succès !');
        _backToList();
      } else {
        _showError(result['message'] ?? 'Erreur lors de la création');
        setState(() => _isLoading = false);
      }
    } catch (e) {
      _showError('Erreur de connexion');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateShop() async {
    if (!_formKey.currentState!.validate() || _selectedShop == null) return;

    setState(() => _isLoading = true);

    // Préparer les horaires
    final Map<String, dynamic> openingHoursData = {};
    for (var entry in _openingHours.entries) {
      if (entry.value['closed'] == 'true') {
        openingHoursData[entry.key] = {'closed': true};
      } else {
        openingHoursData[entry.key] = {
          'open': entry.value['open'],
          'close': entry.value['close'],
          'closed': false,
        };
      }
    }

    try {
      final result = await _apiService.updateShop(
        shopId: _selectedShop!['id'],
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        address: _addressController.text.trim(),
        phone: _phoneController.text.trim(),
        email: _emailController.text.trim(),
        city: _cityController.text.trim(),
        postalCode: _postalCodeController.text.trim(),
        categoryIds: _selectedCategoryIds,
        photo: _selectedLogo,
        banner: _selectedBanner,
        token: _token!,
        deliveryCities: _selectedDeliveryCities,
        deliveryPrice: _deliveryPriceController.text.isNotEmpty ? double.parse(_deliveryPriceController.text) : 0,
        freeDeliveryMinAmount: _freeDeliveryMinController.text.isNotEmpty ? double.parse(_freeDeliveryMinController.text) : null,
        deliveryType: _selectedDeliveryType,
        latitude: _latitudeController.text.isNotEmpty ? double.parse(_latitudeController.text) : null,
        longitude: _longitudeController.text.isNotEmpty ? double.parse(_longitudeController.text) : null,
        openingHours: openingHoursData,
        facebookUrl: _facebookController.text.trim().isNotEmpty ? _facebookController.text.trim() : null,
        instagramUrl: _instagramController.text.trim().isNotEmpty ? _instagramController.text.trim() : null,
        whatsappNumber: _whatsappController.text.trim().isNotEmpty ? _whatsappController.text.trim() : null,
      );

      if (result['success']) {
        _showSuccess('Boutique mise à jour !');
        setState(() {
          _selectedShop = result['shop'] ?? _selectedShop;
          _isEditing = false;
        });
        _loadShops();
      } else {
        _showError(result['message'] ?? 'Erreur lors de la mise à jour');
        setState(() => _isLoading = false);
      }
    } catch (e) {
      _showError('Erreur de connexion');
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

  void _safePop() {
    if (_isCreating || _selectedShop != null) {
      _backToList();
    } else if (Navigator.of(context).canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.home);
    }
  }

  void _shareShop() {
    if (_selectedShop == null) return;

    final shopName = _selectedShop!['name'] ?? 'Ma boutique';
    final shopId = _selectedShop!['id'];
    final shopLink = '${AppConstants.apiBaseUrl.replaceAll('/api', '')}/shop/$shopId';
    final shareText = 'Découvrez ma boutique $shopName sur Nora! 🛒\n\n🔗 $shopLink';

    Share.share(shareText, subject: 'Ma boutique sur Nora');
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && !_isEditing && !_isCreating && _selectedShop == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    // 1. VUE LISTE DES BOUTIQUES
    if (!_isCreating && _selectedShop == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: CustomAppBar(
          title: 'Mes boutiques',
          showBackButton: true,
          onBackPressed: _safePop,
        ),
        body: _shops.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.store, size: 80, color: AppColors.textTertiary),
                    const SizedBox(height: 16),
                    const Text(
                      'Vous n\'avez pas encore de boutique',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Créez votre première boutique pour commencer à vendre',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _openCreateForm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                      child: const Text('Créer ma boutique'),
                    ),
                  ],
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _shops.length,
                itemBuilder: (context, index) {
                  final shop = _shops[index];
                  final logo = shop['photo'] ?? shop['logo'];

                  String statusText = 'Inconnu';
                  Color statusColor = AppColors.textTertiary;
                  if (shop['status'] == 'en_attente') {
                    statusText = 'En attente de validation';
                    statusColor = Colors.orange;
                  } else if (shop['status'] == 'active') {
                    statusText = 'Active';
                    statusColor = AppColors.success;
                  } else if (shop['status'] == 'refusee') {
                    statusText = 'Refusée';
                    statusColor = AppColors.error;
                  }

                  return Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: InkWell(
                      onTap: () => _selectShop(shop),
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.backgroundLight,
                                image: logo != null && logo.toString().isNotEmpty
                                    ? DecorationImage(
                                        image: CachedNetworkImageProvider(_getFullImageUrl(logo)),
                                        fit: BoxFit.cover,
                                      )
                                    : null,
                              ),
                              child: logo == null || logo.toString().isEmpty
                                  ? const Icon(Icons.store, color: AppColors.textSecondary)
                                  : null,
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    shop['name'] ?? 'Boutique sans nom',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    statusText,
                                    style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.w500),
                                  ),
                                  if (shop['categories'] != null && (shop['categories'] as List).isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Wrap(
                                      spacing: 4,
                                      children: (shop['categories'] as List).take(2).map((cat) {
                                        return Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: AppColors.backgroundLight,
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            cat['name'],
                                            style: const TextStyle(fontSize: 10),
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            const Icon(Icons.chevron_right, color: AppColors.textSecondary),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
        floatingActionButton: _shops.isNotEmpty
            ? FloatingActionButton(
                onPressed: _openCreateForm,
                backgroundColor: AppColors.primary,
                child: const Icon(Icons.add),
              )
            : null,
      );
    }

    // 2. VUE CRÉATION OU ÉDITION
    if (_isCreating || _isEditing) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: CustomAppBar(
          title: _isCreating ? 'Nouvelle boutique' : 'Modifier ma boutique',
          showBackButton: true,
          onBackPressed: _backToList,
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      // === IMAGES ===
                      _buildImageSection(),
                      const SizedBox(height: 24),

                      // === INFORMATIONS GÉNÉRALES ===
                      _buildGeneralInfoSection(),
                      const SizedBox(height: 16),

                      // === CATÉGORIES ===
                      _buildCategoriesSection(),
                      const SizedBox(height: 16),

                      // === LIVRAISON ===
                      _buildDeliverySection(),
                      const SizedBox(height: 16),

                      // === COORDONNÉES GPS ===
                      _buildGpsSection(),
                      const SizedBox(height: 16),

                      // === HORAIRES D'OUVERTURE ===
                      _buildOpeningHoursSection(),
                      const SizedBox(height: 16),

                      // === RÉSEAUX SOCIAUX ===
                      _buildSocialSection(),
                      const SizedBox(height: 32),

                      // === BOUTONS ===
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: _backToList,
                              child: const Text('Annuler'),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _isCreating ? _createShop : _updateShop,
                              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                              child: Text(_isCreating ? 'Créer' : 'Enregistrer'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
      );
    }

    // 3. VUE DÉTAILS BOUTIQUE
    return _buildShopDetailView();
  }

  Widget _buildImageSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Logo de la boutique', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: _pickLogo,
          child: Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.backgroundLight,
              border: Border.all(color: AppColors.border),
              image: _selectedLogo != null
                  ? DecorationImage(image: FileImage(_selectedLogo!), fit: BoxFit.cover)
                  : (_selectedShop != null && _selectedShop!['photo'] != null && !_isCreating
                      ? DecorationImage(image: CachedNetworkImageProvider(_getFullImageUrl(_selectedShop!['photo'])), fit: BoxFit.cover)
                      : null),
            ),
            child: (_selectedLogo == null && (_isCreating || _selectedShop == null || _selectedShop!['photo'] == null))
                ? const Icon(Icons.camera_alt, size: 40, color: AppColors.textTertiary)
                : null,
          ),
        ),
        const SizedBox(height: 16),

        const Text('Bannière', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: _pickBanner,
          child: Container(
            height: 120,
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.backgroundLight,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
              image: _selectedBanner != null
                  ? DecorationImage(image: FileImage(_selectedBanner!), fit: BoxFit.cover)
                  : (_selectedShop != null && _selectedShop!['banner'] != null && !_isCreating
                      ? DecorationImage(image: CachedNetworkImageProvider(_getFullImageUrl(_selectedShop!['banner'])), fit: BoxFit.cover)
                      : null),
            ),
            child: (_selectedBanner == null && (_isCreating || _selectedShop == null || _selectedShop!['banner'] == null))
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_photo_alternate, size: 40, color: AppColors.textTertiary),
                        SizedBox(height: 8),
                        Text('Ajouter une bannière', style: TextStyle(color: AppColors.textSecondary)),
                      ],
                    ),
                  )
                : null,
          ),
        ),
      ],
    );
  }

  Widget _buildGeneralInfoSection() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            const Text('Informations générales', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Nom de la boutique', border: OutlineInputBorder()),
              validator: (v) => v == null || v.isEmpty ? 'Nom requis' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _descriptionController,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _addressController,
              decoration: const InputDecoration(labelText: 'Adresse', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _cityController,
              decoration: const InputDecoration(labelText: 'Ville', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _postalCodeController,
              decoration: const InputDecoration(labelText: 'Code postal', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _phoneController,
              decoration: const InputDecoration(labelText: 'Téléphone', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder()),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoriesSection() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Catégories', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _categories.map((category) {
                final categoryId = category['id'] as int;
                final isSelected = _selectedCategoryIds.contains(categoryId);
                return FilterChip(
                  label: Text(category['name']),
                  selected: isSelected,
                  onSelected: (_) => _toggleCategory(categoryId),
                  backgroundColor: AppColors.backgroundLight,
                  selectedColor: AppColors.primary.withOpacity(0.2),
                  checkmarkColor: AppColors.primary,
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeliverySection() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Livraison', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),

            const Text('Villes de livraison', style: TextStyle(fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _availableCities.map((city) {
                final isSelected = _selectedDeliveryCities.contains(city);
                return FilterChip(
                  label: Text(city),
                  selected: isSelected,
                  onSelected: (_) => _toggleDeliveryCity(city),
                  backgroundColor: AppColors.backgroundLight,
                  selectedColor: AppColors.primary.withOpacity(0.2),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),

            TextFormField(
              controller: _deliveryPriceController,
              decoration: const InputDecoration(labelText: 'Prix de livraison (FCFA)', border: OutlineInputBorder()),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),

            TextFormField(
              controller: _freeDeliveryMinController,
              decoration: const InputDecoration(labelText: 'Livraison gratuite à partir de (FCFA)', border: OutlineInputBorder()),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),

            const Text('Type de livraison', style: TextStyle(fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: RadioListTile(
                    title: const Text('Standard'),
                    value: 'standard',
                    groupValue: _selectedDeliveryType,
                    onChanged: (value) => setState(() => _selectedDeliveryType = value.toString()),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                Expanded(
                  child: RadioListTile(
                    title: const Text('Express'),
                    value: 'express',
                    groupValue: _selectedDeliveryType,
                    onChanged: (value) => setState(() => _selectedDeliveryType = value.toString()),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                Expanded(
                  child: RadioListTile(
                    title: const Text('Les deux'),
                    value: 'both',
                    groupValue: _selectedDeliveryType,
                    onChanged: (value) => setState(() => _selectedDeliveryType = value.toString()),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGpsSection() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Coordonnées GPS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            TextFormField(
              controller: _latitudeController,
              decoration: const InputDecoration(labelText: 'Latitude', border: OutlineInputBorder(), hintText: 'Ex: 4.051056'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _longitudeController,
              decoration: const InputDecoration(labelText: 'Longitude', border: OutlineInputBorder(), hintText: 'Ex: 9.767869'),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOpeningHoursSection() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          ListTile(
            title: const Text('Horaires d\'ouverture', style: TextStyle(fontWeight: FontWeight.bold)),
            trailing: IconButton(
              icon: Icon(_showOpeningHours ? Icons.expand_less : Icons.expand_more),
              onPressed: () => setState(() => _showOpeningHours = !_showOpeningHours),
            ),
            onTap: () => setState(() => _showOpeningHours = !_showOpeningHours),
          ),
          if (_showOpeningHours)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: _openingHours.keys.map((day) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 100,
                          child: Text(day[0].toUpperCase() + day.substring(1)),
                        ),
                        Expanded(
                          child: Row(
                            children: [
                              Checkbox(
                                value: _openingHours[day]?['closed'] == 'true',
                                onChanged: (_) => _toggleDayClosed(day),
                              ),
                              const Text('Fermé'),
                            ],
                          ),
                        ),
                        if (_openingHours[day]?['closed'] != 'true') ...[
                          const SizedBox(width: 8),
                          SizedBox(
                            width: 80,
                            child: TextFormField(
                              initialValue: _openingHours[day]?['open'],
                              decoration: const InputDecoration(hintText: 'Ouverture', border: OutlineInputBorder()),
                              onChanged: (value) => _updateOpeningHour(day, 'open', value),
                            ),
                          ),
                          const SizedBox(width: 8),
                          SizedBox(
                            width: 80,
                            child: TextFormField(
                              initialValue: _openingHours[day]?['close'],
                              decoration: const InputDecoration(hintText: 'Fermeture', border: OutlineInputBorder()),
                              onChanged: (value) => _updateOpeningHour(day, 'close', value),
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSocialSection() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Réseaux sociaux', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            TextFormField(
              controller: _facebookController,
              decoration: const InputDecoration(
                labelText: 'Facebook',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.facebook, color: Color(0xFF1877F2)),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _instagramController,
              decoration: const InputDecoration(
                labelText: 'Instagram',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.camera_alt, color: Color(0xFFE4405F)),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _whatsappController,
              decoration: const InputDecoration(
                labelText: 'WhatsApp',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.chat, color: Color(0xFF25D366)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _requestCertification(int shopId) async {
    setState(() => _isLoading = true);
    try {
      final result = await _apiService.requestCertification(shopId, _token!);
      if (result['success']) {
        _showSuccess('Demande de certification envoyée avec succès !');
        // Recharger les boutiques
        await _loadShops();
        // Mettre à jour la boutique sélectionnée
        if (_selectedShop != null && _selectedShop!['id'] == shopId) {
          final updatedShop = _shops.firstWhere((s) => s['id'] == shopId, orElse: () => _selectedShop);
          setState(() {
            _selectedShop = updatedShop;
          });
        }
      } else {
        _showError(result['message'] ?? 'Erreur lors de la demande');
      }
    } catch (e) {
      _showError('Erreur de connexion');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showCertificationBenefitsDialog(Map<String, dynamic> shop) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.verified, color: AppColors.primary, size: 28),
            SizedBox(width: 10),
            Text('Devenir certifié', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'La certification Nora offre de nombreux avantages pour booster les ventes de votre boutique :',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 16),
            _buildBenefitItem(Icons.trending_up, 'Plus de visibilité', 'Votre boutique est mise en avant dans les recherches.'),
            _buildBenefitItem(Icons.verified, 'Badge de confiance', 'Rassurez vos clients avec le badge de certification vert.'),
            _buildBenefitItem(Icons.card_giftcard, 'Offres exclusives', 'Accédez à des campagnes de promotion exclusives.'),
            _buildBenefitItem(Icons.support_agent, 'Support 24/7', 'Un conseiller dédié pour répondre à vos besoins.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Plus tard', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context); // Close modal
              await _requestCertification(shop['id']);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
            child: const Text('Se certifier maintenant'),
          ),
        ],
      ),
    );
  }

  Widget _buildBenefitItem(IconData icon, String title, String desc) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.primary, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                Text(desc, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShopDetailView() {
    final shop = _selectedShop!;
    final logo = shop['photo'] ?? shop['logo'];
    final banner = shop['banner'];
    final categories = shop['categories'] ?? [];
    final deliveryCities = shop['delivery_cities'] ?? [];
    final openingHours = shop['opening_hours'];

    String statusText = 'Inconnu';
    Color statusColor = AppColors.textTertiary;
    if (shop['status'] == 'en_attente') {
      statusText = 'En attente de validation';
      statusColor = Colors.orange;
    } else if (shop['status'] == 'active') {
      statusText = 'Active';
      statusColor = AppColors.success;
    } else if (shop['status'] == 'refusee') {
      statusText = 'Refusée';
      statusColor = AppColors.error;
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: CustomAppBar(
        title: shop['name'] ?? 'Ma boutique',
        showBackButton: true,
        onBackPressed: _backToList,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit, color: AppColors.primary),
            onPressed: _openEditForm,
          ),
          IconButton(
            icon: const Icon(Icons.share, color: AppColors.primary),
            onPressed: _shareShop,
            tooltip: 'Partager ma boutique',
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Bannière
            Container(
              height: 150,
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.backgroundLight,
                image: banner != null && banner.toString().isNotEmpty
                    ? DecorationImage(
                        image: CachedNetworkImageProvider(_getFullImageUrl(banner)),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: banner == null
                  ? const Center(child: Icon(Icons.image, size: 50, color: AppColors.textTertiary))
                  : null,
            ),

            // Logo et infos
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: AppColors.primaryGradient,
                          border: Border.all(color: Colors.white, width: 3),
                        ),
                        child: ClipOval(
                          child: logo != null && logo.toString().isNotEmpty
                              ? CachedNetworkImage(
                                  imageUrl: _getFullImageUrl(logo),
                                  fit: BoxFit.cover,
                                  errorWidget: (_, __, ___) => const Icon(Icons.store, color: Colors.white, size: 40),
                                )
                              : const Icon(Icons.store, color: Colors.white, size: 40),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(shop['name'] ?? '', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            Text(
                              statusText,
                              style: TextStyle(color: statusColor, fontSize: 13, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Catégories
                  if (categories.isNotEmpty) ...[
                    Wrap(
                      spacing: 8,
                      children: categories.map((cat) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.backgroundLight,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(cat['name'], style: const TextStyle(fontSize: 12)),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Description
                  if (shop['description'] != null && shop['description'].toString().isNotEmpty) ...[
                    Text(shop['description'], style: const TextStyle(color: AppColors.textSecondary)),
                    const SizedBox(height: 16),
                  ],

                  // Informations générales
                  _buildInfoRow(Icons.location_on, 'Adresse', shop['address']),
                  _buildInfoRow(Icons.phone, 'Téléphone', shop['phone']),
                  _buildInfoRow(Icons.email, 'Email', shop['email']),
                  const SizedBox(height: 16),

                  // Livraison
                  if (deliveryCities.isNotEmpty || shop['delivery_price'] != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.backgroundLight,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Livraison', style: TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          if (deliveryCities.isNotEmpty)
                            _buildInfoRow(Icons.location_city, 'Villes', (deliveryCities as List).join(', ')),
                          if (shop['delivery_price'] != null)
                            _buildInfoRow(Icons.money, 'Prix', '${shop['delivery_price']} FCFA'),
                          if (shop['free_delivery_min_amount'] != null)
                            _buildInfoRow(Icons.local_offer, 'Livraison gratuite', 'à partir de ${shop['free_delivery_min_amount']} FCFA'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.backgroundLight,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Icon(
                              shop['certifiee'] == true
                                  ? Icons.verified
                                  : (shop['has_pending_certification'] == true
                                      ? Icons.hourglass_empty
                                      : Icons.new_releases),
                              color: shop['certifiee'] == true
                                  ? AppColors.primary
                                  : (shop['has_pending_certification'] == true
                                      ? Colors.orange
                                      : AppColors.textSecondary),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                shop['certifiee'] == true
                                    ? 'Boutique certifiée'
                                    : (shop['has_pending_certification'] == true
                                        ? 'Certification en attente de validation'
                                        : 'Boutique non certifiée'),
                                style: const TextStyle(fontWeight: FontWeight.w500),
                              ),
                            ),
                          ],
                        ),
                        if (shop['certifiee'] != true) ...[
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: shop['has_pending_certification'] == true
                                  ? null
                                  : () => _showCertificationBenefitsDialog(shop),
                              icon: const Icon(Icons.verified, size: 18),
                              label: Text(
                                shop['has_pending_certification'] == true
                                    ? 'Demande en attente...'
                                    : 'Demander la certification',
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                padding: const EdgeInsets.symmetric(vertical: 10),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String? value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.textSecondary),
          const SizedBox(width: 12),
          SizedBox(width: 80, child: Text(label, style: const TextStyle(color: AppColors.textSecondary))),
          Expanded(child: Text(value ?? 'Non renseigné', style: const TextStyle(fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }
}
