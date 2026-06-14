import 'dart:convert';

class Product {
  final int id;
  final String name;
  final String description;
  final double price;
  final bool isActive;
  final int categoryId;
  final String categoryName;
  final List<String> images;
  final List<ProductVariant> variants;
  final int shopId;
  final String? shopName;
  final double? rating;
  final int? reviewsCount;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  // Champs de promotion
  final bool inPromotion;
  final double? promotionPrice;
  final int? promotionPercentage;
  final DateTime? promotionStart;
  final DateTime? promotionEnd;

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.isActive,
    required this.categoryId,
    required this.categoryName,
    required this.images,
    required this.variants,
    required this.shopId,
    this.shopName,
    this.rating,
    this.reviewsCount,
    this.createdAt,
    this.updatedAt,
    required this.inPromotion,
    this.promotionPrice,
    this.promotionPercentage,
    this.promotionStart,
    this.promotionEnd,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    // Parser les images
    List<String> images = [];
    if (json['images'] is String && (json['images'] as String).isNotEmpty) {
      try {
        if ((json['images'] as String).startsWith('[')) {
          final parsed = jsonDecode(json['images']);
          if (parsed is List) {
            images = parsed.map((e) => e.toString()).toList();
          }
        } else {
          images = [json['images']];
        }
      } catch (e) {
        images = [];
      }
    } else if (json['images'] is List) {
      images = (json['images'] as List).map((e) => e.toString()).toList();
    }

    // Parser les variantes
    List<ProductVariant> variants = [];
    if (json['variants'] is List) {
      variants = (json['variants'] as List)
          .map((v) => ProductVariant.fromJson(v as Map<String, dynamic>))
          .toList();
    }

    // Parser les dates de promotion
    DateTime? parseDate(String? dateStr) {
      if (dateStr == null || dateStr.isEmpty) return null;
      try {
        return DateTime.parse(dateStr);
      } catch (e) {
        return null;
      }
    }

    return Product(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      isActive: json['is_active'] ?? true,
      categoryId: json['category_id'] ?? 0,
      categoryName: json['category_name'] ?? json['category']?['name'] ?? '',
      images: images,
      variants: variants,
      shopId: json['shop_id'] ?? 0,
      shopName: json['shop_name'] ?? json['shop']?['name'],
      rating: (json['rating'] as num?)?.toDouble(),
      reviewsCount: json['reviews_count'] ?? json['reviews']?['count'],
      createdAt: parseDate(json['created_at']),
      updatedAt: parseDate(json['updated_at']),
      inPromotion: json['in_promotion'] ?? false,
      promotionPrice: (json['promotion_price'] as num?)?.toDouble(),
      promotionPercentage: json['promotion_percentage'] as int?,
      promotionStart: parseDate(json['promotion_start']),
      promotionEnd: parseDate(json['promotion_end']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'is_active': isActive,
      'category_id': categoryId,
      'category_name': categoryName,
      'images': images,
      'variants': variants.map((v) => v.toJson()).toList(),
      'shop_id': shopId,
      'shop_name': shopName,
      'rating': rating,
      'reviews_count': reviewsCount,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'in_promotion': inPromotion,
      'promotion_price': promotionPrice,
      'promotion_percentage': promotionPercentage,
      'promotion_start': promotionStart?.toIso8601String(),
      'promotion_end': promotionEnd?.toIso8601String(),
    };
  }

  // ✅ Propriétés calculées utiles
  bool get isInPromotion {
    if (!inPromotion) return false;
    if (promotionPrice == null) return false;

    final now = DateTime.now();
    if (promotionStart != null && now.isBefore(promotionStart!)) return false;
    if (promotionEnd != null && now.isAfter(promotionEnd!)) return false;

    return true;
  }

  double get currentPrice {
    if (isInPromotion && promotionPrice != null) {
      return promotionPrice!;
    }
    return price;
  }

  double get originalPrice => price;

  int get discountPercentage {
    if (!isInPromotion || promotionPrice == null) return 0;
    return ((price - promotionPrice!) / price * 100).round();
  }

  bool get hasDiscount => isInPromotion && discountPercentage > 0;

  int get totalStock {
    int total = 0;
    for (var variant in variants) {
      total += variant.availableQuantity;
    }
    return total;
  }

  bool get isInStock => totalStock > 0;
}

class ProductVariant {
  final int id;
  final String? size;
  final String? color;
  final String? material;
  final String? sku;
  final double? priceAdjustment;
  final bool isActive;
  final int productId;
  final VariantStock? stock;

  ProductVariant({
    required this.id,
    this.size,
    this.color,
    this.material,
    this.sku,
    this.priceAdjustment,
    required this.isActive,
    required this.productId,
    this.stock,
  });

  factory ProductVariant.fromJson(Map<String, dynamic> json) {
    VariantStock? stock;
    if (json['stock'] != null) {
      stock = VariantStock.fromJson(json['stock'] as Map<String, dynamic>);
    }

    return ProductVariant(
      id: json['id'] ?? 0,
      size: json['size'],
      color: json['color'],
      material: json['material'],
      sku: json['sku'],
      priceAdjustment: (json['price_adjustment'] as num?)?.toDouble(),
      isActive: json['is_active'] ?? true,
      productId: json['product_id'] ?? 0,
      stock: stock,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'size': size,
      'color': color,
      'material': material,
      'sku': sku,
      'price_adjustment': priceAdjustment,
      'is_active': isActive,
      'product_id': productId,
      'stock': stock?.toJson(),
    };
  }

  String get fullName {
    final parts = <String>[];
    if (size != null && size!.isNotEmpty) parts.add(size!);
    if (color != null && color!.isNotEmpty) parts.add(color!);
    if (material != null && material!.isNotEmpty) parts.add(material!);
    return parts.join(' - ');
  }

  int get availableQuantity => stock?.availableQuantity ?? 0;

  bool get isInStock => availableQuantity > 0;

  double get adjustedPrice {
    final basePrice = 0.0; // Sera remplacé par le prix du produit parent
    return basePrice + (priceAdjustment ?? 0);
  }
}

class VariantStock {
  final int id;
  final int quantity;
  final int reservedQuantity;
  final int lowStockThreshold;
  final bool lowStockAlert;

  VariantStock({
    required this.id,
    required this.quantity,
    required this.reservedQuantity,
    required this.lowStockThreshold,
    required this.lowStockAlert,
  });

  factory VariantStock.fromJson(Map<String, dynamic> json) {
    return VariantStock(
      id: json['id'] ?? 0,
      quantity: (json['quantity'] as num?)?.toInt() ?? 0,
      reservedQuantity: (json['reserved_quantity'] as num?)?.toInt() ?? 0,
      lowStockThreshold: (json['low_stock_threshold'] as num?)?.toInt() ?? 5,
      lowStockAlert: json['low_stock_alert'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'quantity': quantity,
      'reserved_quantity': reservedQuantity,
      'low_stock_threshold': lowStockThreshold,
      'low_stock_alert': lowStockAlert,
    };
  }

  int get availableQuantity => quantity - reservedQuantity;

  bool get isLowStock => lowStockAlert || availableQuantity <= lowStockThreshold;
}
