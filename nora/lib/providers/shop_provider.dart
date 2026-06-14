import 'dart:io';
import 'package:flutter/foundation.dart';
import '../models/shop_model.dart';
import '../services/shop_api_service.dart';
import '../services/storage_service.dart';

class ShopProvider with ChangeNotifier {
  final ShopApiService _shopApiService = ShopApiService();
  final StorageService _storageService = StorageService();

  Shop? _myShop;
  List<Shop> _myShops = [];
  List<Shop> _shops = [];
  List<Shop> _pendingShops = [];
  Map<String, dynamic>? _stats;
  bool _isLoading = false;
  String? _errorMessage;

  Shop? get myShop => _myShop;
  List<Shop> get myShops => _myShops;
  List<Shop> get shops => _shops;
  List<Shop> get pendingShops => _pendingShops;
  Map<String, dynamic>? get stats => _stats;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  ShopProvider() {
    loadMyShops();
  }

  Future<void> loadMyShop() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final token = await _storageService.getToken();
      if (token == null) {
        _isLoading = false;
        notifyListeners();
        return;
      }

      final result = await _shopApiService.getMyShop(token);

      if (result['success'] && result['shop'] != null) {
        _myShop = Shop.fromJson(result['shop']);
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Erreur lors du chargement de la boutique';
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadMyShops() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final token = await _storageService.getToken();
      if (token == null) {
        _isLoading = false;
        notifyListeners();
        return;
      }

      final result = await _shopApiService.getMyShops(token);

      if (result['success']) {
        _myShops = (result['shops'] as List)
            .map((s) => Shop.fromJson(s as Map<String, dynamic>))
            .toList();
        if (_myShops.isNotEmpty) {
          _myShop = _myShops.first;
        }
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Erreur lors du chargement des boutiques';
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadShops({
    int? categoryId,
    String? city,
    String? search,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _shopApiService.getShops(
        categoryId: categoryId,
        city: city,
        search: search,
      );

      if (result['success']) {
        _shops = (result['shops'] as List)
            .map((s) => Shop.fromJson(s as Map<String, dynamic>))
            .toList();
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Erreur lors du chargement des boutiques';
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadPendingShops() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final token = await _storageService.getToken();
      if (token == null) {
        _isLoading = false;
        notifyListeners();
        return;
      }

      final result = await _shopApiService.getPendingShops(token);

      if (result['success']) {
        _pendingShops = (result['shops'] as List)
            .map((s) => Shop.fromJson(s as Map<String, dynamic>))
            .toList();
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Erreur lors du chargement des boutiques en attente';
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadStats() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final token = await _storageService.getToken();
      if (token == null) {
        _isLoading = false;
        notifyListeners();
        return;
      }

      final result = await _shopApiService.getShopStats(token);

      if (result['success']) {
        _stats = result['stats'];
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Erreur lors du chargement des statistiques';
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createShop({
    required String name,
    required String description,
    required String address,
    required String phone,
    required String email,
    List<int>? categoryIds,
    File? photo,
    File? banner,
    List<String>? deliveryCities,
    double? deliveryPrice,
    double? freeDeliveryMinAmount,
    String? deliveryType,
    double? latitude,
    double? longitude,
    Map<String, dynamic>? openingHours,
    String? facebookUrl,
    String? instagramUrl,
    String? whatsappNumber,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final token = await _storageService.getToken();
      if (token == null) {
        _errorMessage = 'Veuillez vous connecter';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final result = await _shopApiService.createShop(
        name: name,
        description: description,
        address: address,
        phone: phone,
        email: email,
        categoryIds: categoryIds,
        token: token,
        photo: photo,
        banner: banner,
        deliveryCities: deliveryCities,
        deliveryPrice: deliveryPrice,
        freeDeliveryMinAmount: freeDeliveryMinAmount,
        deliveryType: deliveryType,
        latitude: latitude,
        longitude: longitude,
        openingHours: openingHours,
        facebookUrl: facebookUrl,
        instagramUrl: instagramUrl,
        whatsappNumber: whatsappNumber,
      );

      if (result['success']) {
        await loadMyShops();
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = result['message'] ?? 'Erreur lors de la création';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Erreur de connexion au serveur';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateShop({
    required int shopId,
    String? name,
    String? description,
    String? address,
    String? phone,
    String? email,
    List<int>? categoryIds,
    File? photo,
    File? banner,
    List<String>? deliveryCities,
    double? deliveryPrice,
    double? freeDeliveryMinAmount,
    String? deliveryType,
    double? latitude,
    double? longitude,
    Map<String, dynamic>? openingHours,
    String? facebookUrl,
    String? instagramUrl,
    String? whatsappNumber,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final token = await _storageService.getToken();
      if (token == null) {
        _errorMessage = 'Veuillez vous connecter';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final result = await _shopApiService.updateShop(
        shopId: shopId,
        name: name,
        description: description,
        address: address,
        phone: phone,
        email: email,
        categoryIds: categoryIds,
        token: token,
        photo: photo,
        banner: banner,
        deliveryCities: deliveryCities,
        deliveryPrice: deliveryPrice,
        freeDeliveryMinAmount: freeDeliveryMinAmount,
        deliveryType: deliveryType,
        latitude: latitude,
        longitude: longitude,
        openingHours: openingHours,
        facebookUrl: facebookUrl,
        instagramUrl: instagramUrl,
        whatsappNumber: whatsappNumber,
      );

      if (result['success']) {
        await loadMyShops();
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = result['message'] ?? 'Erreur lors de la mise à jour';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Erreur de connexion au serveur';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteShop(int shopId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final token = await _storageService.getToken();
      if (token == null) {
        _errorMessage = 'Veuillez vous connecter';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final result = await _shopApiService.deleteShop(shopId, token);

      if (result['success']) {
        await loadMyShops();
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = result['message'] ?? 'Erreur lors de la suppression';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Erreur de connexion au serveur';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> approveShop(int shopId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final token = await _storageService.getToken();
      if (token == null) {
        _errorMessage = 'Veuillez vous connecter';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final result = await _shopApiService.approveShop(shopId, token);

      if (result['success']) {
        await loadPendingShops();
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = result['message'] ?? 'Erreur lors de l\'approbation';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Erreur de connexion au serveur';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> rejectShop(int shopId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final token = await _storageService.getToken();
      if (token == null) {
        _errorMessage = 'Veuillez vous connecter';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final result = await _shopApiService.rejectShop(shopId, token);

      if (result['success']) {
        await loadPendingShops();
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = result['message'] ?? 'Erreur lors du rejet';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Erreur de connexion au serveur';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> requestCertification(int shopId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final token = await _storageService.getToken();
      if (token == null) {
        _errorMessage = 'Veuillez vous connecter';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final result = await _shopApiService.requestCertification(shopId, token);

      if (result['success']) {
        await loadMyShops();
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = result['message'] ?? 'Erreur lors de la demande';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Erreur de connexion au serveur';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> followShop(int shopId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final token = await _storageService.getToken();
      if (token == null) {
        _errorMessage = 'Veuillez vous connecter';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final result = await _shopApiService.followShop(shopId, token);

      if (result['success']) {
        await loadShops();
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = result['message'] ?? 'Erreur lors du follow';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Erreur de connexion au serveur';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> unfollowShop(int shopId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final token = await _storageService.getToken();
      if (token == null) {
        _errorMessage = 'Veuillez vous connecter';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final result = await _shopApiService.unfollowShop(shopId, token);

      if (result['success']) {
        await loadShops();
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = result['message'] ?? 'Erreur lors du unfollow';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Erreur de connexion au serveur';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> likeShop(int shopId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final token = await _storageService.getToken();
      if (token == null) {
        _errorMessage = 'Veuillez vous connecter';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final result = await _shopApiService.likeShop(shopId, token);

      if (result['success']) {
        await loadShops();
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = result['message'] ?? 'Erreur lors du like';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Erreur de connexion au serveur';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> unlikeShop(int shopId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final token = await _storageService.getToken();
      if (token == null) {
        _errorMessage = 'Veuillez vous connecter';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final result = await _shopApiService.unlikeShop(shopId, token);

      if (result['success']) {
        await loadShops();
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = result['message'] ?? 'Erreur lors du unlike';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Erreur de connexion au serveur';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> addShopReview(int shopId, int rating, String comment) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final token = await _storageService.getToken();
      if (token == null) {
        _errorMessage = 'Veuillez vous connecter';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final result = await _shopApiService.addShopReview(shopId, rating, comment, token);

      if (result['success']) {
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = result['message'] ?? 'Erreur lors de l\'ajout de l\'avis';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Erreur de connexion au serveur';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
