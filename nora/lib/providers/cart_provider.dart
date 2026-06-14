import 'package:flutter/foundation.dart';
import '../models/cart_model.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';

class CartProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  final StorageService _storageService = StorageService();

  Cart? _cart;
  bool _isLoading = false;
  String? _errorMessage;

  Cart? get cart => _cart;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  int get itemCount => _cart?.totalItems ?? 0;
  double get totalAmount => _cart?.finalAmount ?? 0.0;

  CartProvider() {
    loadCart();
  }

  Future<void> loadCart() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final token = await _storageService.getToken();
      if (token == null) {
        _cart = null;
        _isLoading = false;
        notifyListeners();
        return;
      }

      final result = await _apiService.getCart(token);

      if (result['success'] && result['cart'] != null) {
        _cart = Cart.fromJson(result['cart']);
      } else {
        _cart = null;
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Erreur lors du chargement du panier';
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addToCart({
    required int productVariantId,
    required int quantity,
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

      final result = await _apiService.addToCart(
        productId: productVariantId,
        quantity: quantity,
        productVariantId: productVariantId,
        token: token,
      );

      if (result['success']) {
        await loadCart();
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = result['message'] ?? 'Erreur lors de l\'ajout';
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

  Future<bool> updateCartItem(int itemId, int quantity) async {
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

      final result = await _apiService.updateCartItem(itemId, quantity, token);

      if (result['success']) {
        await loadCart();
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

  Future<bool> removeCartItem(int itemId) async {
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

      final result = await _apiService.removeCartItem(itemId, token);

      if (result['success']) {
        await loadCart();
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

  Future<bool> clearCart() async {
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

      final result = await _apiService.clearCart(token);

      if (result['success']) {
        await loadCart();
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = result['message'] ?? 'Erreur lors du vidage';
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

  Future<bool> applyPromotionCode(String code) async {
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

      // TODO: Implement applyPromotion in API service
      _errorMessage = 'Fonctionnalité à implémenter';
      _isLoading = false;
      notifyListeners();
      return false;
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
