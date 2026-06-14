import 'package:flutter/material.dart';
import '../../../config/app_colors.dart';

class DeliveryAddressForm extends StatefulWidget {
  final Function(Map<String, dynamic>) onAddressChanged;

  const DeliveryAddressForm({super.key, required this.onAddressChanged});

  @override
  State<DeliveryAddressForm> createState() => _DeliveryAddressFormState();
}

class _DeliveryAddressFormState extends State<DeliveryAddressForm> {
  final _formKey = GlobalKey<FormState>();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _postalCodeController = TextEditingController();
  final _phoneController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _addressController.addListener(_notifyParent);
    _cityController.addListener(_notifyParent);
    _postalCodeController.addListener(_notifyParent);
    _phoneController.addListener(_notifyParent);
  }

  void _notifyParent() {
    widget.onAddressChanged({
      'address': _addressController.text,
      'city': _cityController.text,
      'postal_code': _postalCodeController.text,
      'phone': _phoneController.text,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Adresse de livraison',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _addressController,
            decoration: const InputDecoration(
              labelText: 'Adresse',
              hintText: 'Rue, quartier, résidence...',
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Adresse requise';
              }
              return null;
            },
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _cityController,
                  decoration: const InputDecoration(
                    labelText: 'Ville',
                    hintText: 'Douala, Yaoundé...',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Ville requise';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _postalCodeController,
                  decoration: const InputDecoration(
                    labelText: 'Code postal',
                    hintText: 'Optionnel',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _phoneController,
            decoration: const InputDecoration(
              labelText: 'Téléphone',
              hintText: 'Ex: 6XX XXX XXX',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.phone,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Téléphone requis';
              }
              if (value.length < 8) {
                return 'Téléphone invalide';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _addressController.dispose();
    _cityController.dispose();
    _postalCodeController.dispose();
    _phoneController.dispose();
    super.dispose();
  }
}