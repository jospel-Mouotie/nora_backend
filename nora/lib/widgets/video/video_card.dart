import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../config/app_colors.dart';
import '../../../services/video_cache_service.dart';
import '../../../services/video_api_service.dart';

class VideoCard extends StatefulWidget {
  final Map<String, dynamic> video;
  final bool isActive;

  const VideoCard({
    super.key,
    required this.video,
    required this.isActive,
  });

  @override
  State<VideoCard> createState() => _VideoCardState();
}

class _VideoCardState extends State<VideoCard> {
  final VideoApiService _videoApiService = VideoApiService();
  final VideoCacheService _cacheService = VideoCacheService();

  VideoPlayerController? _controller;
  ChewieController? _chewieController;
  bool _isInitialized = false;
  bool _isLoading = true;
  bool _isBuffering = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initVideo();
  }

  Future<void> _initVideo() async {
    final videoId = widget.video['id'];
    final streamUrl = _videoApiService.getStreamUrl(videoId);

    debugPrint('🎬 VideoCard - Streaming URL: $streamUrl');

    if (streamUrl.isEmpty) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Vidéo non disponible';
        });
      }
      return;
    }

    try {
      // Vérifier le cache
      final videoFile = await _cacheService.getVideoFile(streamUrl);

      if (videoFile != null) {
        _controller = VideoPlayerController.file(videoFile);
      } else {
        _controller = VideoPlayerController.networkUrl(
          Uri.parse(streamUrl),
          httpHeaders: {
            'Accept': 'video/mp4,video/*',
            'User-Agent': 'Mozilla/5.0',
          },
        );
      }

      // Écouter le buffering
      _controller!.addListener(_onControllerUpdate);

      await _controller!.initialize();

      if (widget.video['trim_start'] != null) {
        final trimStart = double.tryParse(widget.video['trim_start'].toString());
        if (trimStart != null) {
          await _controller!.seekTo(Duration(milliseconds: (trimStart * 1000).toInt()));
        }
      }

      _chewieController = ChewieController(
        videoPlayerController: _controller!,
        autoPlay: widget.isActive,
        looping: true,
        showControls: false,
        showControlsOnInitialize: false,
        allowFullScreen: false,
        allowMuting: true,
        customControls: const CupertinoControls(
          backgroundColor: Colors.black54,
          iconColor: Colors.white,
        ),
        // ✅ Style élégant pour les contrôles
        materialProgressColors: ChewieProgressColors(
          playedColor: AppColors.primary,
          handleColor: AppColors.primary,
          backgroundColor: Colors.white24,
          bufferedColor: Colors.white12,
        ),
      );

      if (mounted) {
        setState(() {
          _isInitialized = true;
          _isLoading = false;
          _isBuffering = false;
        });
      }

    } catch (e) {
      debugPrint('❌ Erreur initialisation vidéo: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Erreur de chargement';
        });
      }
    }
  }

  void _onControllerUpdate() {
    if (!mounted) return;

    // Mettre à jour l'état de buffering
    final isBuffering = _controller?.value.isBuffering ?? false;
    if (_isBuffering != isBuffering) {
      setState(() {
        _isBuffering = isBuffering;
      });
    }

    if (_controller != null && _controller!.value.isInitialized) {
      double? trimStart;
      double? trimEnd;
      if (widget.video['trim_start'] != null) {
        trimStart = double.tryParse(widget.video['trim_start'].toString());
      }
      if (widget.video['trim_end'] != null) {
        trimEnd = double.tryParse(widget.video['trim_end'].toString());
      }

      if (trimStart != null && trimEnd != null) {
        final currentPos = _controller!.value.position.inMilliseconds / 1000.0;
        if (currentPos >= trimEnd || currentPos < trimStart) {
          _controller!.seekTo(Duration(milliseconds: (trimStart * 1000).toInt()));
        }
      }
    }
  }

  @override
  void didUpdateWidget(VideoCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive != oldWidget.isActive) {
      if (widget.isActive && _chewieController != null) {
        _chewieController!.play();
      } else if (!widget.isActive && _chewieController != null) {
        _chewieController!.pause();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Contenu principal
          _buildMainContent(),

          // Indicateur de chargement élégant
          if (_isLoading || _isBuffering) _buildLoadingOverlay(),

          // Message d'erreur
          if (_errorMessage != null) _buildErrorOverlay(),
        ],
      ),
    );
  }

  Widget _buildMainContent() {
    // Afficher la miniature en fond pendant le chargement
    final thumbnailUrl = widget.video['thumbnail_url'] ?? widget.video['thumbnail_path'];

    if (!_isInitialized || _chewieController == null) {
      // Fond miniature ou noir
      if (thumbnailUrl != null && thumbnailUrl.toString().isNotEmpty) {
        return CachedNetworkImage(
          imageUrl: thumbnailUrl.toString(),
          fit: BoxFit.cover,
          placeholder: (context, url) => Container(color: Colors.black),
          errorWidget: (context, url, error) => Container(color: Colors.black),
        );
      }
      return Container(color: Colors.black);
    }

    return Chewie(
      controller: _chewieController!,
    );
  }

  Widget _buildLoadingOverlay() {
    return Container(
      color: Colors.black.withOpacity(0.7),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Spinner élégant
            SizedBox(
              width: 48,
              height: 48,
              child: CircularProgressIndicator(
                color: AppColors.primary,
                strokeWidth: 3,
              ),
            ),
            const SizedBox(height: 16),
            // Texte élégant
            AnimatedOpacity(
              opacity: _isBuffering ? 1.0 : 0.5,
              duration: const Duration(milliseconds: 500),
              child: Text(
                _isBuffering ? 'Chargement de la vidéo...' : 'Préparation...',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorOverlay() {
    return Container(
      color: Colors.black.withOpacity(0.8),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icône d'erreur élégante
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white12,
              ),
              child: const Icon(
                Icons.error_outline,
                size: 32,
                color: Colors.white54,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              style: const TextStyle(
                color: Colors.white54,
                fontSize: 14,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 24),
            // Bouton réessayer élégant
            GestureDetector(
              onTap: () {
                setState(() {
                  _errorMessage = null;
                  _isLoading = true;
                });
                _initVideo();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: const Text(
                  'RÉESSAYER',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller?.removeListener(_onControllerUpdate);
    _chewieController?.dispose();
    _controller?.dispose();
    super.dispose();
  }
}
