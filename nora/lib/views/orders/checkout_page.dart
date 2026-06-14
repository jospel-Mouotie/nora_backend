import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../config/app_colors.dart';
import '../../../config/routes.dart';
import '../../../services/order_api_service.dart';
import '../../../services/api_service.dart';
import '../../../services/storage_service.dart';
import '../../../widgets/orders/delivery_address_form.dart';
import '../../../utils/converters.dart';

class CheckoutPage extends StatefulWidget {
  const CheckoutPage({super.key});

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  final OrderApiService _orderApiService = OrderApiService();
  final ApiService _apiService = ApiService();
  final _formKey = GlobalKey<FormState>();
  
  bool _isLoading = true;
  Map<String, dynamic>? _cartSummary;
  Map<String, dynamic> _deliveryAddress = {};
  String _notes = '';

  @override
  void initState() {
    super.initState();
    _loadCartData();
  }

  Future<void> _loadCartData() async {
    final token = await StorageService().getToken();
    if (token == null) {
      _showLoginRequired();
      setState(() => _isLoading = false);
      return;
    }
    
    try {
      final result = await _apiService.getCart(token);
      if (result['success'] && result['cart'] != null) {
        final cart = result['cart'];
        final totalAmount = toDoubleSafe(cart['total_amount']);
        final items = cart['items'] ?? [];
        setState(() {
          _cartSummary = {
            'subtotal': totalAmount.toInt(),
            'delivery_fee': 0, // À ajuster selon la logique de livraison
            'total': totalAmount.toInt(),
            'item_count': cart['total_items'] ?? items.length,
          };
          _isLoading = false;
        });
      } else {
        _showError('Erreur de chargement du panier');
        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint('Erreur réseau cart: $e');
      _showError('Erreur réseau lors de la récupération du panier');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _placeOrder() async {
    if (!_formKey.currentState!.validate()) return;

    _formKey.currentState!.save();

    setState(() => _isLoading = true);

    final token = await StorageService().getToken();
    if (token == null) {
      _showLoginRequired();
      setState(() => _isLoading = false);
      return;
    }

    try {
      final result = await _orderApiService.createOrder(
        deliveryAddress: jsonEncode(_deliveryAddress),
        notes: _notes,
        token: token,
      );

      if (result['success']) {
        if (mounted) {
          context.push('${AppRoutes.orderSuccess}?orderId=${result['order']['order_number']}');
        }
      } else {
        _showError(result['message'] ?? 'Erreur lors de la commande');
      }
    } catch (e) {
      debugPrint('Erreur commande: $e');
      _showError('Erreur de connexion: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showLoginRequired() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Connexion requise'),
        content: const Text('Veuillez vous connecter pour passer commande'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              context.push(AppRoutes.login);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
            ),
            child: const Text('Se connecter'),
          ),
        ],
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_cartSummary == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

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
        title: const Text(
          'Validation commande',
          style: TextStyle(color: AppColors.textPrimary),
        ),
      ),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary)) 
          : Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Adresse de livraison
                    DeliveryAddressForm(
                      onAddressChanged: (address) {
                        _deliveryAddress = address;
                      },
                    ),
                    const SizedBox(height: 24),
                    
                    // Notes
                    TextFormField(
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Notes supplémentaires',
                        hintText: 'Instructions pour le livreur...',
                        border: OutlineInputBorder(),
                      ),
                      onSaved: (value) => _notes = value ?? '',
                    ),
                    const SizedBox(height: 24),
                    
                    // Récapitulatif
                    if (_cartSummary != null)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.backgroundLight,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            _buildSummaryRow('Sous-total (${_cartSummary!['item_count']} articles)', _cartSummary!['subtotal']),
                            const SizedBox(height: 8),
                            _buildSummaryRow('Frais de livraison', _cartSummary!['delivery_fee']),
                            const Divider(height: 16),
                            _buildSummaryRow('Total à payer', _cartSummary!['total'], isTotal: true),
                          ],
                        ),
                      ),
                    
                    const SizedBox(height: 24),
                    
                    // Message paiement
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, color: AppColors.primary),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Paiement à la livraison\nVous payez en espèces à la réception de votre commande.',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // Bouton commander
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _placeOrder,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Confirmer la commande',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSummaryRow(String label, int amount, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isTotal ? 16 : 14,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            color: isTotal ? AppColors.textPrimary : AppColors.textSecondary,
          ),
        ),
        Text(
          '${amount.toString().replaceAll('.0', '')} FCFA',
          style: TextStyle(
            fontSize: isTotal ? 18 : 14,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            color: isTotal ? AppColors.primary : AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}