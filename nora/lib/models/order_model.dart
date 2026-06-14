import 'product_model.dart';

class Order {
  final int id;
  final String orderNumber;
  final double totalAmount;
  final double promotionDiscount;
  final double deliveryFee;
  final double finalAmount;
  final String pin;
  final String qrCode;
  final String status;
  final String paymentStatus;
  final String deliveryAddress;
  final String? notes;
  final int userId;
  final int shopId;
  final List<OrderItem> items;
  final Delivery? delivery;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? confirmedAt;
  final DateTime? deliveredAt;

  Order({
    required this.id,
    required this.orderNumber,
    required this.totalAmount,
    required this.promotionDiscount,
    required this.deliveryFee,
    required this.finalAmount,
    required this.pin,
    required this.qrCode,
    required this.status,
    required this.paymentStatus,
    required this.deliveryAddress,
    this.notes,
    required this.userId,
    required this.shopId,
    required this.items,
    this.delivery,
    this.createdAt,
    this.updatedAt,
    this.confirmedAt,
    this.deliveredAt,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    List<OrderItem> items = [];
    if (json['items'] is List) {
      items = (json['items'] as List)
          .map((i) => OrderItem.fromJson(i as Map<String, dynamic>))
          .toList();
    }

    Delivery? delivery;
    if (json['delivery'] != null) {
      delivery = Delivery.fromJson(json['delivery']);
    }

    return Order(
      id: json['id'] ?? 0,
      orderNumber: json['order_number'] ?? '',
      totalAmount: (json['total_amount'] is num)
          ? (json['total_amount'] as num).toDouble()
          : 0.0,
      promotionDiscount: (json['promotion_discount'] is num)
          ? (json['promotion_discount'] as num).toDouble()
          : 0.0,
      deliveryFee: (json['delivery_fee'] is num)
          ? (json['delivery_fee'] as num).toDouble()
          : 0.0,
      finalAmount: (json['final_amount'] is num)
          ? (json['final_amount'] as num).toDouble()
          : 0.0,
      pin: json['pin'] ?? '',
      qrCode: json['qr_code'] ?? '',
      status: json['status'] ?? 'pending',
      paymentStatus: json['payment_status'] ?? 'pending',
      deliveryAddress: json['delivery_address'] ?? '',
      notes: json['notes'],
      userId: json['user_id'] ?? 0,
      shopId: json['shop_id'] ?? 0,
      items: items,
      delivery: delivery,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
      confirmedAt: json['confirmed_at'] != null
          ? DateTime.parse(json['confirmed_at'])
          : null,
      deliveredAt: json['delivered_at'] != null
          ? DateTime.parse(json['delivered_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'order_number': orderNumber,
      'total_amount': totalAmount,
      'promotion_discount': promotionDiscount,
      'delivery_fee': deliveryFee,
      'final_amount': finalAmount,
      'pin': pin,
      'qr_code': qrCode,
      'status': status,
      'payment_status': paymentStatus,
      'delivery_address': deliveryAddress,
      'notes': notes,
      'user_id': userId,
      'shop_id': shopId,
      'items': items.map((i) => i.toJson()).toList(),
      'delivery': delivery?.toJson(),
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'confirmed_at': confirmedAt?.toIso8601String(),
      'delivered_at': deliveredAt?.toIso8601String(),
    };
  }

  bool get isPending => status == 'pending';
  bool get isConfirmed => status == 'confirmed';
  bool get isPreparing => status == 'preparing';
  bool get isReady => status == 'ready';
  bool get isInDelivery => status == 'in_delivery';
  bool get isDelivered => status == 'delivered';
  bool get isCancelled => status == 'cancelled';
}

class OrderItem {
  final int id;
  final int orderId;
  final int productVariantId;
  final int quantity;
  final double unitPrice;
  final double totalPrice;
  final double promotionDiscount;
  final ProductVariant? variant;
  final DateTime? createdAt;

  OrderItem({
    required this.id,
    required this.orderId,
    required this.productVariantId,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
    required this.promotionDiscount,
    this.variant,
    this.createdAt,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    ProductVariant? variant;
    if (json['product_variant'] != null) {
      variant = ProductVariant.fromJson(json['product_variant']);
    }

    return OrderItem(
      id: json['id'] ?? 0,
      orderId: json['order_id'] ?? 0,
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
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'order_id': orderId,
      'product_variant_id': productVariantId,
      'quantity': quantity,
      'unit_price': unitPrice,
      'total_price': totalPrice,
      'promotion_discount': promotionDiscount,
      'product_variant': variant?.toJson(),
      'created_at': createdAt?.toIso8601String(),
    };
  }
}

class Delivery {
  final int id;
  final int orderId;
  final int? deliveryPersonId;
  final String? driverName;
  final String? driverPhone;
  final String status;
  final String? currentLatitude;
  final String? currentLongitude;
  final String? deliveryPin;
  final DateTime? pinExpiresAt;
  final DateTime? estimatedDeliveryTime;
  final DateTime? actualDeliveryTime;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Delivery({
    required this.id,
    required this.orderId,
    this.deliveryPersonId,
    this.driverName,
    this.driverPhone,
    required this.status,
    this.currentLatitude,
    this.currentLongitude,
    this.deliveryPin,
    this.pinExpiresAt,
    this.estimatedDeliveryTime,
    this.actualDeliveryTime,
    this.createdAt,
    this.updatedAt,
  });

  factory Delivery.fromJson(Map<String, dynamic> json) {
    return Delivery(
      id: json['id'] ?? 0,
      orderId: json['order_id'] ?? 0,
      deliveryPersonId: json['delivery_person_id'],
      driverName: json['driver_name'],
      driverPhone: json['driver_phone'],
      status: json['status'] ?? 'pending',
      currentLatitude: json['current_latitude'],
      currentLongitude: json['current_longitude'],
      deliveryPin: json['delivery_pin'],
      pinExpiresAt: json['pin_expires_at'] != null
          ? DateTime.parse(json['pin_expires_at'])
          : null,
      estimatedDeliveryTime: json['estimated_delivery_time'] != null
          ? DateTime.parse(json['estimated_delivery_time'])
          : null,
      actualDeliveryTime: json['actual_delivery_time'] != null
          ? DateTime.parse(json['actual_delivery_time'])
          : null,
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
      'order_id': orderId,
      'delivery_person_id': deliveryPersonId,
      'driver_name': driverName,
      'driver_phone': driverPhone,
      'status': status,
      'current_latitude': currentLatitude,
      'current_longitude': currentLongitude,
      'delivery_pin': deliveryPin,
      'pin_expires_at': pinExpiresAt?.toIso8601String(),
      'estimated_delivery_time': estimatedDeliveryTime?.toIso8601String(),
      'actual_delivery_time': actualDeliveryTime?.toIso8601String(),
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  bool get hasDriver => deliveryPersonId != null;
  
  bool get isPending => status == 'pending';
  bool get isAssigned => status == 'assigned';
  bool get isInProgress => status == 'in_progress';
  bool get isDelivered => status == 'delivered';
  bool get isCancelled => status == 'cancelled';
}
