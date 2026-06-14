// lib/services/video_api_service.dart
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:flutter/foundation.dart';
import '../config/app_constants.dart';

class VideoApiService {
  static const String baseUrl = AppConstants.apiBaseUrl;

  // ==========================================
  // RÉCUPÉRATION DES VIDÉOS (PUBLIQUES)
  // ==========================================

  /// Récupérer toutes les vidéos publiques
  Future<Map<String, dynamic>> getVideos({
    int? shopId,
    int? userId,
    int? limit,
    int page = 1,
  }) async {
    try {
      final queryParams = <String, String>{};
      if (shopId != null) queryParams['shop_id'] = shopId.toString();
      if (userId != null) queryParams['user_id'] = userId.toString();
      if (limit != null) queryParams['limit'] = limit.toString();
      queryParams['page'] = page.toString();

      final uri = Uri.parse('$baseUrl/videos').replace(queryParameters: queryParams);
      final response = await http.get(
        uri,
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final videos = data['videos'] ?? data['data'] ?? [];

        final videosWithUrls = videos.map((video) {
          video['thumbnail_url'] = getThumbnailUrl(video['thumbnail_path']);
          video['video_url'] = getVideoUrl(video['video_path']);
          return video;
        }).toList();

        return {
          'success': true,
          'videos': videosWithUrls,
        };
      }
      return {'success': false, 'videos': []};
    } catch (e) {
      debugPrint('❌ Erreur getVideos: $e');
      return {'success': false, 'videos': []};
    }
  }

  /// Récupérer les vidéos d'une boutique
  Future<Map<String, dynamic>> getShopVideos(int shopId, {int limit = 20}) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/videos?shop_id=$shopId&limit=$limit'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final videos = data['videos'] ?? data['data'] ?? [];

        final videosWithUrls = videos.map((video) {
          video['thumbnail_url'] = getThumbnailUrl(video['thumbnail_path']);
          video['video_url'] = getVideoUrl(video['video_path']);
          return video;
        }).toList();

