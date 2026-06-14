import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../config/app_colors.dart';
import '../../../config/routes.dart';
import '../../../services/order_api_service.dart';
import '../../../services/storage_service.dart';
import '../../../widgets/orders/order_status_timeline.dart';

class OrderDetailPage extends StatefulWidget {
  final String orderId;

  const OrderDetailPage({super.key, required this.orderId});

  @override
  State<OrderDetailPage> createState() => _OrderDetailPageState();
}

class _OrderDetailPageState extends State<OrderDetailPage> {
  final OrderApiService _orderApiService = OrderApiService();
  Map<String, dynamic>? _order;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadOrder();
  }

  Future<void> _loadOrder() async {
    setState(() => _isLoading = true);
    
    final token = await StorageService().getToken();
    if (token == null) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Non authentifié';
      });
      return;
    }
    
    try {
      final result = await _orderApiService.getOrder(widget.orderId, token);
      if (result['success'] && result['order'] != null) {
        setState(() {
          _order = result['order'];
          _isLoading = false;
          _errorMessage = null;
        });
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = result['message'] ?? 'Erreur lors du chargement';
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Erreur de connexion';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          elevation: 0,
          title: const Text('Détails commande', style: TextStyle(color: AppColors.textPrimary)),
        ),
        body: const Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    if (_errorMessage != null || _order == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          elevation: 0,
          title: const Text('Détails commande', style: TextStyle(color: AppColors.textPrimary)),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(_errorMessage ?? 'Commande non trouvée', style: const TextStyle(color: AppColors.error)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadOrder,
                child: const Text('Réessayer'),
              ),
            ],
          ),
        ),
      );
    }

    final order = _order!;
    final String orderNumber = order['order_number'] ?? widget.orderId;
    final String orderStatus = order['status'] ?? 'pending';
    final String createdAt = order['created_at'] ?? '';
    final int totalAmount = (order['total_amount'] ?? 0).toInt();
    final int deliveryFee = (order['delivery_fee'] ?? 0).toInt();
    final String deliveryAddress = order['delivery_address'] ?? '';
    final List<dynamic> items = order['items'] ?? [];
    final Map<String, dynamic>? delivery = order['delivery'];
    
    // Construire la timeline basée sur le statut
    final List<Map<String, dynamic>> timeline = _buildTimeline(orderStatus);

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
          'Détails commande',
          style: TextStyle(color: AppColors.textPrimary),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.backgroundLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'N° $orderNumber',
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _getStatusLabel(orderStatus),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: _getStatusColor(orderStatus),
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _getStatusColor(orderStatus).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      createdAt,
                      style: TextStyle(
                        fontSize: 12,
                        color: _getStatusColor(orderStatus),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // QR Code de la commande
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.backgroundLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  const Text(
                    '📱 Code QR de la commande',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: QrImageView(
                      data: orderNumber,
                      version: QrVersions.auto,
                      size: 150.0,
                      backgroundColor: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Scannez ce code pour vérifier la commande',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Timeline
            OrderStatusTimeline(timeline: timeline),
            
            const SizedBox(height: 24),
            
            // Livreur (si en livraison)
            if (orderStatus == 'in_delivery' && delivery != null)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.backgroundLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '🚚 Livreur assigné',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(25),
                          ),
                          child: const Icon(Icons.person, color: Colors.white, size: 28),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                delivery['driver_name'] ?? 'Livreur',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                delivery['driver_phone'] ?? '',
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            // TODO: Ouvrir chat
                          },
                          icon: const Icon(Icons.chat_outlined, color: AppColors.primary),
                        ),
                        IconButton(
                          onPressed: () {
                            // TODO: Appeler
                          },
                          icon: const Icon(Icons.phone, color: AppColors.primary),
                        ),
                      ],
                    ),
                    if (delivery['estimated_time'] != null) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.schedule, size: 20, color: AppColors.primary),
                            const SizedBox(width: 8),
                            Text(
                              'Livraison estimée: ${delivery['estimated_time']}',
                              style: const TextStyle(fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            
            const SizedBox(height: 24),
            
            // Articles
            const Text(
              'Articles commandés',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            ...items.map((item) => _buildOrderItem(Map<String, dynamic>.from(item as Map))),
            
            const SizedBox(height: 24),
            
            // Résumé
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.backgroundLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  _buildSummaryRow('Sous-total', totalAmount - deliveryFee),
                  const SizedBox(height: 8),
                  _buildSummaryRow('Frais de livraison', deliveryFee),
                  const Divider(height: 16),
                  _buildSummaryRow('Total', totalAmount, isTotal: true),
                ],
              ),
            ),
            
            const SizedBox(height: 24),

            // Action: Contacter l'admin
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primary.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Besoin d\'aide avec votre commande ?',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryDark,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Notre équipe est là pour vous assister à tout moment.',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        // L'id 1 est souvent l'admin principal ou un service client générique
                        context.push('${AppRoutes.chatAdminConversation}/1');
                      },
                      icon: const Icon(Icons.support_agent),
                      label: const Text('Contacter le support'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Adresse de livraison
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.backgroundLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '📍 Adresse de livraison',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    deliveryAddress,
                    style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Bouton suivre la livraison (si en cours)
            if (orderStatus == 'in_delivery')
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    context.push('${AppRoutes.orderTracking}/delivery_123');
                  },
                  icon: const Icon(Icons.location_on),
                  label: const Text('Suivre ma livraison en direct'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderItem(Map<String, dynamic> item) {
    // Adapter à la structure de l'API: item contient productVariant qui contient product
    final productVariant = item['product_variant'];
    final product = productVariant != null ? productVariant['product'] : null;
    
    final String name = product != null ? product['name'] : 'Produit inconnu';
    final int price = (item['unit_price'] ?? 0).toInt();
    final int quantity = (item['quantity'] ?? 0).toInt();
    final int total = (item['total_price'] ?? 0).toInt();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.background,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: AppColors.backgroundLight,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.image, color: AppColors.textTertiary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$price FCFA x $quantity',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '$total FCFA',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _buildTimeline(String status) {
    // Construire la timeline basée sur le statut actuel
    final timeline = <Map<String, dynamic>>[];
    
    final statuses = [
      {'status': 'pending_admin', 'label': 'En attente admin'},
      {'status': 'pending', 'label': 'En attente boutique'},
      {'status': 'confirmed', 'label': 'Confirmée'},
      {'status': 'preparing', 'label': 'En préparation'},
      {'status': 'ready', 'label': 'Prête'},
      {'status': 'in_delivery', 'label': 'En livraison'},
      {'status': 'delivered', 'label': 'Livrée'},
    ];

    bool foundCurrentStatus = false;
    for (var s in statuses) {
      final isCompleted = statuses.indexOf(s) < statuses.indexWhere((st) => st['status'] == status);
      final isCurrent = s['status'] == status;
      
      timeline.add({
        'status': s['status'],
        'label': s['label'],
        'date': isCurrent ? 'En cours' : '',
        'completed': isCompleted || isCurrent,
      });
      
      if (isCurrent) foundCurrentStatus = true;
    }
    
    return timeline;
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
          '$amount FCFA',
          style: TextStyle(
            fontSize: isTotal ? 18 : 14,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            color: isTotal ? AppColors.primary : AppColors.textPrimary,
          ),
        ),
      ],
    );
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