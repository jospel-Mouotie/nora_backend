import 'dart:io';
import 'package:flutter/foundation.dart';
import '../models/video_model.dart';
import '../services/video_api_service.dart';
import '../services/storage_service.dart';

class VideoProvider with ChangeNotifier {
  final VideoApiService _apiService = VideoApiService();
  final StorageService _storageService = StorageService();

  List<Video> _videos = [];
  List<Video> _myVideos = [];
  Video? _currentVideo;
  bool _isLoading = false;
  String? _errorMessage;

  List<Video> get videos => _videos;
  List<Video> get myVideos => _myVideos;
  Video? get currentVideo => _currentVideo;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  VideoProvider() {
    loadVideos();
  }

  // ==========================================
  // CHARGEMENT DES VIDÉOS
  // ==========================================

  Future<void> loadVideos({
    int limit = 20,
    int? shopId,
    int? userId,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _apiService.getVideos(
        limit: limit,
        shopId: shopId,
        userId: userId,
      );

      if (result['success']) {
        _videos = (result['videos'] as List)
            .map((v) => Video.fromJson(v as Map<String, dynamic>))
            .toList();
      } else {
        _errorMessage = result['message'] ?? 'Erreur lors du chargement';
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Erreur lors du chargement des vidéos';
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadTrendingVideos({int limit = 20, int days = 7}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _apiService.getTrendingVideos(limit: limit, days: days);

      if (result['success']) {
        _videos = (result['videos'] as List)
            .map((v) => Video.fromJson(v as Map<String, dynamic>))
            .toList();
      } else {
        _errorMessage = result['message'] ?? 'Erreur lors du chargement';
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Erreur lors du chargement des vidéos tendances';
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadShopVideos(int shopId, {int limit = 20}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _apiService.getShopVideos(shopId, limit: limit);

      if (result['success']) {
        _videos = (result['videos'] as List)
            .map((v) => Video.fromJson(v as Map<String, dynamic>))
            .toList();
      } else {
        _errorMessage = result['message'] ?? 'Erreur lors du chargement';
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Erreur lors du chargement des vidéos de la boutique';
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadMyVideos() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final token = await _storageService.getToken();
      if (token == null) {
        _errorMessage = 'Veuillez vous connecter';
        _isLoading = false;
        notifyListeners();
        return;
      }

      final result = await _apiService.getMyVideos(token);

      if (result['success']) {
        _myVideos = (result['videos'] as List)
            .map((v) => Video.fromJson(v as Map<String, dynamic>))
            .toList();
      } else {
        _errorMessage = result['message'] ?? 'Erreur lors du chargement';
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Erreur lors du chargement de vos vidéos';
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadVideo(int videoId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _apiService.getVideo(videoId);

      if (result['success']) {
        _currentVideo = Video.fromJson(result['video'] as Map<String, dynamic>);
      } else {
        _errorMessage = result['message'] ?? 'Vidéo non trouvée';
      }
    } catch (e) {
      _errorMessage = 'Erreur lors du chargement de la vidéo';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ==========================================
  // INTERACTIONS
  // ==========================================

  Future<bool> toggleLike(int videoId) async {
    try {
      final token = await _storageService.getToken();
      if (token == null) {
        _errorMessage = 'Veuillez vous connecter';
        notifyListeners();
        return false;
      }

      final result = await _apiService.toggleVideoLike(videoId, token);

      if (result['success']) {
        final isLiked = result['liked'] ?? false;
        final likesCount = result['likesCount'] ?? 0;

        // Mettre à jour la vidéo courante
        if (_currentVideo?.id == videoId) {
          _currentVideo = _currentVideo!.copyWith(
            isLikedByUser: isLiked,
            likesCount: likesCount,
          );
        }

        // Mettre à jour dans la liste des vidéos
        final index = _videos.indexWhere((v) => v.id == videoId);
        if (index != -1) {
          _videos[index] = _videos[index].copyWith(
            isLikedByUser: isLiked,
            likesCount: likesCount,
          );
        }

        // Mettre à jour dans mes vidéos
        final myIndex = _myVideos.indexWhere((v) => v.id == videoId);
        if (myIndex != -1) {
          _myVideos[myIndex] = _myVideos[myIndex].copyWith(
            isLikedByUser: isLiked,
            likesCount: likesCount,
          );
        }

        notifyListeners();
        return true;
      } else {
        _errorMessage = result['message'] ?? 'Erreur lors du like';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Erreur de connexion au serveur';
      notifyListeners();
      return false;
    }
  }

  Future<void> recordView(int videoId, {int watchDuration = 0}) async {
    try {
      await _apiService.recordView(videoId, watchDuration: watchDuration);
    } catch (e) {
      debugPrint('Erreur recordView: $e');
    }
  }

  // ==========================================
  // UPLOAD ET GESTION
  // ==========================================

  Future<bool> uploadVideo({
    required String videoPath,
    required String title,
    required String description,
    File? thumbnail,
    bool isPublic = true,
    bool allowComments = true,
    bool allowDownloads = false,
    int? shopId,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final token = await _storageService.getToken();
      if (token == null) {
        _errorMessage = 'Veuillez vous connecter';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final file = File(videoPath);
      final result = await _apiService.uploadVideo(
        videoFile: file,
        title: title,
        description: description,
        isPublic: isPublic,
        allowComments: allowComments,
        allowDownloads: allowDownloads,
        shopId: shopId,
        thumbnail: thumbnail,
        token: token,
      );

      if (result['success']) {
        await loadMyVideos();
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = result['message'] ?? 'Erreur lors de l\'upload';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Erreur de connexion au serveur';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteVideo(int videoId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final token = await _storageService.getToken();
      if (token == null) {
        _errorMessage = 'Veuillez vous connecter';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final result = await _apiService.deleteVideo(videoId, token);

      if (result['success']) {
        // Supprimer de la liste locale
        _videos.removeWhere((v) => v.id == videoId);
        _myVideos.removeWhere((v) => v.id == videoId);
        
        if (_currentVideo?.id == videoId) {
          _currentVideo = null;
        }
        
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = result['message'] ?? 'Erreur lors de la suppression';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Erreur de connexion au serveur';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}