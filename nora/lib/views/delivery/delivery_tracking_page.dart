import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../config/app_colors.dart';
import '../../../config/routes.dart';
import '../../../services/delivery_api_service.dart';
import '../../../services/location_service.dart';
import '../../../services/storage_service.dart';
import '../../../widgets/delivery/delivery_map.dart';
import '../../../widgets/delivery/driver_info_card.dart';
import '../../../utils/converters.dart';

class DeliveryTrackingPage extends StatefulWidget {
  final int deliveryId;

  const DeliveryTrackingPage({super.key, required this.deliveryId});

  @override
  State<DeliveryTrackingPage> createState() => _DeliveryTrackingPageState();
}

class _DeliveryTrackingPageState extends State<DeliveryTrackingPage> {
  final DeliveryApiService _deliveryApiService = DeliveryApiService();

  Map<String, dynamic>? _delivery;
  bool _isLoading = true;
  String? _errorMessage;
  String? _userRole; // 'client' ou 'livreur'

  Timer? _refreshTimer;
  Timer? _locationUpdateTimer;

  @override
  void initState() {
    super.initState();
    _loadUserRole();
    _loadDelivery();
    _startRefreshTimer();
  }

  Future<void> _loadUserRole() async {
    final token = await StorageService().getToken();
    if (token != null) {
      // TODO: Récupérer le rôle depuis le token ou l'API
      _userRole = 'client'; // À remplacer par la vraie valeur
    }
  }

  Future<void> _loadDelivery() async {
    setState(() => _isLoading = true);

    final token = await StorageService().getToken();
    if (token == null) {
      setState(() {
        _errorMessage = 'Veuillez vous connecter pour suivre votre livraison';
        _isLoading = false;
      });
      return;
    }

    try {
      final result = await _deliveryApiService.getDelivery(
        widget.deliveryId.toString(),
        token,
      );

      if (result['success'] && result['delivery'] != null) {
        setState(() {
          _delivery = result['delivery'];
          _isLoading = false;
        });

        // Démarrer les mises à jour selon le rôle
        if (_userRole == 'livreur') {
          _startSendingLocation(); // Livreur envoie sa position
        } else {
          _startReceivingLocation(); // Client reçoit la position
        }
      } else {
        _errorMessage = result['message'] ?? 'Livraison non trouvée';
        setState(() => _isLoading = false);
      }
    } catch (e) {
      print('Erreur chargement livraison: $e');
      _errorMessage = 'Erreur de connexion au serveur';
      setState(() => _isLoading = false);
    }
  }

