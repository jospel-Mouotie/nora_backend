class MBItem {
  final int id;
  final String name;
  final String? description;
  final String? image;
  final double price;
  final String category;
  final String type;
  final bool featured;
  final bool isActive;
  final int? stock;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  MBItem({
    required this.id,
    required this.name,
    this.description,
    this.image,
    required this.price,
    required this.category,
    required this.type,
    required this.featured,
    required this.isActive,
    this.stock,
    this.createdAt,
    this.updatedAt,
  });

  factory MBItem.fromJson(Map<String, dynamic> json) {
    return MBItem(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      description: json['description'],
      image: json['image'],
      price: (json['price'] is num) ? (json['price'] as num).toDouble() : 0.0,
      category: json['category'] ?? 'general',
      type: json['type'] ?? 'item',
      featured: json['featured'] ?? false,
      isActive: json['is_active'] ?? true,
      stock: json['stock'],
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
      'name': name,
      'description': description,
      'image': image,
      'price': price,
      'category': category,
      'type': type,
      'featured': featured,
      'is_active': isActive,
      'stock': stock,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  bool get isInStock => stock == null || stock! > 0;
  
  bool get isOutOfStock => stock != null && stock! <= 0;
  
  String get formattedPrice => price.toStringAsFixed(2);
}

class MBPurchase {
  final int id;
  final int userId;
  final int mbItemId;
  final double amount;
  final String status;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final MBItem? item;

  MBPurchase({
    required this.id,
    required this.userId,
    required this.mbItemId,
    required this.amount,
    required this.status,
    this.createdAt,
    this.updatedAt,
    this.item,
  });

  factory MBPurchase.fromJson(Map<String, dynamic> json) {
    MBItem? item;
    if (json['mb_item'] != null) {
      item = MBItem.fromJson(json['mb_item']);
    }

    return MBPurchase(
      id: json['id'] ?? 0,
      userId: json['user_id'] ?? 0,
      mbItemId: json['mb_item_id'] ?? 0,
      amount: (json['amount'] is num) ? (json['amount'] as num).toDouble() : 0.0,
      status: json['status'] ?? 'pending',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
      item: item,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'mb_item_id': mbItemId,
      'amount': amount,
      'status': status,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'mb_item': item?.toJson(),
    };
  }

  bool get isPending => status == 'pending';
  bool get isCompleted => status == 'completed';
  bool get isFailed => status == 'failed';
  
  String get formattedAmount => amount.toStringAsFixed(2);
}
