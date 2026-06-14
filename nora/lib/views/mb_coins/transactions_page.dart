import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../config/app_colors.dart';
import '../../../services/api_service.dart';
import '../../../services/storage_service.dart';
import '../../../utils/converters.dart';

class TransactionsPage extends StatefulWidget {
  const TransactionsPage({super.key});

  @override
  State<TransactionsPage> createState() => _TransactionsPageState();
}

class _TransactionsPageState extends State<TransactionsPage> {
  final ApiService _apiService = ApiService();
  List<dynamic> _transactions = [];
  bool _isLoading = true;
  String? _filter;

  final List<Map<String, String>> _filters = [
    {'value': 'all', 'label': 'Toutes'},
    {'value': 'credit', 'label': 'Crédits'},
    {'value': 'debit', 'label': 'Débits'},
  ];

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    setState(() => _isLoading = true);
    
    final token = await StorageService().getToken();
    if (token == null) {
      setState(() => _isLoading = false);
      return;
    }
    
    try {
      final type = _filter == 'all' ? null : _filter;
      final result = await _apiService.getMbCoinsTransactions(
        type: type,
        limit: 50,
        token: token,
      );
      
      if (result['success'] && result['transactions'] != null) {
        setState(() {
          _transactions = result['transactions'];
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      print('Erreur chargement transactions: $e');
      setState(() => _isLoading = false);
    }
  }

  String _formatDate(String dateTimeStr) {
    final dateTime = DateTime.tryParse(dateTimeStr);
    if (dateTime == null) return '';
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inDays > 7) {
      return '${difference.inDays ~/ 7} sem';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} j';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} h';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} min';
    } else {
      return 'à l\'instant';
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
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Historique des transactions',
          style: TextStyle(color: AppColors.textPrimary),
        ),
      ),
      body: Column(
        children: [
          // Filtres
          Container(
            height: 50,
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: _filters.map((filter) {
                final isSelected = _filter == filter['value'];
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _filter = filter['value'];
                    });
                    _loadTransactions();
                  },
                  child: Container(
                    margin: const EdgeInsets.only(right: 12),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primary : AppColors.backgroundLight,
                      border: Border.all(
                        color: isSelected ? AppColors.primary : AppColors.border,
                      ),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Text(
                      filter['label']!,
                      style: TextStyle(
                        color: isSelected ? Colors.white : AppColors.textSecondary,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  )
                : _transactions.isEmpty
                    ? const Center(
                        child: Text('Aucune transaction'),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _transactions.length,
                        itemBuilder: (context, index) {
                          final transaction = _transactions[index];
                          final amount = toDoubleSafe(transaction['amount']);
                          final type = toStringSafe(transaction['type']);
                          final description = toStringSafe(transaction['description']);
                          final createdAt = toStringSafe(transaction['created_at']);
                          final isCredit = type == 'credit';
                          
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.backgroundLight,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 50,
                                  height: 50,
                                  decoration: BoxDecoration(
                                    color: isCredit ? AppColors.success.withOpacity(0.1) : AppColors.error.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(25),
                                  ),
                                  child: Icon(
                                    isCredit ? Icons.arrow_upward : Icons.arrow_downward,
                                    color: isCredit ? AppColors.success : AppColors.error,
                                    size: 28,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        description,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        _formatDate(createdAt),
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: AppColors.textTertiary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  '${isCredit ? '+' : '-'} ${amount.toInt()} MB',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: isCredit ? AppColors.success : AppColors.error,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}