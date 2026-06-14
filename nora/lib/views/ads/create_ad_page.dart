import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:go_router/go_router.dart';
import '../../../config/app_colors.dart';
import '../../../services/ad_service.dart';
import '../../../services/storage_service.dart';

class CreateAdPage extends StatefulWidget {
  const CreateAdPage({super.key});

  @override
  State<CreateAdPage> createState() => _CreateAdPageState();
}

class _CreateAdPageState extends State<CreateAdPage> {
  final AdService _adService = AdService();
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _linkUrlController = TextEditingController();
  final _budgetController = TextEditingController();

  String _selectedType = 'banner';
  String _selectedPosition = 'top';
  File? _selectedImage;
  bool _isLoading = false;

  final List<Map<String, dynamic>> _types = [
    {'value': 'banner', 'label': 'Bannière', 'icon': Icons.crop_original},
    {'value': 'video', 'label': 'Vidéo', 'icon': Icons.videocam},
    {'value': 'carousel', 'label': 'Carrousel', 'icon': Icons.view_carousel},
    {'value': 'popup', 'label': 'Popup', 'icon': Icons.center_focus_strong},
  ];

  final List<Map<String, dynamic>> _positions = [
    {'value': 'top', 'label': 'Haut de page', 'icon': Icons.vertical_align_top},
    {'value': 'bottom', 'label': 'Bas de page', 'icon': Icons.vertical_align_bottom},
    {'value': 'shop_top', 'label': 'Dans les boutiques', 'icon': Icons.store},
  ];

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
      });
    }
  }

  Future<void> _createAd() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedImage == null) {
      _showError('Veuillez sélectionner une image');
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
      final imageBytes = await _selectedImage!.readAsBytes();

      final result = await _adService.createAd(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        type: _selectedType,
        position: _selectedPosition,
        linkUrl: _linkUrlController.text.trim(),
        budget: double.parse(_budgetController.text),
        token: token,
        imageBytes: imageBytes,
      );

      if (result['success']) {
        _showSuccess('Publicité créée avec succès !');
        if (mounted) {
          context.pop(true);
        }
      } else {
        _showError(result['message'] ?? 'Erreur lors de la création');
      }
    } catch (e) {
      _showError('Erreur de connexion');
    } finally {
      setState(() => _isLoading = false);
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
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Créer une publicité',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _createAd,
            child: Text(
              'Publier',
              style: TextStyle(
                color: _isLoading ? AppColors.textTertiary : AppColors.primary,
                fontWeight: FontWeight.w600,
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
              // Image
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 150,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppColors.backgroundLight,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                    image: _selectedImage != null
                        ? DecorationImage(
                      image: FileImage(_selectedImage!),
                      fit: BoxFit.cover,
                    )
                        : null,
                  ),
                  child: _selectedImage == null
                      ? const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_photo_alternate, size: 40),
                      SizedBox(height: 8),
                      Text('Tapez pour sélectionner une image'),
                    ],
                  )
                      : null,
                ),
              ),
              const SizedBox(height: 16),

              // Titre
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Titre de la publicité',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Titre requis';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Description
              TextFormField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Description requise';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Type
              DropdownButtonFormField<String>(
                value: _selectedType,
                decoration: const InputDecoration(
                  labelText: 'Type de publicité',
                  border: OutlineInputBorder(),
                ),
                items: _types.map<DropdownMenuItem<String>>((type) {
                  return DropdownMenuItem<String>(
                    value: type['value'] as String,
                    child: Row(
                      children: [
                        Icon(type['icon'] as IconData, size: 20),
                        const SizedBox(width: 8),
                        Text(type['label'] as String),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() => _selectedType = value!);
                },
              ),
              const SizedBox(height: 16),

              // Position
              DropdownButtonFormField<String>(
                value: _selectedPosition,
                decoration: const InputDecoration(
                  labelText: 'Position',
                  border: OutlineInputBorder(),
                ),
                items: _positions.map<DropdownMenuItem<String>>((position) {
                  return DropdownMenuItem<String>(
                    value: position['value'] as String,
                    child: Row(
                      children: [
                        Icon(position['icon'] as IconData, size: 20),
                        const SizedBox(width: 8),
                        Text(position['label'] as String),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() => _selectedPosition = value!);
                },
              ),
              const SizedBox(height: 16),

              // Lien
              TextFormField(
                controller: _linkUrlController,
                decoration: const InputDecoration(
                  labelText: 'Lien de destination',
                  hintText: 'https://...',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Lien requis';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Budget
              TextFormField(
                controller: _budgetController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Budget (FCFA)',
                  hintText: '10000',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Budget requis';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Montant invalide';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 24),

              // Information
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.info.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, color: AppColors.info),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'La création de publicités est exclusivement réservée aux boutiques certifiées afin de garantir la qualité sur Nora Marketplace.',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.info,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _linkUrlController.dispose();
    _budgetController.dispose();
    super.dispose();
  }
}