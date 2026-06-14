import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:video_player/video_player.dart';
import '../../../config/app_colors.dart';
import '../../../config/routes.dart';
import '../../../services/video_api_service.dart';
import '../../../services/storage_service.dart';
import '../../../utils/converters.dart';
import '../../../widgets/video/comment_sheet.dart';
import '../../../services/mb_coins_api_service.dart';

class VideoPlayerPage extends StatefulWidget {
  final int videoId;

  const VideoPlayerPage({super.key, required this.videoId});

  @override
  State<VideoPlayerPage> createState() => _VideoPlayerPageState();
}

class _VideoPlayerPageState extends State<VideoPlayerPage>
    with SingleTickerProviderStateMixin {
  final VideoApiService _videoApiService = VideoApiService();
  VideoPlayerController? _controller;
  Map<String, dynamic>? _video;
  bool _isLoading = true;
  bool _isPlaying = false;
  String? _errorMessage;
  bool _isInitialized = false;
  bool _showControls = true;
  bool _isLiked = false;
  int _likesCount = 0;
  int _commentsCount = 0;
  String? _token;
  bool _hasEarnedForView = false;

  // Animation
  late AnimationController _heartAnimController;
  bool _showHeartAnim = false;

  void _safePop() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      context.go(AppRoutes.home);
    }
  }

  @override
  void initState() {
    super.initState();
    _heartAnimController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _loadToken();
    _loadVideo();
  }

  Future<void> _loadToken() async {
    _token = await StorageService().getToken();
  }

  @override
  void dispose() {
    _controller?.removeListener(_onControllerUpdate);
    _controller?.dispose();
    _heartAnimController.dispose();
    super.dispose();
  }

  void _onControllerUpdate() {
    if (mounted && _controller != null) {
      setState(() {
        _isPlaying = _controller!.value.isPlaying;
      });

      // Range looping
      if (_video != null && _controller!.value.isInitialized) {
        final trimStart = double.tryParse(_video!['trim_start']?.toString() ?? '');
        final trimEnd = double.tryParse(_video!['trim_end']?.toString() ?? '');

        if (trimStart != null && trimEnd != null) {
          final currentPos = _controller!.value.position.inMilliseconds / 1000.0;
          if (currentPos >= trimEnd || currentPos < trimStart) {
            _controller!.seekTo(Duration(milliseconds: (trimStart * 1000).toInt()));
          }
        }
      }

      // View earning reward after 5 seconds
      if (!_hasEarnedForView && _controller!.value.isInitialized && _controller!.value.isPlaying && _video != null) {
        final currentPos = _controller!.value.position.inMilliseconds / 1000.0;
        final trimStart = double.tryParse(_video!['trim_start']?.toString() ?? '') ?? 0.0;
        if (currentPos - trimStart >= 5.0) {
          _hasEarnedForView = true;
          _earnCoinsForAction('view');
        }
      }
    }
  }

  Future<void> _loadVideo() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await _videoApiService.getVideo(widget.videoId);
      if (mounted && result['success'] && result['video'] != null) {
        final video = result['video'];
        setState(() {
          _video = video;
          _isLiked = video['is_liked'] ?? false;
          _likesCount = toIntSafe(video['likes_count']);
          _commentsCount = toIntSafe(video['comments_count']);
          _isLoading = false;
        });
        await _initPlayer();
        // Enregistrer une vue
        _videoApiService.recordView(widget.videoId, watchDuration: 1);
      } else if (mounted) {
        setState(() {
          _errorMessage = 'Vidéo non trouvée';
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Erreur chargement vidéo: $e');
      if (mounted) {
        setState(() {
          _errorMessage = 'Erreur de connexion';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _initPlayer() async {
    if (!mounted) return;

    final streamUrl = _videoApiService.getStreamUrl(widget.videoId);

    if (streamUrl.isEmpty) {
      if (mounted) setState(() => _errorMessage = 'Vidéo non disponible');
      return;
    }

    try {
      _controller = VideoPlayerController.networkUrl(
        Uri.parse(streamUrl),
        httpHeaders: {
          'Accept': 'video/mp4,video/*',
          'User-Agent': 'NoraMobile/1.0',
        },
      );
      _controller!.addListener(_onControllerUpdate);
      await _controller!.initialize();

      if (mounted) {
        setState(() => _isInitialized = true);

        // Seek to trim_start if present
        if (_video != null) {
          final trimStart = double.tryParse(_video!['trim_start']?.toString() ?? '');
          if (trimStart != null) {
            await _controller!.seekTo(Duration(milliseconds: (trimStart * 1000).toInt()));
          }
        }

        await _controller!.play();
        setState(() => _isPlaying = true);
      }
    } catch (e) {
      debugPrint('Erreur initialisation lecteur: $e');
      if (mounted) {
        setState(() => _errorMessage = 'Impossible de lire la vidéo');
      }
    }
  }

  Future<void> _earnCoinsForAction(String action) async {
    if (_token == null) return;
    try {
      final api = MbCoinsApiService();
      final result = await api.earnCoins(
        action: action,
        videoId: widget.videoId,
        token: _token!,
      );

      if (result['success'] && result['earned'] > 0) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.monetization_on, color: Colors.amber, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    '+${result['earned']} MB Coin gagné ! (${action == 'view' ? 'Visionnage' : action == 'like' ? 'Like' : 'Commentaire'})',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ],
              ),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Erreur gain MB Coins: $e');
    }
  }

  void _togglePlay() {
    if (_controller == null || !_isInitialized) return;
    if (_controller!.value.isPlaying) {
      _controller!.pause();
      setState(() {
        _isPlaying = false;
        _showControls = true;
      });
    } else {
      _controller!.play();
      setState(() {
        _isPlaying = true;
      });
      // Masquer les contrôles après 2s
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted && _isPlaying) {
          setState(() => _showControls = false);
        }
      });
    }
  }

  void _toggleControls() {
    setState(() => _showControls = !_showControls);
    if (_showControls && _isPlaying) {
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted && _isPlaying) {
          setState(() => _showControls = false);
        }
      });
    }
  }

  Future<void> _toggleLike() async {
    if (_token == null) {
      _showLoginSnack();
      return;
    }
    HapticFeedback.lightImpact();
    final wasLiked = _isLiked;
    setState(() {
      _isLiked = !_isLiked;
      _likesCount = _isLiked ? _likesCount + 1 : _likesCount - 1;
    });

    if (_isLiked) {
      _earnCoinsForAction('like');
    }

    // Animation cœur
    setState(() => _showHeartAnim = true);
    await Future.delayed(const Duration(milliseconds: 700));
    if (mounted) setState(() => _showHeartAnim = false);

    try {
      final result =
          await _videoApiService.toggleVideoLike(widget.videoId, _token!);
      if (!result['success'] && mounted) {
        setState(() {
          _isLiked = wasLiked;
          _likesCount = wasLiked ? _likesCount + 1 : _likesCount - 1;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLiked = wasLiked;
        });
      }
    }
  }

  void _openComments() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CommentSheet(
        videoId: widget.videoId,
        commentsCount: _commentsCount,
        onCountChanged: (newCount) {
          if (newCount > _commentsCount) {
            _earnCoinsForAction('comment');
          }
          if (mounted) setState(() => _commentsCount = newCount);
        },
      ),
    );
  }

  void _openShop() {
    final shop = _video?['shop'];
    if (shop != null && shop['id'] != null) {
      context.push('${AppRoutes.shopDetail}/${shop['id']}');
    }
  }

  void _showLoginSnack() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Connectez-vous pour interagir'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: AppColors.primary),
            SizedBox(height: 16),
            Text('Chargement...', style: TextStyle(color: Colors.white70)),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(_errorMessage!,
                style: const TextStyle(color: Colors.white70)),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadVideo,
              style:
                  ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              child: const Text('Réessayer'),
            ),
          ],
        ),
      );
    }

    if (!_isInitialized || _controller == null) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        // Vidéo
        GestureDetector(
          onTap: _toggleControls,
          onDoubleTap: _toggleLike,
          child: Center(
            child: AspectRatio(
              aspectRatio: _controller!.value.aspectRatio,
              child: VideoPlayer(_controller!),
            ),
          ),
        ),

        // Gradient haut
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: Container(
            height: 120,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.7),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),

        // Gradient bas
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            height: 200,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  Colors.black.withOpacity(0.85),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),

        // Barre du haut
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                children: [
                  IconButton(
                    icon: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.black38,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.arrow_back_rounded,
                          color: Colors.white, size: 20),
                    ),
                    onPressed: _safePop,
                  ),
                  Expanded(
                    child: Text(
                      _video?['title'] ?? '',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),
          ),
        ),

        // Contrôle lecture (au centre)
        AnimatedOpacity(
          opacity: _showControls ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 200),
          child: Center(
            child: GestureDetector(
              onTap: _togglePlay,
              child: Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: Colors.black54,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                  color: Colors.white,
                  size: 36,
                ),
              ),
            ),
          ),
        ),

        // Animation cœur double tap
        if (_showHeartAnim)
          Center(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 400),
              curve: Curves.elasticOut,
              builder: (context, value, _) => Transform.scale(
                scale: value,
                child: const Icon(
                  Icons.favorite_rounded,
                  color: Colors.white,
                  size: 80,
                ),
              ),
            ),
          ),

        // Infos et actions en bas
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Boutique
                  if (_video?['shop'] != null)
                    GestureDetector(
                      onTap: _openShop,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withOpacity(0.3),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.storefront_rounded,
                                color: Colors.white, size: 16),
                            const SizedBox(width: 6),
                            Text(
                              toStringSafe(_video?['shop']?['name']),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(Icons.arrow_forward_ios_rounded,
                                size: 10, color: Colors.white70),
                          ],
                        ),
                      ),
                    ),

                  const SizedBox(height: 12),

                  // Titre & Description
                  Text(
                    _video?['title'] ?? '',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (_video?['description'] != null &&
                      _video!['description'].toString().isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      _video!['description'],
                      style:
                          const TextStyle(color: Colors.white70, fontSize: 13),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],

                  const SizedBox(height: 16),

                  // Barre d'actions
                  Row(
                    children: [
                      // Like
                      _ActionChip(
                        icon: _isLiked
                            ? Icons.favorite_rounded
                            : Icons.favorite_border_rounded,
                        label: _formatCount(_likesCount),
                        color: _isLiked ? Colors.red : Colors.white,
                        onTap: _toggleLike,
                      ),
                      const SizedBox(width: 16),

                      // Commentaires
                      _ActionChip(
                        icon: Icons.chat_bubble_rounded,
                        label: _formatCount(_commentsCount),
                        color: Colors.white,
                        onTap: _openComments,
                      ),
                      const SizedBox(width: 16),

                      // Partager
                      _ActionChip(
                        icon: Icons.share_rounded,
                        label: 'Partager',
                        color: Colors.white,
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Partage — à venir'),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                      ),

                      const Spacer(),

                      // Vues
                      Row(
                        children: [
                          const Icon(Icons.visibility_rounded,
                              size: 16, color: Colors.white54),
                          const SizedBox(width: 4),
                          Text(
                            '${_formatCount(toIntSafe(_video?['views_count']))} vues',
                            style: const TextStyle(
                                color: Colors.white54, fontSize: 12),
                          ),
                        ],
                      ),
                    ],
                  ),

                  // Barre de progression
                  const SizedBox(height: 12),
                  VideoProgressIndicator(
                    _controller!,
                    allowScrubbing: true,
                    colors: VideoProgressColors(
                      playedColor: AppColors.primary,
                      bufferedColor: Colors.white30,
                      backgroundColor: Colors.white12,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _formatCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    }
    return count.toString();
  }
}

class _ActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionChip({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white12,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
