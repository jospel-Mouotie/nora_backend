class Shop {
  final int id;
  final String name;
  final String? description;
  final String? address;
  final String? phone;
  final String? email;
  final String? photo;
  final String? banner;
  final String? photoUrl;
  final String? bannerUrl;
  final double? rating;
  final int? reviewsCount;
  final int? followersCount;
  final int? likesCount;
  final bool isCertified;
  final DateTime? certifiedAt;
  final bool isActive;
  final String status;
  final int userId;
  final bool hasPendingCertification;
  final List<String>? deliveryCities;
  final double? deliveryPrice;
  final double? freeDeliveryMinAmount;
  final String? deliveryType;
  final double? latitude;
  final double? longitude;
  final Map<String, dynamic>? openingHours;
  final String? facebookUrl;
  final String? instagramUrl;
  final String? whatsappNumber;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final List<dynamic>? categories;

  Shop({
    required this.id,
    required this.name,
    this.description,
    this.address,
    this.phone,
    this.email,
    this.photo,
    this.banner,
    this.photoUrl,
    this.bannerUrl,
    this.rating,
    this.reviewsCount,
    this.followersCount,
    this.likesCount,
    required this.isCertified,
    this.certifiedAt,
    required this.isActive,
    required this.status,
    required this.userId,
    this.deliveryCities,
    this.deliveryPrice,
    this.freeDeliveryMinAmount,
    this.deliveryType,
    this.latitude,
    this.longitude,
    this.openingHours,
    this.facebookUrl,
    this.instagramUrl,
    this.whatsappNumber,
    this.createdAt,
    this.updatedAt,
    this.categories,
    required this.hasPendingCertification,
  });

  factory Shop.fromJson(Map<String, dynamic> json) {
    return Shop(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      description: json['description'],
      address: json['address'],
      phone: json['phone'],
      email: json['email'],
      photo: json['photo'],
      banner: json['banner'],
      photoUrl: json['photo_url'],
      bannerUrl: json['banner_url'],
      rating: json['rating'] != null
          ? (json['rating'] is num) ? (json['rating'] as num).toDouble() : null
          : null,
      reviewsCount: json['reviews_count'],
      followersCount: json['followers_count'],
      likesCount: json['likes_count'],
      isCertified: json['certifiee'] ?? json['is_certified'] ?? false,
      certifiedAt: json['certifiee_at'] != null
          ? DateTime.parse(json['certifiee_at'])
          : null,
      isActive: json['is_active'] ?? true,
      status: json['status'] ?? 'en_attente',
      userId: json['user_id'] ?? 0,
      deliveryCities: json['delivery_cities'] is List
          ? (json['delivery_cities'] as List).map((e) => e.toString()).toList()
          : null,
      deliveryPrice: json['delivery_price'] != null
          ? (json['delivery_price'] is num) ? (json['delivery_price'] as num).toDouble() : null
          : null,
      freeDeliveryMinAmount: json['free_delivery_min_amount'] != null
          ? (json['free_delivery_min_amount'] is num) ? (json['free_delivery_min_amount'] as num).toDouble() : null
          : null,
      deliveryType: json['delivery_type'],
      latitude: json['latitude'] != null
          ? (json['latitude'] is num) ? (json['latitude'] as num).toDouble() : null
          : null,
      longitude: json['longitude'] != null
          ? (json['longitude'] is num) ? (json['longitude'] as num).toDouble() : null
          : null,
      openingHours: json['opening_hours'] is Map ? json['opening_hours'] as Map<String, dynamic> : null,
      facebookUrl: json['facebook_url'],
      instagramUrl: json['instagram_url'],
      whatsappNumber: json['whatsapp_number'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
      categories: json['categories'],
      hasPendingCertification: json['has_pending_certification'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'address': address,
      'phone': phone,
      'email': email,
      'photo': photo,
      'banner': banner,
      'photo_url': photoUrl,
      'banner_url': bannerUrl,
      'rating': rating,
      'reviews_count': reviewsCount,
      'followers_count': followersCount,
      'likes_count': likesCount,
      'certifiee': isCertified,
      'certifiee_at': certifiedAt?.toIso8601String(),
      'is_certified': isCertified,
      'is_active': isActive,
      'status': status,
      'user_id': userId,
      'delivery_cities': deliveryCities,
      'delivery_price': deliveryPrice,
      'free_delivery_min_amount': freeDeliveryMinAmount,
      'delivery_type': deliveryType,
      'latitude': latitude,
      'longitude': longitude,
      'opening_hours': openingHours,
      'facebook_url': facebookUrl,
      'instagram_url': instagramUrl,
      'whatsapp_number': whatsappNumber,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'categories': categories,
      'has_pending_certification': hasPendingCertification,
    };
  }

  bool get isPending => status == 'en_attente' || status == 'pending';
  bool get isActiveShop => status == 'active';
  bool get isSuspended => status == 'refusee' || status == 'suspended';
  bool get isRejected => status == 'refusee' || status == 'rejected';
  bool get canAddProducts => isActiveShop && isCertified;
}
