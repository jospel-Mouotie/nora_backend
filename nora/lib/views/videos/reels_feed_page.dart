import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../config/app_colors.dart';
import '../../../config/routes.dart';
import '../../../services/video_api_service.dart';
import '../../../services/storage_service.dart';
import '../../../services/video_cache_service.dart';
import '../../../widgets/video/video_card.dart';
import '../../../widgets/video/video_actions.dart';
import '../../../widgets/video/comment_sheet.dart';
import '../../../utils/converters.dart';

class ReelsFeedPage extends StatefulWidget {
  const ReelsFeedPage({super.key});

  @override
  State<ReelsFeedPage> createState() => _ReelsFeedPageState();
}

class _ReelsFeedPageState extends State<ReelsFeedPage>
    with SingleTickerProviderStateMixin {
  final VideoApiService _videoApiService = VideoApiService();
  final VideoCacheService _cacheService = VideoCacheService();
  late PageController _pageController;

  List<dynamic> _videos = [];
  bool _isInitialLoading = true;
  bool _isLoadingMore = false;
  int _currentIndex = 0;
  bool _hasMore = true;

  final Map<int, bool> _likedStates = {};
  final Map<int, bool> _savedStates = {};
  final Map<int, int> _likesCountMap = {};
  final Map<int, int> _commentsCountMap = {};
  String? _token;

  // Animation
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  // Double-tap like
  bool _showHeartAnimation = false;
  Timer? _heartTimer;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _loadToken();
    _loadInitialVideos();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
  }

  void _safePop() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      context.go(AppRoutes.home);
    }
  }

  Future<void> _loadToken() async {
    _token = await StorageService().getToken();
    if (mounted) setState(() {});
  }

  Future<void> _loadInitialVideos() async {
    setState(() {
      _isInitialLoading = true;
    });

    await _loadVideos(refresh: true);

    if (mounted) setState(() => _isInitialLoading = false);

    _animationController.forward();
  }

  Future<void> _loadVideos({bool refresh = false}) async {
    if (_isLoadingMore) return;
    if (!_hasMore && !refresh) return;

    if (mounted) setState(() => _isLoadingMore = true);

    try {
      final result = await _videoApiService.getVideos(limit: 15);

      if (result['success'] && result['videos'] != null) {
        final newVideos = result['videos'] as List;

        if (refresh) {
          _videos = newVideos;
        } else {
          _videos.addAll(newVideos);
        }

        _hasMore = newVideos.length >= 15;

        // Initialiser les états des vidéos
        for (var video in newVideos) {
          final id = video['id'];
          if (id != null) {
            _likedStates.putIfAbsent(id, () => video['is_liked'] ?? false);
            _likesCountMap.putIfAbsent(id, () => toIntSafe(video['likes_count']));
            _commentsCountMap.putIfAbsent(id, () => toIntSafe(video['comments_count']));
          }
          _preloadVideoAssets(video);
        }
      } else {
        if (refresh) _loadTestVideos();
      }
    } catch (e) {
      debugPrint('❌ Erreur chargement vidéos: $e');
      if (refresh) _loadTestVideos();
    } finally {
      if (mounted) setState(() => _isLoadingMore = false);
    }
  }

  void _loadTestVideos() {
    setState(() {
      _videos = [
        {
          'id': 1,
          'title': 'Nouvelle collection été',
          'description': 'Découvrez notre nouvelle collection #Mode #Été #Tendance',
          'video_url': null,
          'thumbnail': null,
          'duration': 30,
          'views_count': 15234,
          'likes_count': 2345,
          'comments_count': 456,
          'user': {
            'id': 1,
            'name': 'Green Style',
            'avatar': null,
            'is_verified': true,
          },
          'shop': {'id': 1, 'name': 'Green Style'},
          'is_liked': false,
        },
        {
          'id': 2,
          'title': 'Tendances 2026',
          'description': 'Les must-have de la saison #Tendance #Luxe',
          'video_url': null,
          'thumbnail': null,
          'duration': 45,
          'views_count': 8923,
          'likes_count': 1234,
          'comments_count': 234,
          'user': {
            'id': 2,
            'name': 'Fashion Luxe',
            'avatar': null,
            'is_verified': true,
          },
          'shop': {'id': 2, 'name': 'Fashion Luxe'},
          'is_liked': false,
        },
      ];
      _hasMore = false;
      // Initialiser les états
      for (var v in _videos) {
        final id = v['id'];
        _likedStates.putIfAbsent(id, () => false);
        _likesCountMap.putIfAbsent(id, () => toIntSafe(v['likes_count']));
        _commentsCountMap.putIfAbsent(id, () => toIntSafe(v['comments_count']));
      }
    });
  }

  Future<void> _preloadVideoAssets(Map<String, dynamic> video) async {
    final thumbnailUrl = video['thumbnail_path'] ?? video['thumbnail_url'];
    if (thumbnailUrl != null && thumbnailUrl.toString().isNotEmpty) {
      await _cacheService.cacheThumbnail(thumbnailUrl);
    }
  }

  Future<void> _onLikePressed(int videoId) async {
    final wasLiked = _likedStates[videoId] ?? false;
    final currentCount = _likesCountMap[videoId] ?? 0;

    // Mise à jour optimiste
    setState(() {
      _likedStates[videoId] = !wasLiked;
      _likesCountMap[videoId] = wasLiked ? currentCount - 1 : currentCount + 1;
    });

    HapticFeedback.lightImpact();

    if (_token != null) {
      try {
        await _videoApiService.toggleVideoLike(videoId, _token!);
      } catch (e) {
        // Rollback on error
        if (mounted) {
          setState(() {
            _likedStates[videoId] = wasLiked;
            _likesCountMap[videoId] = currentCount;
          });
        }
      }
    }
  }

  void _onDoubleTap(int videoId) {
    // Like si pas déjà liké
    if (!(_likedStates[videoId] ?? false)) {
      _onLikePressed(videoId);
    }
    HapticFeedback.mediumImpact();

    // Animation cœur
    setState(() => _showHeartAnimation = true);
    _heartTimer?.cancel();
    _heartTimer = Timer(const Duration(milliseconds: 800), () {
      if (mounted) setState(() => _showHeartAnimation = false);
    });
  }

  void _onSavePressed(int videoId) {
    final wasSaved = _savedStates[videoId] ?? false;
    setState(() => _savedStates[videoId] = !wasSaved);
    HapticFeedback.selectionClick();
  }

  void _onCommentPressed(Map<String, dynamic> video) {
    final videoId = video['id'];
    final currentCount = _commentsCountMap[videoId] ?? toIntSafe(video['comments_count']);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CommentSheet(
        videoId: videoId,
        commentsCount: currentCount,
        onCountChanged: (newCount) {
          if (mounted) {
            setState(() => _commentsCountMap[videoId] = newCount);
          }
        },
      ),
    );
  }

  void _onSharePressed(Map<String, dynamic> video) {
    final videoId = video['id'];
    final title = toStringSafe(video['title']);
    // Affiche une bottom sheet de partage
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _ShareSheet(
        videoId: videoId,
        title: title,
        apiService: _videoApiService,
      ),
    );
  }

  void _onShopPressed(Map<String, dynamic>? shop) {
    if (shop != null && shop['id'] != null) {
      context.push('${AppRoutes.shopDetail}/${shop['id']}');
    }
  }

  void _onProfilePressed(
    Map<String, dynamic> user,
    Map<String, dynamic>? shop,
  ) {
    if (shop != null && shop['id'] != null) {
      context.push('${AppRoutes.shopDetail}/${shop['id']}');
    }
  }

  String _getThumbnailUrl(Map<String, dynamic> video) {
    final thumbnailPath = video['thumbnail_path'] ?? video['thumbnail'];
    if (thumbnailPath != null && thumbnailPath.toString().isNotEmpty) {
      return _videoApiService.getThumbnailUrl(thumbnailPath.toString());
    }
    return '';
  }

  String _getStreamUrl(Map<String, dynamic> video) {
    final videoId = video['id'];
    return _videoApiService.getStreamUrl(videoId);
  }

  @override
  Widget build(BuildContext context) {
    if (_isInitialLoading && _videos.isEmpty) {
      return _buildLoadingScreen();
    }

    if (_videos.isEmpty && !_isInitialLoading) {
      return _buildEmptyScreen();
    }

    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.black38,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 20),
          ),
          onPressed: _safePop,
        ),
        title: const Text(
          'Reels',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.black38,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.search_rounded, color: Colors.white, size: 20),
            ),
            onPressed: () => context.push(AppRoutes.search),
          ),
        ],
      ),
      body: PageView.builder(
        controller: _pageController,
        scrollDirection: Axis.vertical,
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
            _animationController.reset();
            _animationController.forward();
          });

          // Enregistrer la vue
          if (index < _videos.length) {
            _videoApiService.recordView(_videos[index]['id']);
          }

          // Charger plus
          if (index >= _videos.length - 3 && _hasMore && !_isLoadingMore) {
            _loadVideos();
          }
        },
        itemCount: _videos.length + (_hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _videos.length && _hasMore) {
            return _buildLoadingIndicator();
          }

          final video = _videos[index];
          final videoId = video['id'];
          final isLiked = _likedStates[videoId] ?? (video['is_liked'] ?? false);
          final isSaved = _savedStates[videoId] ?? false;
          final likesCount = _likesCountMap[videoId] ?? toIntSafe(video['likes_count']);
          final commentsCount = _commentsCountMap[videoId] ?? toIntSafe(video['comments_count']);
          final user = video['user'] ?? {};
          final shop = video['shop'];
          final description = toStringSafe(video['description']);
          final title = toStringSafe(video['title']);

          // Enrichir avec les URLs
          final streamUrl = _getStreamUrl(video);
          video['video_url'] = streamUrl;
          final thumbnailUrl = _getThumbnailUrl(video);
          if (thumbnailUrl.isNotEmpty) {
            video['thumbnail_url'] = thumbnailUrl;
          }
          // Mettre à jour les compteurs depuis la map locale
          video['likes_count'] = likesCount;
          video['comments_count'] = commentsCount;

          return AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return GestureDetector(
                onDoubleTap: () => _onDoubleTap(videoId),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Vidéo
                    index == _currentIndex
                        ? Transform.scale(
                            scale: _scaleAnimation.value,
                            child: VideoCard(
                              video: video,
                              isActive: true,
                            ),
                          )
                        : VideoCard(video: video, isActive: false),

                    // Gradient de fond
                    _buildGradientOverlay(),

                    // Overlay principal
                    _buildOverlay(
                      video: video,
                      user: user,
                      shop: shop,
                      description: description,
                      title: title,
                      isLiked: isLiked,
                      isSaved: isSaved,
                      videoId: videoId,
                    ),

                    // Animation cœur sur double-tap
                    if (index == _currentIndex && _showHeartAnimation)
                      _buildHeartAnimation(),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildGradientOverlay() {
    return Positioned.fill(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black.withOpacity(0.3),
              Colors.transparent,
              Colors.transparent,
              Colors.black.withOpacity(0.7),
            ],
            stops: const [0.0, 0.2, 0.6, 1.0],
          ),
        ),
      ),
    );
  }

  Widget _buildOverlay({
    required Map<String, dynamic> video,
    required Map<String, dynamic> user,
    required Map<String, dynamic>? shop,
    required String description,
    required String title,
    required bool isLiked,
    required bool isSaved,
    required int videoId,
  }) {
    return Positioned.fill(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 16, top: 80),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Contenu gauche (infos vidéo)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(left: 16, right: 8),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Bouton boutique (si disponible)
                    if (shop != null && shop['id'] != null)
                      GestureDetector(
                        onTap: () => _onShopPressed(shop),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            gradient: AppColors.primaryGradient,
                            borderRadius: BorderRadius.circular(30),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withOpacity(0.4),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.storefront_rounded,
                                size: 15,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                toStringSafe(shop['name']),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(width: 4),
                              const Icon(
                                Icons.arrow_forward_ios_rounded,
                                size: 10,
                                color: Colors.white70,
                              ),
                            ],
                          ),
                        ),
                      ),

                    const SizedBox(height: 10),

                    // Profil utilisateur
                    GestureDetector(
                      onTap: () => _onProfilePressed(user, shop),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border:
                                  Border.all(color: Colors.white, width: 1.5),
                            ),
                            child: ClipOval(
                              child: user['avatar'] != null &&
                                      user['avatar'].toString().isNotEmpty
                                  ? CachedNetworkImage(
                                      imageUrl: user['avatar'],
                                      fit: BoxFit.cover,
                                      placeholder: (context, url) => Container(
                                        color: AppColors.primary,
                                        child: const Icon(Icons.person,
                                            color: Colors.white, size: 16),
                                      ),
                                      errorWidget: (context, url, error) =>
                                          Container(
                                        color: AppColors.primary,
                                        child: const Icon(Icons.person,
                                            color: Colors.white, size: 16),
                                      ),
                                    )
                                  : Container(
                                      color: AppColors.primary,
                                      child: const Icon(Icons.person,
                                          color: Colors.white, size: 16),
                                    ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '@${toStringSafe(user['name'])}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              shadows: [
                                Shadow(color: Colors.black54, blurRadius: 4),
                              ],
                            ),
                          ),
                          if (user['is_verified'] == true) ...[
                            const SizedBox(width: 4),
                            const Icon(
                              Icons.verified_rounded,
                              size: 14,
                              color: Colors.blue,
                            ),
                          ],
                        ],
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Titre
                    if (title.isNotEmpty)
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          shadows: [
                            Shadow(color: Colors.black54, blurRadius: 6),
                          ],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),

                    const SizedBox(height: 4),

                    // Description avec hashtags
                    if (description.isNotEmpty)
                      _ExpandableDescription(description: description),

                    const SizedBox(height: 10),

                    // Son original
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.black38,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.music_note_rounded,
                            size: 12,
                            color: Colors.white70,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            'Son original · ${toStringSafe(user['name'])}',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Actions droite
            VideoActions(
              video: video,
              isLiked: isLiked,
              isSaved: isSaved,
              onLike: () => _onLikePressed(videoId),
              onComment: () => _onCommentPressed(video),
              onShare: () => _onSharePressed(video),
              onSave: () => _onSavePressed(videoId),
              onProfile: () => _onProfilePressed(user, shop),
              onShop: shop != null ? () => _onShopPressed(shop) : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeartAnimation() {
    return Center(
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: 1.0),
        duration: const Duration(milliseconds: 400),
        curve: Curves.elasticOut,
        builder: (context, value, child) {
          return Transform.scale(
            scale: value,
            child: Opacity(
              opacity: _showHeartAnimation ? 1.0 : 0.0,
              child: const Icon(
                Icons.favorite_rounded,
                color: Colors.white,
                size: 100,
                shadows: [
                  Shadow(
                    color: Colors.red,
                    blurRadius: 20,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildLoadingScreen() {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: AppColors.primaryGradient,
              ),
              child: const Center(
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.5,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Chargement des reels...',
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyScreen() {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: _safePop,
        ),
        title: const Text('Reels', style: TextStyle(color: Colors.white)),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.video_library_rounded,
              size: 80,
              color: Colors.white.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'Aucune vidéo disponible',
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadInitialVideos,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Rafraîchir'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return Container(
      color: Colors.black,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: AppColors.primaryGradient,
              ),
              child: const Center(
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Chargement...',
              style:
                  TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animationController.dispose();
    _heartTimer?.cancel();
    super.dispose();
  }
}

// Widget description extensible
class _ExpandableDescription extends StatefulWidget {
  final String description;
  const _ExpandableDescription({required this.description});

  @override
  State<_ExpandableDescription> createState() =>
      _ExpandableDescriptionState();
}

class _ExpandableDescriptionState extends State<_ExpandableDescription> {
  bool _expanded = false;

  List<String> _extractHashtags(String text) {
    final regex = RegExp(r'#\w+');
    return regex.allMatches(text).map((match) => match.group(0)!).toList();
  }

  String _removeHashtags(String text) {
    return text.replaceAll(RegExp(r'#\w+'), '').trim();
  }

  @override
  Widget build(BuildContext context) {
    final hashtags = _extractHashtags(widget.description);
    final cleanText = _removeHashtags(widget.description);

    return GestureDetector(
      onTap: () => setState(() => _expanded = !_expanded),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (cleanText.isNotEmpty)
            Text(
              cleanText,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                shadows: [
                  Shadow(color: Colors.black54, blurRadius: 4),
                ],
              ),
              maxLines: _expanded ? null : 2,
              overflow: _expanded ? TextOverflow.visible : TextOverflow.ellipsis,
            ),
          if (!_expanded && cleanText.length > 80)
            Text(
              'plus...',
              style: TextStyle(
                color: Colors.white.withOpacity(0.6),
                fontSize: 12,
              ),
            ),
          if (hashtags.isNotEmpty)
            Wrap(
              spacing: 4,
              runSpacing: 2,
              children: hashtags
                  .map(
                    (tag) => Text(
                      tag,
                      style: TextStyle(
                        color: AppColors.primaryLight,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        shadows: const [
                          Shadow(color: Colors.black54, blurRadius: 4),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            ),
        ],
      ),
    );
  }
}

// Bottom sheet de partage
class _ShareSheet extends StatelessWidget {
  final int videoId;
  final String title;
  final VideoApiService apiService;

  const _ShareSheet({
    required this.videoId,
    required this.title,
    required this.apiService,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Partager',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _ShareOption(
                icon: Icons.link_rounded,
                label: 'Copier le lien',
                color: AppColors.primary,
                onTap: () async {
                  try {
                    final result = await apiService.getComments(videoId);
                    final shareUrl =
                        'http://nora.app/reels/$videoId';
                    await Clipboard.setData(
                        ClipboardData(text: shareUrl));
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Lien copié !'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  } catch (e) {
                    Navigator.pop(context);
                  }
                },
              ),
              _ShareOption(
                icon: Icons.message_rounded,
                label: 'WhatsApp',
                color: const Color(0xFF25D366),
                onTap: () => Navigator.pop(context),
              ),
              _ShareOption(
                icon: Icons.facebook_rounded,
                label: 'Facebook',
                color: const Color(0xFF1877F2),
                onTap: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class _ShareOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ShareOption({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
