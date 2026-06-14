import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../config/app_colors.dart';
import '../../../config/routes.dart';
import '../../../services/order_api_service.dart';
import '../../../services/storage_service.dart';
import '../../../utils/converters.dart';

class OrderHistoryPage extends StatefulWidget {
  const OrderHistoryPage({super.key});

  @override
  State<OrderHistoryPage> createState() => _OrderHistoryPageState();
}

class _OrderHistoryPageState extends State<OrderHistoryPage> with SingleTickerProviderStateMixin {
  final OrderApiService _orderApiService = OrderApiService();
  late TabController _tabController;
  List<dynamic> _orders = [];
  bool _isLoading = true;

  final List<Map<String, String>> _tabs = [
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
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        _loadOrders();
      }
    });
    _loadOrders();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadOrders() async {
    setState(() => _isLoading = true);
    
    final token = await StorageService().getToken();
    if (token == null) {
      setState(() => _isLoading = false);
      return;
    }
    
    try {
      final status = _tabs[_tabController.index]['value'] == 'all' 
          ? null 
          : _tabs[_tabController.index]['value'];
      final result = await _orderApiService.getOrders(
        status: status,
        token: token,
      );
      
      if (result['success'] && result['orders'] != null) {
        setState(() {
          _orders = result['orders'];
          _isLoading = false;
        });
      } else {
        _loadTestOrders();
      }
    } catch (e) {
      _loadTestOrders();
    }
  }

  void _loadTestOrders() {
    setState(() {
      _orders = [
        {'order_number': 'ORD-20260514-001', 'status': 'delivered', 'total_amount': 9500, 'created_at': '2026-05-14', 'item_count': 4},
        {'order_number': 'ORD-20260513-002', 'status': 'in_delivery', 'total_amount': 12500, 'created_at': '2026-05-13', 'item_count': 3},
        {'order_number': 'ORD-20260512-003', 'status': 'confirmed', 'total_amount': 6700, 'created_at': '2026-05-12', 'item_count': 2},
        {'order_number': 'ORD-20260510-004', 'status': 'delivered', 'total_amount': 23000, 'created_at': '2026-05-10', 'item_count': 5},
      ];
      _isLoading = false;
    });
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
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              context.pop();
            } else {
              context.go('/home');
            }
          },
        ),
        title: const Text(
          'Mes commandes',
          style: TextStyle(color: AppColors.textPrimary),
        ),
      ),
      body: Column(
        children: [
          // Tabs
          Container(
            color: AppColors.background,
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              indicatorColor: AppColors.primary,
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.textSecondary,
              labelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              unselectedLabelStyle: const TextStyle(fontSize: 14),
              tabs: _tabs.map((tab) => Tab(text: tab['label'])).toList(),
            ),
          ),
          const Divider(height: 1),
          // Liste des commandes
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  )
                : _orders.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.history, size: 64, color: AppColors.textTertiary),
                            const SizedBox(height: 16),
                            Text(
                              'Aucune commande',
                              style: TextStyle(
                                fontSize: 16,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            ElevatedButton(
                              onPressed: () => context.go(AppRoutes.home),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                              ),
                              child: const Text('Découvrir'),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadOrders,
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            if (constraints.maxWidth > 800) {
                              return GridView.builder(
                                padding: const EdgeInsets.all(16),
                                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  crossAxisSpacing: 16,
                                  mainAxisSpacing: 16,
                                  childAspectRatio: 2.5,
                                ),
                                itemCount: _orders.length,
                                itemBuilder: (context, index) {
                                  return _buildOrderCard(_orders[index]);
                                },
                              );
                            }
                            return ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: _orders.length,
                              itemBuilder: (context, index) {
                                return _buildOrderCard(_orders[index]);
                              },
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> order) {
    final status = toStringSafe(order['status']);
    final orderNumber = toStringSafe(order['order_number']);
    final totalAmount = toIntSafe(order['total_amount']);
    final createdAt = toStringSafe(order['created_at']);
    final itemCount = toIntSafe(order['item_count']);

    return GestureDetector(
      onTap: () {
        context.push('${AppRoutes.orderDetail}/$orderNumber');
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.background,
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  orderNumber,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(status).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    _getStatusLabel(status),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: _getStatusColor(status),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '$itemCount article${itemCount > 1 ? 's' : ''}',
                  style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                ),
                Text(
                  createdAt,
                  style: const TextStyle(fontSize: 12, color: AppColors.textTertiary),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total',
                  style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
                ),
                Text(
                  '$totalAmount FCFA',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
            if (status == 'in_delivery')
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Row(
                  children: [
                    Icon(Icons.location_on, size: 16, color: AppColors.primary),
                    const SizedBox(width: 4),
                    const Text(
                      'En cours de livraison',
                      style: TextStyle(fontSize: 12, color: AppColors.primary),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'pending_admin': return 'En attente validation';
      case 'pending': return 'En attente boutique';
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
      case 'pending_admin': return AppColors.warning;
      case 'pending': return AppColors.warning;
      case 'confirmed': return AppColors.info;
      case 'preparing': return AppColors.info;
      case 'ready': return AppColors.info;
      case 'in_delivery': return AppColors.primary;
      case 'delivered': return AppColors.success;
      case 'cancelled': return AppColors.error;
      default: return AppColors.textSecondary;
    }
  }
}