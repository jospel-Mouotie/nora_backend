import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../config/app_colors.dart';
import '../../../services/api_service.dart';
import '../../../services/storage_service.dart';
import '../../../utils/converters.dart';

class WithdrawPage extends StatefulWidget {
  const WithdrawPage({super.key});

  @override
  State<WithdrawPage> createState() => _WithdrawPageState();
}

class _WithdrawPageState extends State<WithdrawPage> {
  final ApiService _apiService = ApiService();
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _accountNameController = TextEditingController();
  final _accountNumberController = TextEditingController();
  final _bankNameController = TextEditingController();
  
  Map<String, dynamic>? _balance;
  bool _isLoading = true;
  bool _isSubmitting = false;
  String? _selectedMethod = 'bank_transfer';

  final List<Map<String, dynamic>> _methods = [
    {'value': 'bank_transfer', 'label': 'Virement bancaire', 'icon': Icons.account_balance},
    {'value': 'orange_money', 'label': 'Orange Money', 'icon': Icons.phone_android},
    {'value': 'mtn_money', 'label': 'MTN Mobile Money', 'icon': Icons.phone_android},
  ];

  @override
  void initState() {
    super.initState();
    _loadBalance();
  }

  Future<void> _loadBalance() async {
    setState(() => _isLoading = true);
    
    final token = await StorageService().getToken();
    if (token == null) {
      setState(() => _isLoading = false);
      return;
    }
    
    try {
      final result = await _apiService.getMbCoinsBalance(token);
      if (result['success'] && result['balance'] != null) {
        setState(() {
          _balance = result['balance'];
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      print('Erreur solde: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _submitWithdraw() async {
    if (!_formKey.currentState!.validate()) return;
    
    final currentBalance = toDoubleSafe(_balance?['balance']);
    final amount = double.tryParse(_amountController.text) ?? 0;
    
    if (amount <= 0) {
      _showError('Montant invalide');
      return;
    }
    
    if (amount > currentBalance) {
      _showError('Solde insuffisant');
      return;
    }
    
    if (amount < 1000) {
      _showError('Montant minimum de retrait : 1000 MB');
      return;
    }
    
    setState(() => _isSubmitting = true);
    
    final token = await StorageService().getToken();
    if (token == null) {
      _showError('Veuillez vous reconnecter');
      setState(() => _isSubmitting = false);
      return;
    }
    
    try {
      Map<String, dynamic> details = {};
      if (_selectedMethod == 'bank_transfer') {
        details = {
          'account_name': _accountNameController.text.trim(),
          'account_number': _accountNumberController.text.trim(),
          'bank_name': _bankNameController.text.trim(),
        };
      } else {
        details = {
          'phone_number': _accountNumberController.text.trim(),
        };
      }
      
      final result = await _apiService.requestMbWithdrawal(
        amount: amount,
        method: _selectedMethod!,
        details: details,
        token: token,
      );
      
      if (result['success']) {
        _showSuccess('Demande de retrait envoyée avec succès !');
        Navigator.pop(context);
      } else {
        _showError(result['message'] ?? 'Erreur lors de la demande');
      }
    } catch (e) {
      _showError('Erreur de connexion');
    } finally {
      setState(() => _isSubmitting = false);
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
    final currentBalance = toDoubleSafe(_balance?['balance']).toInt();
    
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
          'Retirer MB Coins',
          style: TextStyle(color: AppColors.textPrimary),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Solde actuel
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Solde disponible',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white70,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '$currentBalance MB',
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Formulaire
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        // Montant
                        TextFormField(
                          controller: _amountController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Montant à retirer',
                            hintText: '1000',
                            prefixIcon: Icon(Icons.monetization_on),
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Montant requis';
                            }
                            return null;
                          },
                        ),
                        
                        const SizedBox(height: 20),
                        
                        // Méthode de retrait
                        const Text(
                          'Méthode de retrait',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ..._methods.map((method) => RadioListTile<String>(
                              value: method['value'],
                              groupValue: _selectedMethod,
                              onChanged: (value) {
                                setState(() {
                                  _selectedMethod = value;
                                });
                              },
                              title: Text(method['label']),
                              secondary: Icon(method['icon'], color: AppColors.primary),
                              contentPadding: EdgeInsets.zero,
                            )),
                        
                        const SizedBox(height: 20),
                        
                        // Détails selon la méthode
                        if (_selectedMethod == 'bank_transfer') ...[
                          TextFormField(
                            controller: _accountNameController,
                            decoration: const InputDecoration(
                              labelText: 'Nom du compte',
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Nom du compte requis';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _accountNumberController,
                            decoration: const InputDecoration(
                              labelText: 'Numéro de compte',
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Numéro de compte requis';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _bankNameController,
                            decoration: const InputDecoration(
                              labelText: 'Nom de la banque',
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Nom de la banque requis';
                              }
                              return null;
                            },
                          ),
                        ] else ...[
                          TextFormField(
                            controller: _accountNumberController,
                            keyboardType: TextInputType.phone,
                            decoration: InputDecoration(
                              labelText: _selectedMethod == 'orange_money' 
                                  ? 'Numéro Orange Money' 
                                  : 'Numéro MTN Mobile Money',
                              hintText: '6XXXXXXXX',
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Numéro de téléphone requis';
                              }
                              if (value.length < 8) {
                                return 'Numéro invalide';
                              }
                              return null;
                            },
                          ),
                        ],
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Bouton de validation
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _submitWithdraw,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: _isSubmitting
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Demander le retrait'),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Note
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.backgroundLight,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, size: 20, color: AppColors.textSecondary),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Le traitement des demandes de retrait prend 24 à 48h ouvrés.',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
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
}