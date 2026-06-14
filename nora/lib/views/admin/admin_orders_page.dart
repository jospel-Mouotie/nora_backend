import 'package:flutter/material.dart';
import '../../../config/app_colors.dart';
import '../../../services/order_api_service.dart';
import '../../../services/storage_service.dart';
import 'admin_order_chat_page.dart';

class AdminOrdersPage extends StatefulWidget {
  const AdminOrdersPage({super.key});

  @override
  State<AdminOrdersPage> createState() => _AdminOrdersPageState();
}

class _AdminOrdersPageState extends State<AdminOrdersPage> {
  final OrderApiService _orderApiService = OrderApiService();
  List<dynamic> _orders = [];
  bool _isLoading = true;
  String _filterStatus = 'all';

  final List<Map<String, String>> _statusFilters = [
    {'value': 'all', 'label': 'Toutes'},
    {'value': 'pending_admin', 'label': 'A valider'},
    {'value': 'pending', 'label': 'En attente (Boutique)'},
    {'value': 'confirmed', 'label': 'Confirmées'},
    {'value': 'preparing', 'label': 'En préparation'},
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
      // Utiliser l'endpoint admin pour récupérer les commandes en attente
      final result = await _orderApiService.getPendingOrders(token: token);
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
        {'id': 1, 'order_number': 'ORD-001', 'customer_name': 'Jean Dupont', 'shop_name': 'Fashion Store', 'total_amount': 32000, 'status': 'pending', 'created_at': '2026-05-16'},
        {'id': 2, 'order_number': 'ORD-002', 'customer_name': 'Marie Laurent', 'shop_name': 'Tech Hub', 'total_amount': 45000, 'status': 'in_delivery', 'created_at': '2026-05-16'},
        {'id': 3, 'order_number': 'ORD-003', 'customer_name': 'Paul Martin', 'shop_name': 'Beauty Corner', 'total_amount': 12800, 'status': 'delivered', 'created_at': '2026-05-15'},
      ];
      _isLoading = false;
    });
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

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending': return AppColors.warning;
      case 'pending_admin': return Colors.purple;
      case 'confirmed': return AppColors.info;
      case 'preparing': return AppColors.info;
      case 'ready': return AppColors.info;
      case 'in_delivery': return AppColors.primary;
      case 'delivered': return AppColors.success;
      case 'cancelled': return AppColors.error;
      default: return AppColors.textSecondary;
    }
  }

  void _openChat(int orderId, String chatType) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AdminOrderChatPage(
          orderId: orderId,
          chatType: chatType,
        ),
      ),
    );
  }

  Future<void> _sendToShop(String orderId) async {
    final token = await StorageService().getToken();
    if (token == null) return;
    
    showDialog(
      context: context, 
      barrierDismissible: false, 
      builder: (_) => const Center(child: CircularProgressIndicator())
    );
    
    final result = await _orderApiService.sendToShop(orderId, token);
    
    if (mounted) Navigator.pop(context); // fermer loading
    
    if (result['success']) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Commande envoyée à la boutique'), backgroundColor: AppColors.success));
        _loadOrders();
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result['message']), backgroundColor: AppColors.error));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredOrders = _orders.where((order) {
      if (_filterStatus != 'all' && order['status'] != _filterStatus) return false;
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text('Commandes', style: TextStyle(color: AppColors.textPrimary)),
      ),
      body: Column(
        children: [
          Container(
            height: 50,
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: _statusFilters.map((filter) {
                final isSelected = _filterStatus == filter['value'];
                return GestureDetector(
                  onTap: () => setState(() => _filterStatus = filter['value']!),
                  child: Container(
                    margin: const EdgeInsets.only(right: 12),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primary : AppColors.backgroundLight,
                      border: Border.all(color: isSelected ? AppColors.primary : AppColors.border),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Text(filter['label']!, style: TextStyle(color: isSelected ? Colors.white : AppColors.textSecondary)),
                  ),
                );
              }).toList(),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : filteredOrders.isEmpty
                    ? const Center(child: Text('Aucune commande trouvée'))
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: filteredOrders.length,
                        itemBuilder: (context, index) {
                          final order = filteredOrders[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ExpansionTile(
                              title: Text(order['order_number'], style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Client: ${order['customer_name'] ?? (order['user'] != null ? order['user']['name'] : 'Inconnu')}'),
                                  Text('Boutique: ${order['shop_name'] ?? (order['shop'] != null ? order['shop']['name'] : 'Inconnu')}'),
                                  Text('Montant: ${order['total_amount']} FCFA'),
                                  Text('Date: ${order['created_at']}'),
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: _getStatusColor(order['status']).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(_getStatusLabel(order['status']), style: TextStyle(color: _getStatusColor(order['status']), fontSize: 11)),
                                  ),
                                ],
                              ),
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                    children: [
                                      if (order['status'] == 'pending_admin')
                                        ElevatedButton.icon(
                                          onPressed: () => _sendToShop(order['id'].toString()),
                                          icon: const Icon(Icons.send, size: 16),
                                          label: const Text('Envoyer Boutique'),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: AppColors.primary,
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(horizontal: 12),
                                          ),
                                        ),
                                      IconButton(
                                        icon: const Icon(Icons.person, color: AppColors.info),
                                        tooltip: 'Chat Client',
                                        onPressed: () => _openChat(order['id'], 'admin_client'),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.storefront, color: AppColors.warning),
                                        tooltip: 'Chat Boutique',
                                        onPressed: () => _openChat(order['id'], 'admin_shop'),
                                      ),
                                    ],
                                  ),
                                )
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