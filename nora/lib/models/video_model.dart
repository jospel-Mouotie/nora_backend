class Video {
  final int id;
  final String title;
  final String? description;
  final String videoPath;
  final String? thumbnailPath;
  final String status;
  final int? durationSeconds;
  final String? resolution;
  final double? fileSizeMb;
  final String format;
  final bool isPublic;
  final bool allowComments;
  final bool allowDownloads;
  final DateTime? publishedAt;
  final int userId;
  final String? userName;
  final int? shopId;
  final String? shopName;
  final int viewCount;
  final int likesCount;
  final int commentsCount;
  final bool isLikedByUser;
  final String? streamUrl;
  final String? processedPath;
  final double? trimStart;
  final double? trimEnd;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Video({
    required this.id,
    required this.title,
    this.description,
    required this.videoPath,
    this.thumbnailPath,
    required this.status,
    this.durationSeconds,
    this.resolution,
    this.fileSizeMb,
    required this.format,
    required this.isPublic,
    required this.allowComments,
    required this.allowDownloads,
    this.publishedAt,
    required this.userId,
    this.userName,
    this.shopId,
    this.shopName,
    required this.viewCount,
    required this.likesCount,
    required this.commentsCount,
    required this.isLikedByUser,
    this.streamUrl,
    this.processedPath,
    this.trimStart,
    this.trimEnd,
    this.createdAt,
    this.updatedAt,
  });

  factory Video.fromJson(Map<String, dynamic> json) {
    return Video(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      description: json['description'],
      videoPath: json['video_path'] ?? '',
      thumbnailPath: json['thumbnail_path'],
      status: json['status'] ?? 'processing',
      durationSeconds: json['duration_seconds'],
      resolution: json['resolution'],
      fileSizeMb: json['file_size_mb'] != null
          ? (json['file_size_mb'] is num)
              ? (json['file_size_mb'] as num).toDouble()
              : null
          : null,
      format: json['format'] ?? 'mp4',
      isPublic: json['is_public'] ?? true,
      allowComments: json['allow_comments'] ?? true,
      allowDownloads: json['allow_downloads'] ?? false,
      publishedAt: json['published_at'] != null
          ? DateTime.parse(json['published_at'])
          : null,
      userId: json['user_id'] ?? 0,
      userName: json['user_name'],
      shopId: json['shop_id'],
      shopName: json['shop_name'],
      viewCount: json['view_count'] ?? 0,
      likesCount: json['likes_count'] ?? 0,
      commentsCount: json['comments_count'] ?? 0,
      isLikedByUser: json['is_liked_by_user'] ?? false,
      streamUrl: json['stream_url'],
      processedPath: json['processed_path'],
      trimStart: json['trim_start'] != null
          ? (json['trim_start'] is num)
              ? (json['trim_start'] as num).toDouble()
              : null
          : null,
      trimEnd: json['trim_end'] != null
          ? (json['trim_end'] is num)
              ? (json['trim_end'] as num).toDouble()
              : null
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
      'title': title,
      'description': description,
      'video_path': videoPath,
      'thumbnail_path': thumbnailPath,
      'status': status,
      'duration_seconds': durationSeconds,
      'resolution': resolution,
      'file_size_mb': fileSizeMb,
      'format': format,
      'is_public': isPublic,
      'allow_comments': allowComments,
      'allow_downloads': allowDownloads,
      'published_at': publishedAt?.toIso8601String(),
      'user_id': userId,
      'user_name': userName,
      'shop_id': shopId,
      'shop_name': shopName,
      'view_count': viewCount,
      'likes_count': likesCount,
      'comments_count': commentsCount,
      'is_liked_by_user': isLikedByUser,
      'stream_url': streamUrl,
      'processed_path': processedPath,
      'trim_start': trimStart,
      'trim_end': trimEnd,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  String get formattedDuration {
    if (durationSeconds == null) return '00:00';
    final minutes = durationSeconds! ~/ 60;
    final seconds = durationSeconds! % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  String get formattedFileSize {
    if (fileSizeMb == null) return '0 MB';
    if (fileSizeMb! < 1024) {
      return '${fileSizeMb!.toStringAsFixed(2)} MB';
    }
    final gb = fileSizeMb! / 1024;
    return '${gb.toStringAsFixed(2)} GB';
  }

  bool get isProcessing => status == 'processing';
  bool get isReady => status == 'ready';
  bool get isFailed => status == 'failed';
  bool get isDeleted => status == 'deleted';
  Video copyWith({
    int? id,
    String? title,
    String? description,
    String? videoPath,
    String? thumbnailPath,
    String? status,
    int? durationSeconds,
    String? resolution,
    double? fileSizeMb,
    String? format,
    bool? isPublic,
    bool? allowComments,
    bool? allowDownloads,
    DateTime? publishedAt,
    int? userId,
    String? userName,
    int? shopId,
    String? shopName,
    int? viewCount,
    int? likesCount,
    int? commentsCount,
    bool? isLikedByUser,
    String? streamUrl,
    String? processedPath,
    double? trimStart,
    double? trimEnd,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Video(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      videoPath: videoPath ?? this.videoPath,
      thumbnailPath: thumbnailPath ?? this.thumbnailPath,
      status: status ?? this.status,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      resolution: resolution ?? this.resolution,
      fileSizeMb: fileSizeMb ?? this.fileSizeMb,
      format: format ?? this.format,
      isPublic: isPublic ?? this.isPublic,
      allowComments: allowComments ?? this.allowComments,
      allowDownloads: allowDownloads ?? this.allowDownloads,
      publishedAt: publishedAt ?? this.publishedAt,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      shopId: shopId ?? this.shopId,
      shopName: shopName ?? this.shopName,
      viewCount: viewCount ?? this.viewCount,
      likesCount: likesCount ?? this.likesCount,
      commentsCount: commentsCount ?? this.commentsCount,
      isLikedByUser: isLikedByUser ?? this.isLikedByUser,
      streamUrl: streamUrl ?? this.streamUrl,
      processedPath: processedPath ?? this.processedPath,
      trimStart: trimStart ?? this.trimStart,
      trimEnd: trimEnd ?? this.trimEnd,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