        return {
          'success': true,
          'videos': videosWithUrls,
        };
      }
      return {'success': false, 'videos': []};
    } catch (e) {
      debugPrint('❌ Erreur getShopVideos: $e');
      return {'success': false, 'videos': []};
    }
  }

  /// Récupérer les vidéos d'un utilisateur
  Future<Map<String, dynamic>> getUserVideos(int userId, {int limit = 20}) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/videos?user_id=$userId&limit=$limit'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final videos = data['videos'] ?? data['data'] ?? [];

        final videosWithUrls = videos.map((video) {
          video['thumbnail_url'] = getThumbnailUrl(video['thumbnail_path']);
          video['video_url'] = getVideoUrl(video['video_path']);
          return video;
        }).toList();

        return {
          'success': true,
          'videos': videosWithUrls,
        };
      }
      return {'success': false, 'videos': []};
    } catch (e) {
      debugPrint('❌ Erreur getUserVideos: $e');
      return {'success': false, 'videos': []};
    }
  }

  /// Récupérer mes vidéos (utilisateur connecté)
  Future<Map<String, dynamic>> getMyVideos(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/videos/my'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      debugPrint('📥 My videos response status: ${response.statusCode}');
      debugPrint('📥 My videos response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final videos = data['videos'] ?? data['data'] ?? [];

        final videosWithUrls = videos.map((video) {
          video['thumbnail_url'] = getThumbnailUrl(video['thumbnail_path']);
          video['video_url'] = getVideoUrl(video['video_path']);
          return video;
        }).toList();

        return {
          'success': true,
          'videos': videosWithUrls,
        };
      } else {
        debugPrint('❌ My videos error status: ${response.statusCode}');
        return {'success': false, 'videos': []};
      }
    } catch (e) {
      debugPrint('❌ Erreur getMyVideos: $e');
      return {'success': false, 'videos': []};
    }
  }

  /// Récupérer une vidéo spécifique par son ID
  Future<Map<String, dynamic>> getVideo(int videoId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/videos/$videoId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final video = data['video'] ?? data;

        video['thumbnail_url'] = getThumbnailUrl(video['thumbnail_path']);
        video['video_url'] = getVideoUrl(video['video_path']);

        return {
          'success': true,
          'video': video,
        };
      }
      return {'success': false, 'message': 'Vidéo non trouvée'};
    } catch (e) {
      debugPrint('❌ Erreur getVideo: $e');
      return {'success': false, 'message': 'Erreur de connexion'};
    }
  }

  /// Récupérer les vidéos tendances
  Future<Map<String, dynamic>> getTrendingVideos({int days = 7, int limit = 20}) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/videos/trending?days=$days&limit=$limit'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final videos = data['videos'] ?? data['data'] ?? [];

        final videosWithUrls = videos.map((video) {
          video['thumbnail_url'] = getThumbnailUrl(video['thumbnail_path']);
          video['video_url'] = getVideoUrl(video['video_path']);
          return video;
        }).toList();

        return {
          'success': true,
          'videos': videosWithUrls,
        };
      }
      return {'success': false, 'videos': []};
    } catch (e) {
      debugPrint('❌ Erreur getTrendingVideos: $e');
      return {'success': false, 'videos': []};
    }
  }

  // ==========================================
  // UPLOAD ET GESTION DES VIDÉOS (AUTHENTIFIÉ)
  // ==========================================

  /// Uploader une nouvelle vidéo
  Future<Map<String, dynamic>> uploadVideo({
    required File videoFile,
    required String title,
    String? description,
    bool isPublic = true,
    bool allowComments = true,
    bool allowDownloads = false,
    int? shopId,
    File? thumbnail,
    double? trimStart,
    double? trimEnd,
    required String token,
  }) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/videos/upload'),
      );

      request.headers['Authorization'] = 'Bearer $token';
      request.headers['Accept'] = 'application/json';

      final videoExtension = videoFile.path.split('.').last.toLowerCase();
      request.files.add(
        await http.MultipartFile.fromPath(
          'video',
          videoFile.path,
          contentType: MediaType('video', videoExtension),
        ),
      );

      if (thumbnail != null) {
        final thumbnailExtension = thumbnail.path.split('.').last.toLowerCase();
        request.files.add(
          await http.MultipartFile.fromPath(
            'thumbnail',
            thumbnail.path,
            contentType: MediaType('image', thumbnailExtension),
          ),
        );
      }

      request.fields['title'] = title;
      if (description != null) request.fields['description'] = description;
      request.fields['is_public'] = isPublic ? '1' : '0';
      request.fields['allow_comments'] = allowComments ? '1' : '0';
      request.fields['allow_downloads'] = allowDownloads ? '1' : '0';
      if (shopId != null) request.fields['shop_id'] = shopId.toString();
      if (trimStart != null) request.fields['trim_start'] = trimStart.toString();
      if (trimEnd != null) request.fields['trim_end'] = trimEnd.toString();

      debugPrint('📤 Upload vidéo: $title');

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      debugPrint('📥 Response status: ${response.statusCode}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final video = data['video'] ?? data;

        video['thumbnail_url'] = getThumbnailUrl(video['thumbnail_path']);
        video['video_url'] = getVideoUrl(video['video_path']);

        return {
          'success': true,
          'video': video,
          'message': data['message'] ?? 'Vidéo uploadée avec succès',
        };
      } else {
        String errorMessage = 'Erreur lors de l\'upload';
        try {
          final data = jsonDecode(response.body);
          errorMessage = data['message'] ?? data['error'] ?? errorMessage;
        } catch (e) {
          errorMessage = response.body;
        }
        return {
          'success': false,
          'message': errorMessage,
        };
      }
    } catch (e) {
      debugPrint('❌ Erreur uploadVideo: $e');
      return {
        'success': false,
        'message': 'Erreur de connexion: $e',
      };
    }
  }

  /// Supprimer une vidéo
  Future<Map<String, dynamic>> deleteVideo(int videoId, String token) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/videos/$videoId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'message': data['message'] ?? 'Vidéo supprimée',
        };
      }
      return {
        'success': false,
        'message': 'Erreur lors de la suppression',
      };
    } catch (e) {
      debugPrint('❌ Erreur deleteVideo: $e');
      return {'success': false, 'message': 'Erreur de connexion'};
    }
  }

  /// Mettre à jour une vidéo
  Future<Map<String, dynamic>> updateVideo({
    required int videoId,
    String? title,
    String? description,
    bool? isPublic,
    bool? allowComments,
    bool? allowDownloads,
    int? shopId,
    File? thumbnail,
    required String token,
  }) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/videos/$videoId'),
      );

      request.headers['Authorization'] = 'Bearer $token';
      request.headers['Accept'] = 'application/json';

      // Ajouter la méthode POST pour simuler PUT (certains serveurs ne supportent pas multipart PUT)
      request.fields['_method'] = 'PUT';

      if (title != null) request.fields['title'] = title;
      if (description != null) request.fields['description'] = description;
      if (isPublic != null) request.fields['is_public'] = isPublic ? '1' : '0';
      if (allowComments != null) request.fields['allow_comments'] = allowComments ? '1' : '0';
      if (allowDownloads != null) request.fields['allow_downloads'] = allowDownloads ? '1' : '0';
      if (shopId != null) request.fields['shop_id'] = shopId.toString();

      if (thumbnail != null) {
        final thumbnailExtension = thumbnail.path.split('.').last.toLowerCase();
        request.files.add(
          await http.MultipartFile.fromPath(
            'thumbnail',
            thumbnail.path,
            contentType: MediaType('image', thumbnailExtension),
          ),
        );
      }

      debugPrint('📤 Update vidéo: $videoId');

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      debugPrint('📥 Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final video = data['video'] ?? data;

        video['thumbnail_url'] = getThumbnailUrl(video['thumbnail_path']);
        video['video_url'] = getVideoUrl(video['video_path']);

        return {
          'success': true,
          'video': video,
          'message': data['message'] ?? 'Vidéo mise à jour avec succès',
        };
      } else {
        String errorMessage = 'Erreur lors de la mise à jour';
        try {
          final data = jsonDecode(response.body);
          errorMessage = data['message'] ?? data['error'] ?? errorMessage;
        } catch (e) {
          errorMessage = response.body;
        }
        return {
          'success': false,
          'message': errorMessage,
        };
      }
    } catch (e) {
      debugPrint('❌ Erreur updateVideo: $e');
      return {
        'success': false,
        'message': 'Erreur de connexion: $e',
      };
    }
  }

  // ==========================================
  // INTERACTIONS AVEC LES VIDÉOS
  // ==========================================

  Future<Map<String, dynamic>> toggleVideoLike(int videoId, String token) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/videos/$videoId/like'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'liked': data['liked'] ?? false,
          'likesCount': data['likes_count'] ?? 0,
        };
      }
      return {'success': false, 'liked': false, 'likesCount': 0};
    } catch (e) {
      debugPrint('❌ Erreur toggleVideoLike: $e');
      return {'success': false, 'liked': false, 'likesCount': 0};
    }
  }

  Future<Map<String, dynamic>> recordView(int videoId, {int watchDuration = 0}) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/videos/$videoId/view'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'watch_duration': watchDuration}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'viewsCount': data['views_count'] ?? 0,
        };
      }
      return {'success': false, 'viewsCount': 0};
    } catch (e) {
      debugPrint('❌ Erreur recordView: $e');
      return {'success': false, 'viewsCount': 0};
    }
  }

  Future<Map<String, dynamic>> addComment(
    int videoId,
    String content,
    String token,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/videos/$videoId/comments'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'content': content}),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'comment': data['comment'] ?? data,
        };
      }
      return {'success': false, 'message': 'Erreur lors de l\'ajout du commentaire'};
    } catch (e) {
      debugPrint('❌ Erreur addComment: $e');
      return {'success': false, 'message': 'Erreur de connexion'};
    }
  }

  Future<Map<String, dynamic>> getComments(int videoId, {int page = 1}) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/videos/$videoId/comments?page=$page'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'comments': data['comments'] ?? data['data'] ?? [],
        };
      }
      return {'success': false, 'comments': []};
    } catch (e) {
      debugPrint('❌ Erreur getComments: $e');
      return {'success': false, 'comments': []};
    }
  }

  // ==========================================
  // MÉTADONNÉES ET UTILITAIRES
  // ==========================================

  /// Obtenir l'URL de streaming d'une vidéo (PUBLIQUE)
  String getStreamUrl(int videoId) {
    final baseUrlWithoutApi = baseUrl.replaceAll('/api', '');
    return '$baseUrlWithoutApi/api/videos/$videoId/stream';
  }

  /// Obtenir l'URL de la miniature
  String getThumbnailUrl(String? thumbnailPath) {
    if (thumbnailPath == null || thumbnailPath.isEmpty) return '';
    if (thumbnailPath.startsWith('http')) return thumbnailPath;

    String cleanPath = thumbnailPath;
    if (cleanPath.startsWith('/')) cleanPath = cleanPath.substring(1);
    if (cleanPath.startsWith('storage/')) cleanPath = cleanPath.substring(8);
    if (cleanPath.startsWith('video-thumbnails/')) cleanPath = cleanPath;

    final baseUrlWithoutApi = baseUrl.replaceAll('/api', '');
    // S'assurer que le chemin commence par storage/
    if (!cleanPath.startsWith('storage/')) {
      cleanPath = 'storage/$cleanPath';
    }
    return '$baseUrlWithoutApi/$cleanPath';
  }

  /// Obtenir l'URL de la vidéo pour lecture
  String getVideoUrl(String? videoPath) {
    if (videoPath == null || videoPath.isEmpty) return '';
    if (videoPath.startsWith('http')) return videoPath;

    String cleanPath = videoPath;
    if (cleanPath.startsWith('/')) cleanPath = cleanPath.substring(1);
    if (cleanPath.startsWith('storage/')) cleanPath = cleanPath.substring(8);
    if (cleanPath.startsWith('videos/')) cleanPath = cleanPath;

    final baseUrlWithoutApi = baseUrl.replaceAll('/api', '');
    // S'assurer que le chemin commence par storage/
    if (!cleanPath.startsWith('storage/')) {
      cleanPath = 'storage/$cleanPath';
    }
    return '$baseUrlWithoutApi/$cleanPath';
  }
}
