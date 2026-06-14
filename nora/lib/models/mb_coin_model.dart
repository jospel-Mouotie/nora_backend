class MBCoin {
  final int id;
  final int userId;
  final double balance;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  MBCoin({
    required this.id,
    required this.userId,
    required this.balance,
    this.createdAt,
    this.updatedAt,
  });

  factory MBCoin.fromJson(Map<String, dynamic> json) {
    return MBCoin(
      id: json['id'] ?? 0,
      userId: json['user_id'] ?? 0,
      balance: (json['balance'] is num) ? (json['balance'] as num).toDouble() : 0.0,
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
      'balance': balance,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  String get formattedBalance => balance.toStringAsFixed(2);
}

class MBReward {
  final int id;
  final int userId;
  final int? mbCoinId;
  final String title;
  final String? description;
  final String type;
  final double amount;
  final String? sourceType;
  final String? sourceId;
  final Map<String, dynamic>? metadata;
  final bool isClaimed;
  final DateTime? claimedAt;
  final DateTime? expiresAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  MBReward({
    required this.id,
    required this.userId,
    this.mbCoinId,
    required this.title,
    this.description,
    required this.type,
    required this.amount,
    this.sourceType,
    this.sourceId,
    this.metadata,
    required this.isClaimed,
    this.claimedAt,
    this.expiresAt,
    this.createdAt,
    this.updatedAt,
  });

  factory MBReward.fromJson(Map<String, dynamic> json) {
    Map<String, dynamic>? metadata;
    if (json['metadata'] is Map) {
      metadata = Map<String, dynamic>.from(json['metadata']);
    }

    return MBReward(
      id: json['id'] ?? 0,
      userId: json['user_id'] ?? 0,
      mbCoinId: json['mb_coin_id'],
      title: json['title'] ?? '',
      description: json['description'],
      type: json['type'] ?? 'special',
      amount: (json['amount'] is num) ? (json['amount'] as num).toDouble() : 0.0,
      sourceType: json['source_type'],
      sourceId: json['source_id'],
      metadata: metadata,
      isClaimed: json['is_claimed'] ?? false,
      claimedAt: json['claimed_at'] != null
          ? DateTime.parse(json['claimed_at'])
          : null,
      expiresAt: json['expires_at'] != null
          ? DateTime.parse(json['expires_at'])
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
      'user_id': userId,
      'mb_coin_id': mbCoinId,
      'title': title,
      'description': description,
      'type': type,
      'amount': amount,
      'source_type': sourceType,
      'source_id': sourceId,
      'metadata': metadata,
      'is_claimed': isClaimed,
      'claimed_at': claimedAt?.toIso8601String(),
      'expires_at': expiresAt?.toIso8601String(),
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  bool get isExpired => expiresAt != null && expiresAt!.isBefore(DateTime.now());
  
  bool get canClaim => !isClaimed && !isExpired;
  
  String get formattedAmount => amount.toStringAsFixed(2);
}

class MBTransaction {
  final int id;
  final int userId;
  final int? mbCoinId;
  final String type;
  final double amount;
  final String? description;
  final String? sourceType;
  final String? sourceId;
  final double? balanceAfter;
  final DateTime? createdAt;

  MBTransaction({
    required this.id,
    required this.userId,
    this.mbCoinId,
    required this.type,
    required this.amount,
    this.description,
    this.sourceType,
    this.sourceId,
    this.balanceAfter,
    this.createdAt,
  });

  factory MBTransaction.fromJson(Map<String, dynamic> json) {
    return MBTransaction(
      id: json['id'] ?? 0,
      userId: json['user_id'] ?? 0,
      mbCoinId: json['mb_coin_id'],
      type: json['type'] ?? 'credit',
      amount: (json['amount'] is num) ? (json['amount'] as num).toDouble() : 0.0,
      description: json['description'],
      sourceType: json['source_type'],
      sourceId: json['source_id'],
      balanceAfter: json['balance_after'] != null
          ? (json['balance_after'] is num)
              ? (json['balance_after'] as num).toDouble()
              : null
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'mb_coin_id': mbCoinId,
      'type': type,
      'amount': amount,
      'description': description,
      'source_type': sourceType,
      'source_id': sourceId,
      'balance_after': balanceAfter,
      'created_at': createdAt?.toIso8601String(),
    };
  }

  bool get isCredit => type == 'credit';
  
  bool get isDebit => type == 'debit';
  
  String get formattedAmount => isCredit ? '+${amount.toStringAsFixed(2)}' : '-${amount.toStringAsFixed(2)}';
}
