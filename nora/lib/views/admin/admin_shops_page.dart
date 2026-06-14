import 'package:flutter/material.dart';
import '../../../config/app_colors.dart';
import '../../../models/shop_model.dart';
import '../../../providers/shop_provider.dart';
import 'package:provider/provider.dart';

class AdminShopsPage extends StatefulWidget {
  const AdminShopsPage({super.key});

  @override
  State<AdminShopsPage> createState() => _AdminShopsPageState();
}

class _AdminShopsPageState extends State<AdminShopsPage> {
  String _searchQuery = '';
  String _filterStatus = 'all';

  final List<Map<String, String>> _statusFilters = [
    {'value': 'all', 'label': 'Toutes'},
    {'value': 'active', 'label': 'Actives'},
    {'value': 'en_attente', 'label': 'En attente'},
    {'value': 'refusee', 'label': 'Refusées'},
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ShopProvider>().loadPendingShops();
    });
  }

  Future<void> _validateShop(int shopId, bool approve) async {
    final shopProvider = context.read<ShopProvider>();
    final success = approve 
        ? await shopProvider.approveShop(shopId)
        : await shopProvider.rejectShop(shopId);
    
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(approve ? 'Boutique approuvée' : 'Boutique rejetée'),
          backgroundColor: approve ? AppColors.success : AppColors.error,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(shopProvider.errorMessage ?? 'Erreur'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'active': return 'Active';
      case 'en_attente': return 'En attente';
      case 'refusee': return 'Refusée';
      default: return status;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'active': return AppColors.success;
      case 'en_attente': return AppColors.warning;
      case 'refusee': return AppColors.error;
      default: return AppColors.textSecondary;
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
          'Validation des boutiques',
          style: TextStyle(color: AppColors.textPrimary),
        ),
      ),
      body: Column(
        children: [
          // Barre de recherche
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Rechercher une boutique...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                filled: true,
                fillColor: AppColors.backgroundLight,
              ),
              onChanged: (value) {
                setState(() => _searchQuery = value);
              },
            ),
          ),
          
          // Filtres par statut
          Container(
            height: 50,
            margin: const EdgeInsets.symmetric(horizontal: 16),
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: _statusFilters.map((filter) {
                final isSelected = _filterStatus == filter['value'];
                return GestureDetector(
                  onTap: () {
                    setState(() => _filterStatus = filter['value']!);
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
          
          // Liste des boutiques
          Expanded(
            child: Consumer<ShopProvider>(
              builder: (context, shopProvider, child) {
                final shops = shopProvider.pendingShops;
                
                final filteredShops = shops.where((shop) {
                  if (_filterStatus != 'all' && shop.status != _filterStatus) return false;
                  if (_searchQuery.isNotEmpty) {
                    final name = shop.name.toLowerCase();
                    final query = _searchQuery.toLowerCase();
                    if (!name.contains(query)) return false;
                  }
                  return true;
                }).toList();

                if (shopProvider.isLoading) {
                  return const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  );
                }

                if (filteredShops.isEmpty) {
                  return const Center(
                    child: Text('Aucune boutique trouvée'),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredShops.length,
                  itemBuilder: (context, index) {
                    final shop = filteredShops[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  shop.name,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: _getStatusColor(shop.status).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  _getStatusLabel(shop.status),
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: _getStatusColor(shop.status),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          if (shop.description != null)
                            Text('Description: ${shop.description}'),
                          if (shop.address != null)
                            Text('Adresse: ${shop.address}'),
                          if (shop.phone != null)
                            Text('Téléphone: ${shop.phone}'),
                          if (shop.email != null)
                            Text('Email: ${shop.email}'),
                          if (shop.certifiedAt != null)
                            Text('Certifiée le: ${shop.certifiedAt}'),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              if (shop.status == 'en_attente')
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: () => _validateShop(shop.id, true),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.success,
                                    ),
                                    child: const Text('Approuver'),
                                  ),
                                ),
                              if (shop.status == 'en_attente')
                                const SizedBox(width: 8),
                              if (shop.status == 'en_attente')
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: () => _validateShop(shop.id, false),
                                    style: OutlinedButton.styleFrom(
                                      side: BorderSide(color: AppColors.error),
                                      foregroundColor: AppColors.error,
                                    ),
                                    child: const Text('Rejeter'),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}