import 'product_model.dart';

class Cart {
  final int id;
  final int userId;
  final double totalAmount;
  final double promotionDiscount;
  final String status;
  final DateTime? expiresAt;
  final List<CartItem> items;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Cart({
    required this.id,
    required this.userId,
    required this.totalAmount,
    required this.promotionDiscount,
    required this.status,
    this.expiresAt,
    required this.items,
    this.createdAt,
    this.updatedAt,
  });

  factory Cart.fromJson(Map<String, dynamic> json) {
    List<CartItem> items = [];
    if (json['items'] is List) {
      items = (json['items'] as List)
          .map((i) => CartItem.fromJson(i as Map<String, dynamic>))
          .toList();
    }

    return Cart(
      id: json['id'] ?? 0,
      userId: json['user_id'] ?? 0,
      totalAmount: (json['total_amount'] is num)
          ? (json['total_amount'] as num).toDouble()
          : 0.0,
      promotionDiscount: (json['promotion_discount'] is num)
          ? (json['promotion_discount'] as num).toDouble()
          : 0.0,
      status: json['status'] ?? 'active',
      expiresAt: json['expires_at'] != null
          ? DateTime.parse(json['expires_at'])
          : null,
      items: items,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'total_amount': totalAmount,
      'promotion_discount': promotionDiscount,
      'status': status,
      'expires_at': expiresAt?.toIso8601String(),
      'items': items.map((i) => i.toJson()).toList(),
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  double get finalAmount => totalAmount - promotionDiscount;
  
  int get totalItems => items.fold(0, (sum, item) => sum + item.quantity);
  
  bool get isActive => status == 'active';
  
  bool get isExpired => expiresAt != null && expiresAt!.isBefore(DateTime.now());
}

class CartItem {
  final int id;
  final int cartId;
  final int productVariantId;
  final int quantity;
  final double unitPrice;
  final double totalPrice;
  final double promotionDiscount;
  final ProductVariant? variant;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  CartItem({
    required this.id,
    required this.cartId,
    required this.productVariantId,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
    required this.promotionDiscount,
    this.variant,
    this.createdAt,
    this.updatedAt,
  });

  factory CartItem.fromJson(Map<String, dynamic> json) {
    ProductVariant? variant;
    if (json['product_variant'] != null) {
      variant = ProductVariant.fromJson(json['product_variant']);
    } else if (json['variant'] != null) {
      variant = ProductVariant.fromJson(json['variant']);
    }

    return CartItem(
      id: json['id'] ?? 0,
      cartId: json['cart_id'] ?? 0,
      productVariantId: json['product_variant_id'] ?? 0,
      quantity: json['quantity'] ?? 0,
      unitPrice: (json['unit_price'] is num)
          ? (json['unit_price'] as num).toDouble()
          : 0.0,
      totalPrice: (json['total_price'] is num)
          ? (json['total_price'] as num).toDouble()
          : 0.0,
      promotionDiscount: (json['promotion_discount'] is num)
          ? (json['promotion_discount'] as num).toDouble()
          : 0.0,
      variant: variant,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'cart_id': cartId,
      'product_variant_id': productVariantId,
      'quantity': quantity,
      'unit_price': unitPrice,
      'total_price': totalPrice,
      'promotion_discount': promotionDiscount,
      'product_variant': variant?.toJson(),
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  double get finalPrice => totalPrice - promotionDiscount;
  
  bool get hasPromotion => promotionDiscount > 0;
}