  void _startRefreshTimer() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _loadDelivery();
    });
  }

  // ✅ Pour le CLIENT : récupérer la position du livreur depuis l'API
  void _startReceivingLocation() {
    _locationUpdateTimer?.cancel();
    _locationUpdateTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      _fetchDriverLocation();
    });
  }

  Future<void> _fetchDriverLocation() async {
    final token = await StorageService().getToken();
    if (token == null || _delivery == null) return;

    try {
      // Appel API: GET /api/deliveries/{id}/location
      final result = await _deliveryApiService.getDeliveryLocation(
        widget.deliveryId.toString(),
        token,
      );

      if (result['success'] && mounted) {
        setState(() {
          _delivery!['driver_lat'] = result['latitude'];
          _delivery!['driver_lng'] = result['longitude'];

          // Calculer la distance restante
          if (_delivery!['delivery_lat'] != null && _delivery!['delivery_lng'] != null) {
            double distance = LocationService.calculateDistance(
              result['latitude']?.toDouble() ?? 0,
              result['longitude']?.toDouble() ?? 0,
              _delivery!['delivery_lat'].toDouble(),
              _delivery!['delivery_lng'].toDouble(),
            );
            _delivery!['distance'] = LocationService.formatDistance(distance);

            // Vérifier si le livreur est arrivé (moins de 50m)
            if (distance < 50 && _delivery!['status'] != 'delivered') {
              _delivery!['status'] = 'delivered';
              _locationUpdateTimer?.cancel();
              _loadDelivery();
            }
          }
        });
      }
    } catch (e) {
      print('Erreur récupération position: $e');
    }
  }

  // ✅ Pour le LIVREUR : envoyer sa position à l'API
  void _startSendingLocation() {
    _locationUpdateTimer?.cancel();
    _locationUpdateTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      _sendMyLocation();
    });
  }

  Future<void> _sendMyLocation() async {
    final token = await StorageService().getToken();
    if (token == null) return;

    try {
      // Obtenir la position GPS réelle
      final position = await LocationService.getCurrentPosition();

      if (position != null) {
        // Appel API: PUT /api/deliveries/{id}/location
        final result = await _deliveryApiService.updateDeliveryLocation(
          deliveryId: widget.deliveryId.toString(),
          latitude: position.latitude,
          longitude: position.longitude,
          token: token,
        );

        if (result['success']) {
          print('📍 Position envoyée: ${position.latitude}, ${position.longitude}');

          if (mounted) {
            setState(() {
              _delivery!['driver_lat'] = position.latitude;
              _delivery!['driver_lng'] = position.longitude;
            });
          }
        }
      } else {
        print('⚠️ Impossible d\'obtenir la position GPS');
      }
    } catch (e) {
      print('Erreur envoi position: $e');
    }
  }

  // ✅ Dialog pour vérifier le PIN (livreur)
  void _showPinVerificationDialog() {
    final TextEditingController pinController = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Vérification PIN'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Veuillez saisir le code PIN à 6 chiffres',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: pinController,
                keyboardType: TextInputType.number,
                maxLength: 6,
                obscureText: true,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                decoration: InputDecoration(
                  hintText: '000000',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () => _verifyPin(pinController.text),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
              ),
              child: const Text('Valider'),
            ),
          ],
        );
      },
    );
  }

  // ✅ Vérification du PIN et validation de la livraison
  Future<void> _verifyPin(String pin) async {
    if (pin.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Le PIN doit contenir 6 chiffres'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final token = await StorageService().getToken();
    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez vous reconnecter'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    Navigator.pop(context);
    setState(() => _isLoading = true);

    try {
      // Appel API pour marquer la livraison comme effectuée
      final result = await _deliveryApiService.markDeliveryCompleted(
        widget.deliveryId.toString(),
        token,
      );

      if (result['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Livraison validée avec succès !'),
            backgroundColor: AppColors.success,
          ),
        );
        await _loadDelivery();
        _locationUpdateTimer?.cancel();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ ${result['message']}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Erreur: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _callDriver() {
    final phone = _delivery?['driver']?['phone'];
    if (phone != null && phone.isNotEmpty) {
      // TODO: Lancer appel téléphonique
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Appel téléphonique - Fonctionnalité à venir'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _openChat() {
    context.push('${AppRoutes.chatDelivery}/${widget.deliveryId}');
  }

  void _scanQrCode() {
    context.push('/delivery/scan-qr?deliveryId=${widget.deliveryId}');
  }

  void _refreshDelivery() {
    _loadDelivery();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _locationUpdateTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _delivery == null) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: AppColors.primary),
              SizedBox(height: 16),
              Text(
                'Chargement de la livraison...',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: AppColors.error),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                style: const TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _refreshDelivery,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                ),
                child: const Text('Réessayer'),
              ),
            ],
          ),
        ),
      );
    }

    final delivery = _delivery!;
    final status = toStringSafe(delivery['status']);
    final isDelivered = status == 'delivered';
    final isInProgress = status == 'in_progress' || status == 'picked_up' || status == 'on_the_way';
    final isPending = status == 'pending' || status == 'confirmed';

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
          'Suivi livraison',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        actions: [
          if (isInProgress && _userRole == 'livreur') ...[
            IconButton(
              icon: const Icon(Icons.pin, color: AppColors.primary),
              onPressed: _showPinVerificationDialog,
              tooltip: 'Vérifier PIN',
            ),
            IconButton(
              icon: const Icon(Icons.qr_code_scanner, color: AppColors.primary),
              onPressed: _scanQrCode,
            ),
          ],
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.textPrimary),
            onPressed: _refreshDelivery,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadDelivery,
        child: Column(
          children: [
            // Carte
            Expanded(
              flex: 45,
              child: DeliveryMap(
                pickupLat: toDoubleSafe(delivery['pickup_lat']),
                pickupLng: toDoubleSafe(delivery['pickup_lng']),
                deliveryLat: toDoubleSafe(delivery['delivery_lat']),
                deliveryLng: toDoubleSafe(delivery['delivery_lng']),
                driverLat: toDoubleSafe(delivery['driver_lat']),
                driverLng: toDoubleSafe(delivery['driver_lng']),
              ),
            ),

            // Statut
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              color: isDelivered
                  ? AppColors.success.withOpacity(0.1)
                  : isInProgress
                      ? AppColors.primary.withOpacity(0.1)
                      : AppColors.warning.withOpacity(0.1),
              child: Row(
                children: [
                  Icon(
                    isDelivered
                        ? Icons.check_circle
                        : isInProgress
                            ? Icons.delivery_dining
                            : Icons.pending,
                    color: isDelivered
                        ? AppColors.success
                        : isInProgress
                            ? AppColors.primary
                            : AppColors.warning,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      isDelivered
                          ? 'Livraison terminée'
                          : isInProgress
                              ? 'En cours de livraison'
                              : 'En attente de prise en charge',
                      style: TextStyle(
                        color: isDelivered
                            ? AppColors.success
                            : isInProgress
                                ? AppColors.primary
                                : AppColors.warning,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  if (isInProgress)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'En direct',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Timeline
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  _buildTimelineStep(
                    isCompleted: isDelivered || isInProgress || isPending,
                    isActive: isPending,
                    label: 'Prise en charge',
                    icon: Icons.store,
                  ),
                  Expanded(
                    child: Container(
                      height: 2,
                      color: (isInProgress || isDelivered)
                          ? AppColors.primary
                          : AppColors.border,
                    ),
                  ),
                  _buildTimelineStep(
                    isCompleted: isInProgress || isDelivered,
                    isActive: isInProgress,
                    label: 'En route',
                    icon: Icons.delivery_dining,
                  ),
                  Expanded(
                    child: Container(
                      height: 2,
                      color: isDelivered ? AppColors.primary : AppColors.border,
                    ),
                  ),
                  _buildTimelineStep(
                    isCompleted: isDelivered,
                    isActive: isDelivered,
                    label: 'Livré',
                    icon: Icons.check_circle,
                  ),
                ],
              ),
            ),

            // Info livreur
            DriverInfoCard(
              delivery: delivery,
              onCall: _callDriver,
              onChat: _openChat,
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineStep({
    required bool isCompleted,
    required bool isActive,
    required String label,
    required IconData icon,
  }) {
    Color color;
    if (isCompleted) {
      color = AppColors.success;
    } else if (isActive) {
      color = AppColors.primary;
    } else {
      color = AppColors.border;
    }

    return Column(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withOpacity(0.1),
            border: Border.all(color: color, width: 2),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
            color: isActive ? AppColors.textPrimary : AppColors.textTertiary,
          ),
        ),
      ],
    );
  }
}
