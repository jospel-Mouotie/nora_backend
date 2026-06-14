import 'package:flutter/material.dart';
import '../../../config/app_colors.dart';
import '../../../services/order_api_service.dart';
import '../../../services/storage_service.dart';
import '../../views/admin/admin_order_chat_page.dart';

class MerchantOrdersPage extends StatefulWidget {
  const MerchantOrdersPage({super.key});

  @override
  State<MerchantOrdersPage> createState() => _MerchantOrdersPageState();
}

class _MerchantOrdersPageState extends State<MerchantOrdersPage> {
  final OrderApiService _orderApiService = OrderApiService();
  List<dynamic> _orders = [];
  bool _isLoading = true;
  String _selectedFilter = 'all';

  final List<Map<String, String>> _filters = [
    {'value': 'all', 'label': 'Toutes'},
    {'value': 'pending', 'label': 'En attente'},
    {'value': 'confirmed', 'label': 'Confirmées'},
    {'value': 'preparing', 'label': 'En préparation'},
    {'value': 'ready', 'label': 'Prêtes'},
    {'value': 'in_delivery', 'label': 'En livraison'},
    {'value': 'delivered', 'label': 'Livrées'},
    {'value': 'cancelled', 'label': 'Annulées'},
  ];

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    setState(() => _isLoading = true);

    final token = await StorageService().getToken();
    if (token == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      // Utiliser l'endpoint spécifique pour les boutiques
      final result = await _orderApiService.getShopOrders(token: token);
      if (result['success'] && result['orders'] != null) {
        setState(() {
          _orders = result['orders'];
          _isLoading = false;
        });
      } else {
        _loadTestOrders();
      }
    } catch (e) {
      print('Erreur _loadOrders: $e');
      _loadTestOrders();
    }
  }

  void _loadTestOrders() {
    setState(() {
      _orders = [
        {
          'order_number': 'ORD-001',
          'status': 'pending',
          'total_amount': 32000,
          'created_at': '2026-05-16 10:30',
          'customer_name': 'Jean Dupont',
          'items_count': 2,
        },
        {
          'order_number': 'ORD-002',
          'status': 'in_delivery',
          'total_amount': 45000,
          'created_at': '2026-05-16 09:15',
          'customer_name': 'Marie Laurent',
          'items_count': 3,
        },
        {
          'order_number': 'ORD-003',
          'status': 'delivered',
          'total_amount': 12800,
          'created_at': '2026-05-15 14:20',
          'customer_name': 'Paul Martin',
          'items_count': 1,
        },
      ];
      _isLoading = false;
    });
  }

  Future<void> _updateOrderStatus(String orderId, String newStatus) async {
    final token = await StorageService().getToken();
    if (token == null) return;

    try {
      await _orderApiService.updateOrderStatus(orderId, newStatus, token);
      _loadOrders();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Statut mis à jour'),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      print('Erreur mise à jour statut: $e');
    }
  }

  String _getStatusColor(String status) {
    switch (status) {
      case 'pending': return '#F59E0B';
      case 'confirmed': return '#3B82F6';
      case 'preparing': return '#8B5CF6';
      case 'ready': return '#10B981';
      case 'in_delivery': return '#06B6D4';
      case 'delivered': return '#10B981';
      case 'cancelled': return '#EF4444';
      default: return '#6B7280';
    }
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'pending': return 'En attente';
      case 'confirmed': return 'Confirmée';
      case 'preparing': return 'En préparation';
      case 'ready': return 'Prête';
      case 'in_delivery': return 'En livraison';
      case 'delivered': return 'Livrée';
      case 'cancelled': return 'Annulée';
      default: return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text(
          'Commandes',
          style: TextStyle(color: AppColors.textPrimary),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : Column(
              children: [
                // Filtres
                Container(
                  height: 50,
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: _filters.map((filter) {
                      final isSelected = _selectedFilter == filter['value'];
                      return GestureDetector(
                        onTap: () {
                          setState(() => _selectedFilter = filter['value']!);
                          // TODO: Filtrer les commandes
                        },
                        child: Container(
                          margin: const EdgeInsets.only(right: 12),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),

                // Liste des commandes
                Expanded(
                  child: _orders.isEmpty
                      ? const Center(
                          child: Text('Aucune commande'),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _orders.length,
                          itemBuilder: (context, index) {
                            final order = _orders[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          order['order_number'],
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Color(
                                              int.parse(
                                                '0xFF${_getStatusColor(order['status']).substring(1)}',
                                              ),
                                            ).withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            _getStatusLabel(order['status']),
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: Color(
                                                int.parse(
                                                  '0xFF${_getStatusColor(order['status']).substring(1)}',
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text('Client: ${order['customer_name']}'),
                                    Text('Articles: ${order['items_count']}'),
                                    Text('Total: ${order['total_amount']} FCFA'),
                                    Text('Date: ${order['created_at']}'),
                                    const SizedBox(height: 12),
                                    // Bouton mise à jour statut
                                    Row(
                                      children: [
                                        if (order['status'] != 'delivered' &&
                                            order['status'] != 'cancelled')
                                          Expanded(
                                            child: OutlinedButton(
                                              onPressed: () {
                                                _showStatusDialog(
                                                  order['order_number'],
                                                  order['status'],
                                                );
                                              },
                                              style: OutlinedButton.styleFrom(
                                                side: BorderSide(color: AppColors.primary),
                                              ),
                                              child: const Text('Mettre à jour'),
                                            ),
                                          ),
                                        const SizedBox(width: 8),
                                        IconButton(
                                          icon: const Icon(Icons.support_agent, color: AppColors.primary),
                                          tooltip: 'Contacter Admin',
                                          onPressed: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) => AdminOrderChatPage(
                                                  orderId: order['id'] ?? 0,
                                                  chatType: 'admin_shop',
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }

  void _showStatusDialog(String orderId, String currentStatus) {
    final List<Map<String, String>> statusOptions = [
      {'value': 'confirmed', 'label': 'Confirmer la commande'},
      {'value': 'preparing', 'label': 'Commencer la préparation'},
      {'value': 'ready', 'label': 'Marquer comme prête'},
      {'value': 'in_delivery', 'label': 'Envoyer en livraison'},
      {'value': 'delivered', 'label': 'Marquer comme livrée'},
      {'value': 'cancelled', 'label': 'Annuler la commande'},
    ];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Mettre à jour le statut'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: statusOptions.map((option) {
            return ListTile(
              title: Text(option['label']!),
              onTap: () {
                Navigator.pop(context);
                _updateOrderStatus(orderId, option['value']!);
              },
            );
          }).toList(),
        ),
      ),
    );
  }
}
