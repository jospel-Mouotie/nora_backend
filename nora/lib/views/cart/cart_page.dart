import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../config/app_colors.dart';
import '../../config/routes.dart';
import '../../services/api_service.dart';
import '../../services/storage_service.dart';
import '../../widgets/cart/cart_item_card.dart';
import '../../widgets/cart/cart_summary.dart';
import '../../utils/converters.dart';

class CartPage extends StatefulWidget {
  const CartPage({super.key});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  final ApiService _apiService = ApiService();
  List<dynamic> _cartItems = [];
  Map<String, dynamic>? _cartSummary;
  bool _isLoading = true;
  bool _isUpdating = false;
  String? _errorMessage;
  String? _appliedPromoCode;
  int _discountAmount = 0;
  final promoController = TextEditingController();

  @override
  void initState() {
    super.initState();
    print('🛒 [CART PAGE] initState - Page initialisée');
    _loadCart();
  }

  @override
  void dispose() {
    print('🛒 [CART PAGE] dispose - Nettoyage');
    promoController.dispose();
    super.dispose();
  }

  Future<void> _loadCart() async {
    print('🛒 [CART PAGE] _loadCart - Début du chargement');
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final token = await StorageService().getToken();
    print('🔑 [CART PAGE] Token récupéré: ${token != null ? "OK (${token.substring(0, token.length > 20 ? 20 : token.length)}...)" : "NON"}');

    if (token == null) {
      print('⚠️ [CART PAGE] Pas de token, utilisateur non connecté');
      setState(() {
        _cartItems = [];
        _isLoading = false;
        _errorMessage = 'Veuillez vous connecter pour voir votre panier';
      });
      return;
    }

    try {
      print('📡 [CART PAGE] Appel API getCart...');
      final result = await _apiService.getCart(token);
      print('📡 [CART PAGE] Réponse getCart: success=${result['success']}');

      if (result['success'] && result['cart'] != null) {
        final cart = result['cart'];
        final items = cart['items'] ?? [];
        final totalAmount = toDoubleSafe(cart['total_amount']);
        
        print('✅ [CART PAGE] Panier chargé: ${items.length} articles, total: $totalAmount FCFA');

        setState(() {
          _cartItems = items;
          _cartSummary = {
            'subtotal': totalAmount.toInt(),
            'delivery_fee': 500,
            'total': (totalAmount + 500).toInt(),
            'item_count': cart['total_items'] ?? items.length,
          };
          _isLoading = false;
        });
      } else {
        print('❌ [CART PAGE] Erreur chargement: ${result['message']}');
        setState(() {
          _cartItems = [];
          _cartSummary = null;
          _isLoading = false;
          _errorMessage = result['message'] ?? 'Erreur lors du chargement du panier';
        });
      }
    } catch (e) {
      print('💥 [CART PAGE] Exception _loadCart: $e');
      print('StackTrace: ${StackTrace.current}');
      setState(() {
        _cartItems = [];
        _cartSummary = null;
        _isLoading = false;
        _errorMessage = 'Erreur de connexion au serveur';
      });
    }
  }

  Future<void> _updateQuantity(int itemId, int newQuantity) async {
    print('🛒 [CART PAGE] _updateQuantity - Item: $itemId, Nouvelle quantité: $newQuantity');
    
    if (newQuantity < 1) {
      print('⚠️ [CART PAGE] Quantité invalide (<1), annulation');
      return;
    }

    setState(() => _isUpdating = true);

    final token = await StorageService().getToken();
    print('🔑 [CART PAGE] Token pour update: ${token != null ? "OK" : "NON"}');

    if (token == null) {
      print('❌ [CART PAGE] Pas de token pour update');
      _showError('Veuillez vous reconnecter');
      setState(() => _isUpdating = false);
      return;
    }

    try {
      print('📡 [CART PAGE] Appel API updateCartItem...');
      final result = await _apiService.updateCartItem(itemId, newQuantity, token);
      print('📡 [CART PAGE] Réponse update: success=${result['success']}');

      if (result['success']) {
        print('✅ [CART PAGE] Quantité mise à jour, rechargement du panier...');
        await _loadCart();
      } else {
        print('❌ [CART PAGE] Erreur update: ${result['message']}');
        _showError(result['message'] ?? 'Erreur lors de la mise à jour');
      }
    } catch (e) {
      print('💥 [CART PAGE] Exception _updateQuantity: $e');
      _showError('Erreur de connexion');
    } finally {
      setState(() => _isUpdating = false);
      print('🛒 [CART PAGE] _updateQuantity - Terminé');
    }
  }

