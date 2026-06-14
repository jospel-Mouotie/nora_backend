class UserModel {
  final int id;
  final String name;
  final String email;
  final String? phone;
  final String? avatar;
  final String role;
  final String? emailVerifiedAt;
  final String createdAt;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.avatar,
    required this.role,
    this.emailVerifiedAt,
    required this.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'],
      avatar: json['profile_picture'],
      role: json['role'] ?? 'customer',
      emailVerifiedAt: json['email_verified_at'],
      createdAt: json['created_at'] ?? '',
    );
  }

Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'profile_picture': avatar,
      'role': role,
      'email_verified_at': emailVerifiedAt,
      'created_at': createdAt,
    };
  }

  bool get isEmailVerified => emailVerifiedAt != null;
  bool get isAdmin => role == 'admin';
  bool get isMerchant => role == 'merchant' || role == 'boutiqueur';
  bool get isDelivery => role == 'chauffeur';
}