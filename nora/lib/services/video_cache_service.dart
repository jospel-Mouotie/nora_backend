// lib/services/video_cache_service.dart
import 'dart:io';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'package:video_player/video_player.dart';

class VideoCacheService {
  static final VideoCacheService _instance = VideoCacheService._internal();
  factory VideoCacheService() => _instance;
  VideoCacheService._internal();

  final CacheManager cacheManager = CacheManager(
    Config(
      'videoCache',
      stalePeriod: const Duration(days: 7),
      maxNrOfCacheObjects: 50,
    ),
  );

  final CacheManager thumbnailCacheManager = CacheManager(
    Config(
      'thumbnailCache',
      stalePeriod: const Duration(days: 30),
      maxNrOfCacheObjects: 200,
    ),
  );

  /// Récupérer un fichier vidéo du cache
  Future<File?> getVideoFile(String url) async {
    try {
      final file = await cacheManager.getSingleFile(url);
      return file;
    } catch (e) {
      print('Erreur chargement vidéo: $e');
      return null;
    }
  }

  /// Mettre en cache une vidéo pour une lecture hors ligne
  Future<void> cacheVideoForOffline(String url) async {
    try {
      await cacheManager.downloadFile(url);
      print('Vidéo mise en cache: $url');
    } catch (e) {
      print('Erreur cache vidéo: $e');
    }
  }

  /// Vérifier si une vidéo est en cache
  Future<bool> isVideoCached(String url) async {
    try {
      final file = await cacheManager.getFileFromCache(url);
      return file != null;
    } catch (e) {
      return false;
    }
  }

  /// Générer une miniature à partir d'une URL vidéo
  Future<String?> generateThumbnailFromUrl(String videoUrl, {int seconds = 1}) async {
    try {
      final thumbnail = await VideoThumbnail.thumbnailFile(
        video: videoUrl,
        thumbnailPath: (await getTemporaryDirectory()).path,
        imageFormat: ImageFormat.JPEG,
        quality: 80,
        timeMs: seconds * 1000,
      );
      return thumbnail;
    } catch (e) {
      print('Erreur génération miniature depuis URL: $e');
      return null;
    }
  }

  /// Générer une miniature à partir d'un fichier local
  Future<String?> generateThumbnailFromFile(String filePath, {int seconds = 1}) async {
    try {
      final thumbnail = await VideoThumbnail.thumbnailFile(
        video: filePath,
        thumbnailPath: (await getTemporaryDirectory()).path,
        imageFormat: ImageFormat.JPEG,
        quality: 80,
        timeMs: seconds * 1000,
      );
      return thumbnail;
    } catch (e) {
      print('Erreur génération miniature depuis fichier: $e');
      return null;
    }
  }

  /// Mettre en cache une miniature
  Future<void> cacheThumbnail(String thumbnailUrl) async {
    try {
      await thumbnailCacheManager.downloadFile(thumbnailUrl);
    } catch (e) {
      print('Erreur cache miniature: $e');
    }
  }

  /// Obtenir une miniature du cache
  Future<File?> getThumbnail(String url) async {
    try {
      final file = await thumbnailCacheManager.getSingleFile(url);
      return file;
    } catch (e) {
      return null;
    }
  }

  /// Nettoyer tous les caches
  Future<void> clearCache() async {
    await cacheManager.emptyCache();
    await thumbnailCacheManager.emptyCache();
  }

  /// Obtenir la durée d'une vidéo
  Future<Duration?> getVideoDuration(String videoUrl) async {
    try {
      final controller = VideoPlayerController.networkUrl(Uri.parse(videoUrl));
      await controller.initialize();
      final duration = controller.value.duration;
      await controller.dispose();
      return duration;
    } catch (e) {
      print('Erreur getVideoDuration: $e');
      return null;
    }
  }

  /// Obtenir la taille du cache vidéo (méthode corrigée)
  Future<int> getVideoCacheSize() async {
    try {
      // Utiliser getTemporaryDirectory pour obtenir le dossier de cache
      final appDir = await getTemporaryDirectory();
      final cachePath = '${appDir.path}/videoCache';
      final cacheDir = Directory(cachePath);

      if (await cacheDir.exists()) {
        int totalSize = 0;
        await for (final file in cacheDir.list()) {
          if (file is File) {
            totalSize += await file.length();
          }
        }
        return totalSize;
      }
      return 0;
    } catch (e) {
      print('Erreur getVideoCacheSize: $e');
      return 0;
    }
  }

  /// Supprimer les vidéos plus anciennes qu'un certain nombre de jours
  Future<void> clearOldVideos({int olderThanDays = 7}) async {
    try {
      final appDir = await getTemporaryDirectory();
      final cachePath = '${appDir.path}/videoCache';
      final cacheDir = Directory(cachePath);

      if (await cacheDir.exists()) {
        final now = DateTime.now();
        await for (final entity in cacheDir.list()) {
          if (entity is File) {
            final stat = await entity.stat();
            if (now.difference(stat.modified).inDays > olderThanDays) {
              await entity.delete();
            }
          }
        }
      }
    } catch (e) {
      print('Erreur suppression anciennes vidéos: $e');
    }
  }

  /// Obtenir le chemin du cache vidéo
  Future<String?> getVideoCachePath() async {
    try {
      final appDir = await getTemporaryDirectory();
      return '${appDir.path}/videoCache';
    } catch (e) {
      return null;
    }
  }
}