  Future<void> _removeItem(int itemId) async {
    print('🛒 [CART PAGE] _removeItem - Item ID: $itemId');
    
    setState(() => _isUpdating = true);

    final token = await StorageService().getToken();
    print('🔑 [CART PAGE] Token pour remove: ${token != null ? "OK" : "NON"}');

    if (token == null) {
      print('❌ [CART PAGE] Pas de token pour remove');
      _showError('Veuillez vous reconnecter');
      setState(() => _isUpdating = false);
      return;
    }

    try {
      print('📡 [CART PAGE] Appel API removeCartItem...');
      final result = await _apiService.removeCartItem(itemId, token);
      print('📡 [CART PAGE] Réponse remove: success=${result['success']}');

      if (result['success']) {
        print('✅ [CART PAGE] Article supprimé, rechargement...');
        await _loadCart();
      } else {
        print('❌ [CART PAGE] Erreur remove: ${result['message']}');
        _showError(result['message'] ?? 'Erreur lors de la suppression');
      }
    } catch (e) {
      print('💥 [CART PAGE] Exception _removeItem: $e');
      _showError('Erreur de connexion');
    } finally {
      setState(() => _isUpdating = false);
      print('🛒 [CART PAGE] _removeItem - Terminé');
    }
  }

  Future<void> _clearCart() async {
    print('🛒 [CART PAGE] _clearCart - Tentative de vidage');
    
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Vider le panier'),
        content: const Text('Voulez-vous vraiment vider votre panier ?'),
        actions: [
          TextButton(
            onPressed: () {
              print('❌ [CART PAGE] Vidage annulé par utilisateur');
              Navigator.pop(context, false);
            },
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              print('✅ [CART PAGE] Vidage confirmé par utilisateur');
              Navigator.pop(context, true);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: const Text('Vider'),
          ),
        ],
      ),
    );

    if (confirm != true) {
      print('🛒 [CART PAGE] Vidage annulé');
      return;
    }

    setState(() => _isUpdating = true);

    final token = await StorageService().getToken();
    print('🔑 [CART PAGE] Token pour clear: ${token != null ? "OK" : "NON"}');

    if (token == null) {
      print('❌ [CART PAGE] Pas de token pour clear');
      _showError('Veuillez vous reconnecter');
      setState(() => _isUpdating = false);
      return;
    }

    try {
      print('📡 [CART PAGE] Appel API clearCart...');
      final result = await _apiService.clearCart(token);
      print('📡 [CART PAGE] Réponse clear: success=${result['success']}');

      if (result['success']) {
        print('✅ [CART PAGE] Panier vidé avec succès');
        await _loadCart();
      } else {
        print('❌ [CART PAGE] Erreur clear: ${result['message']}');
        _showError(result['message'] ?? 'Erreur lors du vidage');
      }
    } catch (e) {
      print('💥 [CART PAGE] Exception _clearCart: $e');
      _showError('Erreur de connexion');
    } finally {
      setState(() => _isUpdating = false);
      print('🛒 [CART PAGE] _clearCart - Terminé');
    }
  }

  void _applyPromoCode() {
    print('🏷️ [CART PAGE] _applyPromoCode - Ouverture dialogue');
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Code promo'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Entrez votre code promo'),
            const SizedBox(height: 16),
            TextField(
              controller: promoController,
              decoration: const InputDecoration(
                hintText: 'CODE2026',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              print('❌ [CART PAGE] Application promo annulée');
              Navigator.pop(context);
            },
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              final code = promoController.text.trim();
              print('🏷️ [CART PAGE] Code promo saisi: "$code"');
              
              if (code.isEmpty) {
                print('⚠️ [CART PAGE] Code promo vide');
                _showError('Veuillez entrer un code promo');
                return;
              }
              
              Navigator.pop(context);
              setState(() => _isUpdating = true);
              
              try {
                print('📡 [CART PAGE] Appel API applyPromotion...');
                // TODO: Implémenter appel API
                await Future.delayed(const Duration(seconds: 1)); // Simuler appel
                print('✅ [CART PAGE] Code promo simulé appliqué');
                
                setState(() {
                  _appliedPromoCode = code;
                  _discountAmount = 1000;
                  if (_cartSummary != null) {
                    _cartSummary!['total'] = _cartSummary!['total'] - _discountAmount;
                  }
                });
                _showSuccess('Code promo appliqué !');
              } catch (e) {
                print('💥 [CART PAGE] Erreur application promo: $e');
                _showError('Erreur lors de l\'application du code promo');
              } finally {
                setState(() => _isUpdating = false);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
            ),
            child: const Text('Appliquer'),
          ),
        ],
      ),
    );
  }

  void _removePromoCode() {
    print('🏷️ [CART PAGE] _removePromoCode - Suppression du code promo: $_appliedPromoCode');
    setState(() {
      _appliedPromoCode = null;
      if (_cartSummary != null) {
        _cartSummary!['total'] = _cartSummary!['total'] + _discountAmount;
      }
      _discountAmount = 0;
    });
    print('✅ [CART PAGE] Code promo supprimé');
  }

  void _goToCheckout() {
    print('🛒 [CART PAGE] _goToCheckout - Navigation vers checkout');
    
    if (_cartItems.isEmpty) {
      print('⚠️ [CART PAGE] Panier vide, impossible de commander');
      _showError('Votre panier est vide');
      return;
    }
    
    print('✅ [CART PAGE] Redirection vers checkout avec ${_cartItems.length} articles');
    context.push(AppRoutes.checkout);
  }

  void _showError(String message) {
    print('❌ [CART PAGE] Erreur affichée: $message');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
      ),
    );
  }

  void _showSuccess(String message) {
    print('✅ [CART PAGE] Succès: $message');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.success,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    print('🖥️ [CART PAGE] build - Rendering page');
    
    if (_isLoading) {
      print('⏳ [CART PAGE] build - Affichage chargement');
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    if (_errorMessage != null && _cartItems.isEmpty) {
      print('⚠️ [CART PAGE] build - Affichage erreur: $_errorMessage');
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
            onPressed: () {
              print('🔙 [CART PAGE] Bouton retour appuyé');
              context.pop();
            },
          ),
          title: const Text(
            'Mon panier',
            style: TextStyle(color: AppColors.textPrimary),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: AppColors.error),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                style: const TextStyle(
                  fontSize: 16,
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  print('🔄 [CART PAGE] Bouton réessayer appuyé');
                  _loadCart();
                },
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

    if (_cartItems.isEmpty) {
      print('📭 [CART PAGE] build - Panier vide');
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
            onPressed: () {
              print('🔙 [CART PAGE] Bouton retour appuyé (panier vide)');
              context.pop();
            },
          ),
          title: const Text(
            'Mon panier',
            style: TextStyle(color: AppColors.textPrimary),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.shopping_bag_outlined, size: 80, color: AppColors.textTertiary),
              const SizedBox(height: 16),
              Text(
                'Votre panier est vide',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Ajoutez des produits depuis la boutique',
                style: TextStyle(color: AppColors.textTertiary),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  print('🏠 [CART PAGE] Bouton Découvrir appuyé');
                  context.go(AppRoutes.home);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                ),
                child: const Text('Découvrir'),
              ),
            ],
          ),
        ),
      );
    }

    print('🛍️ [CART PAGE] build - Affichage panier avec ${_cartItems.length} articles');
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () {
            print('🔙 [CART PAGE] Bouton retour appuyé');
            context.pop();
          },
        ),
        title: const Text(
          'Mon panier',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        actions: [
          TextButton(
            onPressed: () {
              print('🗑️ [CART PAGE] Bouton "Tout supprimer" appuyé');
              _clearCart();
            },
            child: const Text(
              'Tout supprimer',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isLargeScreen = constraints.maxWidth > 800;
          
          Widget cartContent = Column(
            children: [
              // Message paiement
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.backgroundLight,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    Icon(Icons.local_shipping_outlined, color: AppColors.primary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'Paiement à la livraison ou en ligne',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            'Payez en toute sécurité selon votre choix',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Liste des articles
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () {
                    print('🔄 [CART PAGE] Pull-to-refresh déclenché');
                    return _loadCart();
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _cartItems.length,
                    itemBuilder: (context, index) {
                      final item = _cartItems[index];
                      return CartItemCard(
                        item: item,
                        onQuantityChanged: (newQuantity) {
                          _updateQuantity(item['id'], newQuantity);
                        },
                        onRemove: () {
                          _removeItem(item['id']);
                        },
                        isUpdating: _isUpdating,
                      );
                    },
                  ),
                ),
              ),
            ],
          );

          Widget summaryContent = Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Code promo
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Vous avez un code promo ?',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        _applyPromoCode();
                      },
                      child: const Text(
                        'Ajouter >',
                        style: TextStyle(color: AppColors.primary),
                      ),
                    ),
                  ],
                ),
              ),
              // Résumé
              if (_cartSummary != null)
                CartSummary(
                  summary: _cartSummary!,
                  onCheckout: _goToCheckout,
                ),
            ],
          );

          if (isLargeScreen) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 2, child: cartContent),
                Expanded(
                  flex: 1, 
                  child: Container(
                    padding: const EdgeInsets.only(top: 16, right: 16, bottom: 16),
                    child: Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: summaryContent,
                    ),
                  )
                ),
              ],
            );
          }

          return Column(
            children: [
              Expanded(child: cartContent),
              summaryContent,
            ],
          );
        },
      ),
    );
  }
}