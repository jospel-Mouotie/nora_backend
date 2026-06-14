import 'package:flutter/material.dart';
import '../../../config/app_colors.dart';
import '../../../services/shop_api_service.dart';
import '../../../services/storage_service.dart';

class AdminValidationsPage extends StatefulWidget {
  const AdminValidationsPage({super.key});

  @override
  State<AdminValidationsPage> createState() => _AdminValidationsPageState();
}

class _AdminValidationsPageState extends State<AdminValidationsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ShopApiService _shopApiService = ShopApiService();

  List<dynamic> _pendingShops = [];
  List<dynamic> _pendingCertifications = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadPendingData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadPendingData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final token = await StorageService().getToken();
    if (token == null) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Veuillez vous connecter';
      });
      return;
    }

    try {
      await Future.wait([
        _loadPendingShops(token),
        _loadPendingCertifications(token),
      ]);
    } catch (e) {
      setState(() => _errorMessage = 'Erreur de chargement');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadPendingShops(String token) async {
    try {
      final result = await _shopApiService.getPendingShops(token);
      if (result['success'] && result['shops'] != null) {
        setState(() => _pendingShops = result['shops']);
      }
    } catch (e) {
      print('Erreur chargement boutiques: $e');
    }
  }

  Future<void> _loadPendingCertifications(String token) async {
    try {
      final result = await _shopApiService.getPendingCertifications(token);
      if (result['success'] && result['requests'] != null) {
        final requests = result['requests'];
        setState(() => _pendingCertifications = requests is List ? requests : (requests['data'] ?? []));
      }
    } catch (e) {
      print('Erreur chargement certifications: $e');
    }
  }

  Future<bool> _showConfirmDialog({
    required String title,
    required String message,
    required String confirmText,
    Color? confirmColor,
  }) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: confirmColor ?? AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text(confirmText),
          ),
        ],
      ),
    ) ?? false;
  }

  Future<void> _approveShop(int shopId, String shopName) async {
    final confirm = await _showConfirmDialog(
      title: 'Approuver la boutique',
      message: 'Voulez-vous vraiment approuver la boutique "$shopName" ? Elle sera visible par tous les clients.',
      confirmText: 'Approuver',
      confirmColor: AppColors.success,
    );
    if (!confirm) return;

    final token = await StorageService().getToken();
    if (token == null) return;
    setState(() => _isLoading = true);
    try {
      final result = await _shopApiService.approveShop(shopId, token);
      _showSnackBar(result['message'] ?? 'Boutique approuvée', isSuccess: result['success']);
      if (result['success']) await _loadPendingShops(token);
    } catch (e) {
      _showSnackBar('Erreur de connexion');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _rejectShop(int shopId, String shopName) async {
    final confirm = await _showConfirmDialog(
      title: 'Rejeter la boutique',
      message: 'Voulez-vous vraiment rejeter la boutique "$shopName" ?',
      confirmText: 'Rejeter',
      confirmColor: AppColors.error,
    );
    if (!confirm) return;

    final token = await StorageService().getToken();
    if (token == null) return;
    setState(() => _isLoading = true);
    try {
      final result = await _shopApiService.rejectShop(shopId, token);
      _showSnackBar(result['message'] ?? 'Boutique rejetée', isSuccess: result['success']);
      if (result['success']) await _loadPendingShops(token);
    } catch (e) {
      _showSnackBar('Erreur de connexion');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _approveCertification(int requestId, String shopName) async {
    final confirm = await _showConfirmDialog(
      title: 'Certifier la boutique',
      message: 'Voulez-vous vraiment certifier la boutique "$shopName" ? Un badge de confiance lui sera accordé.',
      confirmText: 'Certifier',
      confirmColor: AppColors.primary,
    );
    if (!confirm) return;

    final token = await StorageService().getToken();
    if (token == null) return;
    setState(() => _isLoading = true);
    try {
      final result = await _shopApiService.approveCertification(requestId, token);
      _showSnackBar(result['message'] ?? 'Certification approuvée', isSuccess: result['success']);
      if (result['success']) await _loadPendingCertifications(token);
    } catch (e) {
      _showSnackBar('Erreur de connexion');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _rejectCertification(int requestId, String shopName) async {
    final confirm = await _showConfirmDialog(
      title: 'Rejeter la demande',
      message: 'Voulez-vous vraiment rejeter la demande de certification de la boutique "$shopName" ?',
      confirmText: 'Rejeter',
      confirmColor: AppColors.error,
    );
    if (!confirm) return;

    final token = await StorageService().getToken();
    if (token == null) return;
    setState(() => _isLoading = true);
    try {
      final result = await _shopApiService.rejectCertification(requestId, token);
      _showSnackBar(result['message'] ?? 'Demande rejetée', isSuccess: result['success']);
      if (result['success']) await _loadPendingCertifications(token);
    } catch (e) {
      _showSnackBar('Erreur de connexion');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message, {bool isSuccess = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(isSuccess ? Icons.check_circle : Icons.error, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: isSuccess ? AppColors.success : AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Validations',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadPendingData,
            tooltip: 'Rafraîchir',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          tabs: [
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.store, size: 16),
                  const SizedBox(width: 6),
                  Text('Boutiques (${_pendingShops.length})'),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.verified, size: 16),
                  const SizedBox(width: 6),
                  Text('Certif. (${_pendingCertifications.length})'),
                ],
              ),
            ),
            const Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.video_library, size: 16),
                  SizedBox(width: 6),
                  Text('Stories'),
                ],
              ),
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _errorMessage != null
              ? _buildErrorView()
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildShopsList(),
                    _buildCertificationsList(),
                    _buildStoriesList(),
                  ],
                ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.error.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.error_outline, size: 48, color: AppColors.error),
          ),
          const SizedBox(height: 16),
          Text(_errorMessage!, style: const TextStyle(color: AppColors.textSecondary, fontSize: 16)),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _loadPendingData,
            icon: const Icon(Icons.refresh),
            label: const Text('Réessayer'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState({required IconData icon, required String title, required String subtitle}) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 56, color: AppColors.primary.withOpacity(0.5)),
          ),
          const SizedBox(height: 20),
          Text(title, style: const TextStyle(color: AppColors.textSecondary, fontSize: 17, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text(subtitle, style: TextStyle(color: AppColors.textTertiary, fontSize: 13)),
        ],
      ),
    );
  }

  // ========== BOUTIQUES LIST ==========

  Widget _buildShopsList() {
    if (_pendingShops.isEmpty) {
      return _buildEmptyState(
        icon: Icons.store_outlined,
        title: 'Aucune boutique en attente',
        subtitle: 'Les nouvelles boutiques apparaîtront ici',
      );
    }

    return RefreshIndicator(
      onRefresh: _loadPendingData,
      color: AppColors.primary,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _pendingShops.length,
        itemBuilder: (context, index) => _buildShopCard(_pendingShops[index]),
      ),
    );
  }

  Widget _buildShopCard(Map<String, dynamic> shop) {
    final user = shop['user'] ?? {};
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 16, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.orange.withOpacity(0.15), Colors.orange.withOpacity(0.05)],
              ),
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: Colors.orange, borderRadius: BorderRadius.circular(20)),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.schedule, size: 12, color: Colors.white),
                      SizedBox(width: 4),
                      Text('En attente', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
                const Spacer(),
                Text(_formatDate(shop['created_at']), style: TextStyle(fontSize: 12, color: AppColors.textTertiary)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 50, height: 50,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [AppColors.primary, AppColors.primaryLight]),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.store, color: Colors.white, size: 26),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(shop['name'] ?? 'Sans nom', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                          const SizedBox(height: 2),
                          Text(user['name'] ?? 'Propriétaire', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Divider(color: AppColors.border, height: 1),
                const SizedBox(height: 12),
                if (user['email'] != null) _buildInfoChip(Icons.email, user['email']),
                if (shop['phone'] != null) _buildInfoChip(Icons.phone, shop['phone']),
                if (shop['address'] != null) _buildInfoChip(Icons.location_on, shop['address']),
                if (shop['description'] != null && shop['description'].toString().isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      shop['description'],
                      style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                      maxLines: 2, overflow: TextOverflow.ellipsis,
                    ),
                  ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _approveShop(shop['id'], shop['name'] ?? ''),
                        icon: const Icon(Icons.check_circle, size: 18),
                        label: const Text('Approuver'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.success,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _rejectShop(shop['id'], shop['name'] ?? ''),
                        icon: const Icon(Icons.cancel, size: 18),
                        label: const Text('Rejeter'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.error,
                          side: const BorderSide(color: AppColors.error),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ========== CERTIFICATIONS LIST ==========

  Widget _buildCertificationsList() {
    if (_pendingCertifications.isEmpty) {
      return _buildEmptyState(
        icon: Icons.verified_outlined,
        title: 'Aucune demande de certification',
        subtitle: 'Les demandes de certification apparaîtront ici',
      );
    }

    return RefreshIndicator(
      onRefresh: _loadPendingData,
      color: AppColors.primary,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _pendingCertifications.length,
        itemBuilder: (context, index) => _buildCertificationCard(_pendingCertifications[index]),
      ),
    );
  }

  Widget _buildCertificationCard(Map<String, dynamic> request) {
    final shop = request['shop'] ?? {};
    final user = shop['user'] ?? {};
    final status = request['status'] ?? 'pending';
    final isPaid = status == 'paid';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 16, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isPaid
                    ? [AppColors.primary.withOpacity(0.15), AppColors.primary.withOpacity(0.05)]
                    : [Colors.orange.withOpacity(0.15), Colors.orange.withOpacity(0.05)],
              ),
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isPaid ? AppColors.primary : Colors.orange,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(isPaid ? Icons.payment : Icons.schedule, size: 12, color: Colors.white),
                      const SizedBox(width: 4),
                      Text(
                        isPaid ? 'Payée' : 'En attente de paiement',
                        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Text(_formatDate(request['created_at']), style: TextStyle(fontSize: 12, color: AppColors.textTertiary)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 50, height: 50,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [AppColors.accent, Colors.orange.shade300]),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.verified, color: Colors.white, size: 26),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(shop['name'] ?? 'Boutique', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                          const SizedBox(height: 2),
                          Text(user['name'] ?? 'Propriétaire', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                        ],
                      ),
                    ),
                  ],
                ),
                if (request['payment_method'] != null) ...[
                  const SizedBox(height: 12),
                  Divider(color: AppColors.border, height: 1),
                  const SizedBox(height: 10),
                  _buildInfoChip(Icons.payment, 'Paiement: ${request['payment_method']}'),
                  if (request['transaction_id'] != null)
                    _buildInfoChip(Icons.receipt, 'Transaction: ${request['transaction_id']}'),
                ],
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _approveCertification(request['id'], shop['name'] ?? ''),
                        icon: const Icon(Icons.verified, size: 18),
                        label: const Text('Certifier'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: Colors.grey.shade300,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _rejectCertification(request['id'], shop['name'] ?? ''),
                        icon: const Icon(Icons.cancel, size: 18),
                        label: const Text('Rejeter'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.error,
                          side: const BorderSide(color: AppColors.error),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ========== STORIES LIST ==========

  Widget _buildStoriesList() {
    return _buildEmptyState(
      icon: Icons.video_library_outlined,
      title: 'Aucune story en attente',
      subtitle: 'Fonctionnalité à venir',
    );
  }

  // ========== HELPERS ==========

  Widget _buildInfoChip(IconData icon, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.textSecondary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(value, style: TextStyle(fontSize: 13, color: AppColors.textPrimary), maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '';
    try {
      final date = DateTime.parse(dateStr);
      final now = DateTime.now();
      final diff = now.difference(date);
      if (diff.inDays > 7) return 'il y a ${diff.inDays ~/ 7} sem.';
      if (diff.inDays > 0) return 'il y a ${diff.inDays} j.';
      if (diff.inHours > 0) return 'il y a ${diff.inHours} h.';
      if (diff.inMinutes > 0) return 'il y a ${diff.inMinutes} min.';
      return 'à l\'instant';
    } catch (e) {
      return dateStr;
    }
  }
}
