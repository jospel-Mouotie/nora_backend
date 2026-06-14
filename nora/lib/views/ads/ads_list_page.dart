import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../config/app_colors.dart';
import '../../../config/routes.dart';
import '../../../services/ad_service.dart';
import '../../../services/storage_service.dart';
import '../../../widgets/ads/ad_card.dart';

class AdsListPage extends StatefulWidget {
  const AdsListPage({super.key});

  @override
  State<AdsListPage> createState() => _AdsListPageState();
}

class _AdsListPageState extends State<AdsListPage> {
  final AdService _adService = AdService();
  List<dynamic> _ads = [];
  bool _isLoading = true;
  String? _token;

  @override
  void initState() {
    super.initState();
    _loadAds();
  }

  Future<void> _loadAds() async {
    setState(() => _isLoading = true);

    _token = await StorageService().getToken();
    if (_token == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final result = await _adService.getMyAds(_token!);
      if (result['success'] && result['ads'] != null) {
        setState(() {
          _ads = result['ads'];
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      print('Erreur chargement publicités: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _startAd(int adId) async {
    if (_token == null) return;

    final result = await _adService.startAd(adId, _token!);
    if (result['success']) {
      _loadAds();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Campagne démarrée'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  Future<void> _pauseAd(int adId) async {
    if (_token == null) return;

    final result = await _adService.pauseAd(adId, _token!);
    if (result['success']) {
      _loadAds();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Campagne mise en pause'),
          backgroundColor: AppColors.warning,
        ),
      );
    }
  }

  Future<void> _deleteAd(int adId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer la publicité'),
        content: const Text('Voulez-vous vraiment supprimer cette publicité ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    if (_token == null) return;

    final result = await _adService.deleteAd(adId, _token!);
    if (result['success']) {
      _loadAds();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Publicité supprimée'),
          backgroundColor: AppColors.success,
        ),
      );
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
          'Mes publicités',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: AppColors.primary),
            onPressed: () {
              context.push(AppRoutes.createAd);
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      )
          : _token == null
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.lock_outline, size: 64, color: AppColors.textTertiary),
            const SizedBox(height: 16),
            const Text(
              'Connectez-vous pour gérer vos publicités',
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.push(AppRoutes.login),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
              ),
              child: const Text('Se connecter'),
            ),
          ],
        ),
      )
          : _ads.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.campaign, size: 64, color: AppColors.textTertiary),
            const SizedBox(height: 16),
            const Text(
              'Aucune publicité',
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                context.push(AppRoutes.createAd);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
              ),
              child: const Text('Créer une publicité'),
            ),
          ],
        ),
      )
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _ads.length,
        itemBuilder: (context, index) {
          final ad = _ads[index];
          return AdCard(
            ad: ad,
            onTap: () {
              context.push('${AppRoutes.adDetail}/${ad['id']}');
            },
            onStart: ad['status'] != 'active'
                ? () => _startAd(ad['id'])
                : null,
            onPause: ad['status'] == 'active'
                ? () => _pauseAd(ad['id'])
                : null,
            onDelete: () => _deleteAd(ad['id']),
          );
        },
      ),
    );
  }
}