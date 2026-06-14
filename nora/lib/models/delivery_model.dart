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
  
  bool get hasLocation => currentLatitude != null && currentLongitude != null;
  
  bool get isPinValid {
    if (pinExpiresAt == null) return false;
    return DateTime.now().isBefore(pinExpiresAt!);
  }
}
