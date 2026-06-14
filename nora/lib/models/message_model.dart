class Message {
  final int id;
  final int senderId;
  final String senderName;
  final String? senderAvatar;
  final int? receiverId;
  final String? receiverName;
  final String content;
  final String type;
  final String? messageType;
  final int? deliveryId;
  final bool isRead;
  final DateTime? readAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Message({
    required this.id,
    required this.senderId,
    required this.senderName,
    this.senderAvatar,
    this.receiverId,
    this.receiverName,
    required this.content,
    required this.type,
    this.messageType,
    this.deliveryId,
    required this.isRead,
    this.readAt,
    this.createdAt,
    this.updatedAt,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'] ?? 0,
      senderId: json['sender_id'] ?? 0,
      senderName: json['sender_name'] ?? '',
      senderAvatar: json['sender_avatar'],
      receiverId: json['receiver_id'],
      receiverName: json['receiver_name'],
      content: json['content'] ?? '',
      type: json['type'] ?? 'text',
      messageType: json['message_type'],
      deliveryId: json['delivery_id'],
      isRead: json['is_read'] ?? false,
      readAt: json['read_at'] != null
          ? DateTime.parse(json['read_at'])
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
      'sender_id': senderId,
      'sender_name': senderName,
      'sender_avatar': senderAvatar,
      'receiver_id': receiverId,
      'receiver_name': receiverName,
      'content': content,
      'type': type,
      'message_type': messageType,
      'delivery_id': deliveryId,
      'is_read': isRead,
      'read_at': readAt?.toIso8601String(),
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  bool get isText => type == 'text';
  bool get isImage => type == 'image';
  bool get isVideo => type == 'video';
  bool get isAudio => type == 'audio';
  bool get isFile => type == 'file';
  
  bool get isFromAdmin => messageType == 'admin';
  bool get isFromDelivery => messageType == 'delivery';
  
  String get formattedTime {
    if (createdAt == null) return '';
    final now = DateTime.now();
    final difference = now.difference(createdAt!);
    
    if (difference.inMinutes < 1) return 'À l\'instant';
    if (difference.inMinutes < 60) return 'Il y a ${difference.inMinutes} min';
    if (difference.inHours < 24) return 'Il y a ${difference.inHours} h';
    if (difference.inDays < 7) return 'Il y a ${difference.inDays} j';
    return '${createdAt!.day.toString().padLeft(2, '0')}/${createdAt!.month.toString().padLeft(2, '0')}';
  }
}

class Conversation {
  final int id;
  final int userId;
  final String userName;
  final String? userAvatar;
  final int? unreadCount;
  final Message? lastMessage;
  final DateTime? updatedAt;

  Conversation({
    required this.id,
    required this.userId,
    required this.userName,
    this.userAvatar,
    this.unreadCount,
    this.lastMessage,
    this.updatedAt,
  });

  factory Conversation.fromJson(Map<String, dynamic> json) {
    Message? lastMessage;
    if (json['last_message'] != null) {
      lastMessage = Message.fromJson(json['last_message']);
    }

    return Conversation(
      id: json['id'] ?? 0,
      userId: json['user_id'] ?? 0,
      userName: json['user_name'] ?? '',
      userAvatar: json['user_avatar'],
      unreadCount: json['unread_count'],
      lastMessage: lastMessage,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'user_name': userName,
      'user_avatar': userAvatar,
      'unread_count': unreadCount,
      'last_message': lastMessage?.toJson(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  bool get hasUnread => unreadCount != null && unreadCount! > 0;
  
  String get lastMessagePreview {
    if (lastMessage == null) return 'Aucun message';
    if (lastMessage!.isImage) return '📷 Image';
    if (lastMessage!.isVideo) return '🎥 Vidéo';
    if (lastMessage!.isAudio) return '🎤 Audio';
    if (lastMessage!.isFile) return '📎 Fichier';
    return lastMessage!.content.length > 30
        ? '${lastMessage!.content.substring(0, 30)}...'
        : lastMessage!.content;
  }
}
