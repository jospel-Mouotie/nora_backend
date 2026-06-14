// lib/features/merchant/pages/merchant_videos_page.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../config/app_colors.dart';
import '../../../config/routes.dart';
import '../../../services/video_api_service.dart';
import '../../../services/storage_service.dart';

class MerchantVideosPage extends StatefulWidget {
  const MerchantVideosPage({super.key});

  @override
  State<MerchantVideosPage> createState() => _MerchantVideosPageState();
}

class _MerchantVideosPageState extends State<MerchantVideosPage> {
  final VideoApiService _videoApiService = VideoApiService();
  List<dynamic> _videos = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadVideos();
  }

  Future<void> _loadVideos() async {
    setState(() => _isLoading = true);
    
    final token = await StorageService().getToken();
    if (token == null) {
      setState(() => _isLoading = false);
      return;
    }
    
    try {
      final result = await _videoApiService.getMyVideos(token);
      if (result['success'] && result['videos'] != null) {
        setState(() {
          _videos = result['videos'];
          _isLoading = false;
        });
      } else {
        _loadTestVideos();
      }
    } catch (e) {
      debugPrint('Erreur chargement: $e');
      _loadTestVideos();
    }
  }

  void _loadTestVideos() {
    setState(() {
      _videos = [
        {
          'id': 1,
          'title': 'Présentation collection été',
          'thumbnail_path': null,
          'views_count': 1234,
          'likes_count': 89,
          'created_at': '2026-05-16',
        },
        {
          'id': 2,
          'title': 'Tutoriel produit',
          'thumbnail_path': null,
          'views_count': 567,
          'likes_count': 34,
          'created_at': '2026-05-15',
        },
      ];
      _isLoading = false;
    });
  }

  void _uploadVideo() {
    context.push(AppRoutes.videoUpload);
  }

  void _editVideo(Map<String, dynamic> video) {
    context.push(
      '${AppRoutes.videoUpload}?videoId=${video['id']}',
      extra: video,
    ).then((_) => _loadVideos());
  }

  Future<void> _deleteVideo(int videoId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer la vidéo'),
        content: const Text('Voulez-vous vraiment supprimer cette vidéo ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    
    if (confirm != true) return;
    
    final token = await StorageService().getToken();
    if (token != null) {
      try {
        final result = await _videoApiService.deleteVideo(videoId, token);
        if (result['success']) {
          _loadVideos();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Vidéo supprimée'),
                backgroundColor: AppColors.success,
              ),
            );
          }
        }
      } catch (e) {
        debugPrint('Erreur suppression: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Erreur lors de la suppression'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text(
          'Mes vidéos',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: AppColors.primary),
            onPressed: _uploadVideo,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : _videos.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.video_library, size: 64, color: AppColors.textTertiary),
                      const SizedBox(height: 16),
                      const Text(
                        'Aucune vidéo',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _uploadVideo,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                        ),
                        child: const Text('Ajouter une vidéo'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadVideos,
                  child: GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 0.75,
                    ),
                    itemCount: _videos.length,
                    itemBuilder: (context, index) {
                      final video = _videos[index];
                      return Container(
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Thumbnail
                            Expanded(
                              child: ClipRRect(
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(12),
                                ),
                                child: Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    if (video['thumbnail_path'] != null)
                                      Image.network(
                                        video['thumbnail_path'],
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) {
                                          return Container(
                                            color: AppColors.backgroundLight,
                                            child: Icon(
                                              Icons.video_library,
                                              size: 40,
                                              color: AppColors.primary,
                                            ),
                                          );
                                        },
                                      )
                                    else
                                      Container(
                                        color: AppColors.backgroundLight,
                                        child: Icon(
                                          Icons.play_circle_outline,
                                          size: 40,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                    Container(
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          begin: Alignment.topCenter,
                                          end: Alignment.bottomCenter,
                                          colors: [
                                            Colors.transparent,
                                            Colors.black.withOpacity(0.5),
                                          ],
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      bottom: 8,
                                      right: 8,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.black.withOpacity(0.7),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          _formatDuration(video['duration_seconds']),
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 10,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            // Infos
                            Padding(
                              padding: const EdgeInsets.all(8),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    video['title'] ?? 'Sans titre',
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w500,
                                      fontSize: 13,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      const Icon(Icons.visibility, size: 12, color: AppColors.textSecondary),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${video['views_count'] ?? 0}',
                                        style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                      ),
                                      const SizedBox(width: 12),
                                      const Icon(Icons.favorite, size: 12, color: AppColors.textSecondary),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${video['likes_count'] ?? 0}',
                                        style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: TextButton(
                                          onPressed: () {
                                            context.push(
                                              '${AppRoutes.videoPlayer}/${video['id']}',
                                            );
                                          },
                                          style: TextButton.styleFrom(
                                            padding: EdgeInsets.zero,
                                            minimumSize: const Size(0, 30),
                                          ),
                                          child: const Text('Voir', style: TextStyle(fontSize: 12)),
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.edit,
                                            size: 18, color: AppColors.primary),
                                        onPressed: () => _editVideo(video),
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete,
                                            size: 18, color: AppColors.error),
                                        onPressed: () => _deleteVideo(video['id']),
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
    );
  }

  String _formatDuration(int? seconds) {
    if (seconds == null || seconds == 0) return '00:00';
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }
}