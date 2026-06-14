import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../config/app_colors.dart';
import '../../../config/app_constants.dart';
import '../../../services/api_service.dart';
import '../../../services/storage_service.dart';
import '../../../services/language_service.dart';
import '../../../utils/converters.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final ApiService _apiService = ApiService();
  final LanguageService _languageService = LanguageService();
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  
  Map<String, dynamic>? _user;
  bool _isLoading = true;
  bool _isSaving = false;
  File? _selectedImage;
  String? _errorMessage;
  String? _token;

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
    _loadUser();
  }

  Future<void> _loadUser() async {
    setState(() => _isLoading = true);
    
    _token = await StorageService().getToken();
    if (_token == null) {
      setState(() => _isLoading = false);
      return;
    }
    
    try {
      final result = await _apiService.getUserProfile(_token!);
      if (result['success'] && result['user'] != null) {
        setState(() {
          _user = result['user'];
          _nameController.text = toStringSafe(_user?['name']);
          _phoneController.text = toStringSafe(_user?['phone']);
          _addressController.text = toStringSafe(_user?['address']);
          _cityController.text = toStringSafe(_user?['city']);
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = result['message'] ?? _languageService.translate('loading_error');
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Erreur chargement profil: $e');
      setState(() {
        _errorMessage = _languageService.translate('server_error');
        _isLoading = false;
      });
    }
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    
    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
      });
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isSaving = true);
    
    if (_token == null) {
      _showError(_languageService.translate('please_reconnect'));
      setState(() => _isSaving = false);
      return;
    }
    
    try {
      // Mettre à jour le profil
      final result = await _apiService.updateUserProfile(
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim().isNotEmpty ? _phoneController.text.trim() : null,
        address: _addressController.text.trim().isNotEmpty ? _addressController.text.trim() : null,
        city: _cityController.text.trim().isNotEmpty ? _cityController.text.trim() : null,
        token: _token!,
      );
      
      if (!result['success']) {
        _showError(result['message'] ?? _languageService.translate('profile_update_error'));
        setState(() => _isSaving = false);
        return;
      }
      
      // Upload de la photo si sélectionnée
      if (_selectedImage != null) {
        final photoResult = await _apiService.uploadProfilePicture(_selectedImage!, _token!);
        if (!photoResult['success']) {
          _showError('${_languageService.translate('photo_not_saved')}: ${photoResult['message']}');
        }
      }
      
      _showSuccess(_languageService.translate('profile_updated'));
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) context.pop();
      });
      
    } catch (e) {
      _showError(_languageService.translate('server_error'));
    } finally {
      setState(() => _isSaving = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.success,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    if (_user == null || _token == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(_languageService.translate('edit_profile')),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: AppColors.error),
              const SizedBox(height: 16),
              Text(_errorMessage ?? _languageService.translate('impossible_to_load_profile')),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _loadUser,
                child: Text(_languageService.translate('retry')),
              ),
            ],
          ),
        ),
      );
    }

    final avatar = _user?['profile_photo'];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              context.pop();
            } else {
              context.go('/home');
            }
          },
        ),
        title: Text(
          _languageService.translate('edit_profile'),
          style: const TextStyle(color: AppColors.textPrimary),
        ),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _saveProfile,
            child: Text(
              _languageService.translate('save'),
              style: TextStyle(
                color: _isSaving ? AppColors.textTertiary : AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Avatar
              Center(
                child: Stack(
                  children: [
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.primary, width: 3),
                      ),
                      child: ClipOval(
                        child: _selectedImage != null
                            ? Image.file(
                                _selectedImage!,
                                fit: BoxFit.cover,
                              )
                            : avatar != null && avatar.toString().isNotEmpty
                                ? CachedNetworkImage(
                                    imageUrl: _getFullImageUrl(avatar),
                                    fit: BoxFit.cover,
                                    placeholder: (context, url) => Container(
                                      color: AppColors.backgroundLight,
                                      child: const Icon(Icons.person, size: 50),
                                    ),
                                    errorWidget: (context, url, error) => Container(
                                      color: AppColors.backgroundLight,
                                      child: const Icon(Icons.person, size: 50),
                                    ),
                                  )
                                : Container(
                                    color: AppColors.backgroundLight,
                                    child: const Icon(Icons.person, size: 50),
                                  ),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: _pickImage,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.camera_alt,
                            size: 20,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Nom complet
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: _languageService.translate('full_name'),
                  hintText: _languageService.translate('your_name'),
                  prefixIcon: const Icon(Icons.person_outline),
                  border: const OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return _languageService.translate('name_required');
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 16),
              
              // Email (non modifiable)
              TextFormField(
                initialValue: toStringSafe(_user?['email']),
                enabled: false,
                decoration: InputDecoration(
                  labelText: _languageService.translate('email'),
                  prefixIcon: const Icon(Icons.email_outlined),
                  border: const OutlineInputBorder(),
                  filled: true,
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Téléphone
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: _languageService.translate('phone_number'),
                  hintText: _languageService.translate('phone_hint'),
                  prefixIcon: const Icon(Icons.phone_outlined),
                  border: const OutlineInputBorder(),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Adresse
              TextFormField(
                controller: _addressController,
                decoration: InputDecoration(
                  labelText: _languageService.translate('address'),
                  hintText: _languageService.translate('address_hint'),
                  prefixIcon: const Icon(Icons.location_on_outlined),
                  border: const OutlineInputBorder(),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Ville
              TextFormField(
                controller: _cityController,
                decoration: InputDecoration(
                  labelText: _languageService.translate('city'),
                  hintText: _languageService.translate('city_hint'),
                  prefixIcon: const Icon(Icons.location_city),
                  border: const OutlineInputBorder(),
                ),
              ),
              
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    super.dispose();
  }
}