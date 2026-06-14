import 'package:flutter/foundation.dart';
import '../models/product_model.dart';
import '../services/product_api_service.dart';
import 'dart:io';
import '../services/storage_service.dart';

class ProductProvider with ChangeNotifier {
  final ProductApiService _productApiService = ProductApiService();
  final StorageService _storageService = StorageService();

  List<Product> _products = [];
  List<Product> _myProducts = [];
  Product? _currentProduct;
  bool _isLoading = false;
  String? _errorMessage;

  List<Product> get products => _products;
  List<Product> get myProducts => _myProducts;
  Product? get currentProduct => _currentProduct;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Charger tous les produits
  Future<void> loadProducts({
    int limit = 20,
    int page = 1,
    String? search,
    int? categoryId,
    int? shopId,
    String? sort,
    bool? inPromotion,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _productApiService.getProducts(
        limit: limit,
        page: page,
        search: search,
        categoryId: categoryId,
        shopId: shopId,
        sort: sort,
        inPromotion: inPromotion,
      );

      if (result['success']) {
        _products = (result['products'] as List)
            .map((json) => Product.fromJson(json as Map<String, dynamic>))
            .toList();
      } else {
        _errorMessage = result['message'] ?? 'Erreur de chargement';
      }
    } catch (e) {
      _errorMessage = 'Erreur de connexion';
      debugPrint('Erreur loadProducts: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Charger mes produits
  Future<void> loadMyProducts({int page = 1, int limit = 15}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final token = await _storageService.getToken();
      if (token == null) {
        _errorMessage = 'Non connecté';
        _isLoading = false;
        notifyListeners();
        return;
      }

      final result = await _productApiService.getMyProducts(
        token,
        page: page,
        limit: limit,
      );

      if (result['success']) {
        _myProducts = (result['products'] as List)
            .map((json) => Product.fromJson(json as Map<String, dynamic>))
            .toList();
      } else {
        _errorMessage = result['message'] ?? 'Erreur de chargement';
      }
    } catch (e) {
      _errorMessage = 'Erreur de connexion';
      debugPrint('Erreur loadMyProducts: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Charger un produit spécifique
  Future<void> loadProduct(int productId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _productApiService.getProduct(productId);

      if (result['success']) {
        _currentProduct = Product.fromJson(result['product'] as Map<String, dynamic>);
      } else {
        _errorMessage = result['message'] ?? 'Produit non trouvé';
      }
    } catch (e) {
      _errorMessage = 'Erreur de connexion';
      debugPrint('Erreur loadProduct: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Créer un produit
  Future<bool> createProduct({
    required String name,
    required double price,
    required String description,
    required int categoryId,
    required List<dynamic> images,
    List<Map<String, dynamic>>? variants,
    int stock = 0,
    double? comparePrice,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final token = await _storageService.getToken();
      if (token == null) {
        _errorMessage = 'Non connecté';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final result = await _productApiService.createProduct(
        name: name,
        price: price,
        description: description,
        categoryId: categoryId,
        images: images.cast<File>(),
        variants: variants,
        stock: stock,
        comparePrice: comparePrice,
        token: token,
      );

      if (result['success']) {
        await loadMyProducts();
        return true;
      } else {
        _errorMessage = result['message'] ?? 'Erreur lors de la création';
        return false;
      }
    } catch (e) {
      _errorMessage = 'Erreur de connexion';
      debugPrint('Erreur createProduct: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Mettre à jour un produit
  Future<bool> updateProduct({
    required int productId,
    required String name,
    required double price,
    required String description,
    required int categoryId,
    int? stock,
    double? comparePrice,
    bool? isActive,
    List<Map<String, dynamic>>? variants,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final token = await _storageService.getToken();
      if (token == null) {
        _errorMessage = 'Non connecté';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final result = await _productApiService.updateProduct(
        productId: productId,
        name: name,
        price: price,
        description: description,
        categoryId: categoryId,
        stock: stock,
        comparePrice: comparePrice,
        isActive: isActive,
        variants: variants,
        token: token,
      );

      if (result['success']) {
        await loadMyProducts();
        return true;
      } else {
        _errorMessage = result['message'] ?? 'Erreur lors de la mise à jour';
        return false;
      }
    } catch (e) {
      _errorMessage = 'Erreur de connexion';
      debugPrint('Erreur updateProduct: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Supprimer un produit
  Future<bool> deleteProduct(int productId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final token = await _storageService.getToken();
      if (token == null) {
        _errorMessage = 'Non connecté';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final result = await _productApiService.deleteProduct(productId, token);

      if (result['success']) {
        await loadMyProducts();
        return true;
      } else {
        _errorMessage = result['message'] ?? 'Erreur lors de la suppression';
        return false;
      }
    } catch (e) {
      _errorMessage = 'Erreur de connexion';
      debugPrint('Erreur deleteProduct: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Charger les produits en promotion
  Future<void> loadPromotions({int limit = 15}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _productApiService.getPromotions(limit: limit);

      if (result['success']) {
        _products = (result['products'] as List)
            .map((json) => Product.fromJson(json as Map<String, dynamic>))
            .toList();
      } else {
        _errorMessage = result['message'] ?? 'Erreur de chargement';
      }
    } catch (e) {
      _errorMessage = 'Erreur de connexion';
      debugPrint('Erreur loadPromotions: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Charger les produits recommandés
  Future<void> loadRecommendedProducts({int limit = 20}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final token = await _storageService.getToken();
      final result = await _productApiService.getRecommendedProducts(
        limit: limit,
        token: token,
      );

      if (result['success']) {
        _products = (result['products'] as List)
            .map((json) => Product.fromJson(json as Map<String, dynamic>))
            .toList();
      } else {
        _errorMessage = result['message'] ?? 'Erreur de chargement';
      }
    } catch (e) {
      _errorMessage = 'Erreur de connexion';
      debugPrint('Erreur loadRecommendedProducts: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Activer une promotion
  Future<bool> activatePromotion({
    required int productId,
    required double promotionPrice,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final token = await _storageService.getToken();
      if (token == null) {
        _errorMessage = 'Non connecté';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final result = await _productApiService.activatePromotion(
        productId: productId,
        promotionPrice: promotionPrice,
        startDate: startDate,
        endDate: endDate,
        token: token,
      );

      if (result['success']) {
        await loadMyProducts();
        return true;
      } else {
        _errorMessage = result['message'] ?? 'Erreur lors de l\'activation';
        return false;
      }
    } catch (e) {
      _errorMessage = 'Erreur de connexion';
      debugPrint('Erreur activatePromotion: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Désactiver une promotion
  Future<bool> deactivatePromotion(int productId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final token = await _storageService.getToken();
      if (token == null) {
        _errorMessage = 'Non connecté';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final result = await _productApiService.deactivatePromotion(productId, token);

      if (result['success']) {
        await loadMyProducts();
        return true;
      } else {
        _errorMessage = result['message'] ?? 'Erreur lors de la désactivation';
        return false;
      }
    } catch (e) {
      _errorMessage = 'Erreur de connexion';
      debugPrint('Erreur deactivatePromotion: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
