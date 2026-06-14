import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../config/app_colors.dart';
import '../../../config/app_constants.dart';
import '../../../config/routes.dart';
import '../../../services/video_api_service.dart';
import '../../../services/user_api_service.dart';
import '../../../services/storage_service.dart';
import '../../../widgets/custom_app_bar.dart';
import '../../../utils/converters.dart';
import 'video_upload_page.dart';
import 'reels_feed_page.dart';

class VideoFeedPage extends StatefulWidget {
  final String? videoId;

  const VideoFeedPage({super.key, this.videoId});

  @override
  State<VideoFeedPage> createState() => _VideoFeedPageState();
}

class _VideoFeedPageState extends State<VideoFeedPage> with SingleTickerProviderStateMixin {
  final VideoApiService _videoApiService = VideoApiService();
  final UserApiService _userApiService = UserApiService();
  late TabController _tabController;
  
  List<dynamic> _videos = [];
  List<dynamic> _myVideos = [];
  bool _isLoading = true;
  String? _token;
  String? _userRole;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    _token = await StorageService().getToken();
    
    // Charger le rôle de l'utilisateur
    if (_token != null) {
      try {
        final result = await _userApiService.getUserProfile(_token!);
        if (result['success'] && result['user'] != null) {
          setState(() {
            _userRole = result['user']['role'];
          });
        }
      } catch (e) {
        print('Erreur chargement rôle: $e');
      }
    }

    try {
      await Future.wait([
        _loadVideos(),
        if (_token != null) _loadMyVideos(),
      ]);
      
      // Scroller jusqu'à la vidéo spécifiée si videoId est fourni
      if (widget.videoId != null && widget.videoId!.isNotEmpty) {
        _scrollToVideo(widget.videoId!);
      }
    } catch (e) {
      print('Erreur chargement vidéos: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _scrollToVideo(String videoId) {
    final index = _videos.indexWhere((v) => v['id'].toString() == videoId);
    if (index != -1 && _scrollController.hasClients) {
      // Calculer la position pour scroller jusqu'à la vidéo
      final itemHeight = 300.0; // Hauteur approximative d'un item dans la grille
      final crossAxisCount = 2;
      final itemsPerRow = crossAxisCount;
      final rowIndex = (index / itemsPerRow).floor();
      final scrollPosition = rowIndex * itemHeight;
      
      _scrollController.animateTo(
        scrollPosition,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _loadVideos() async {
    try {
      final result = await _videoApiService.getVideos(limit: 20);
      if (result['success'] && result['videos'] != null) {
        setState(() {
          _videos = result['videos'];
        });
      }
    } catch (e) {
      print('Erreur vidéos: $e');
    }
  }

  Future<void> _loadMyVideos() async {
    if (_token == null) return;
    try {
      final result = await _videoApiService.getMyVideos(_token!);
      if (result['success'] && result['videos'] != null) {
        setState(() {
          _myVideos = result['videos'];
        });
      }
    } catch (e) {
      print('Erreur mes vidéos: $e');
    }
  }

  void _onVideoTap(Map<String, dynamic> video) {
    // Trouver l'index de la vidéo dans la liste
    final index = _videos.indexWhere((v) => v['id'] == video['id']);
    // Ouvrir le mode Reels directement (TikTok-style)
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ReelsFeedPage(),
      ),
    ).then((_) => _loadData());
  }

  void _onAddVideo() {
    if (_token == null) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Connexion requise'),
          content: const Text('Connectez-vous pour ajouter une vidéo'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                context.push(AppRoutes.login);
              },
              child: const Text('Se connecter'),
            ),
          ],
        ),
      );
      return;
    }

    // Vérifier si l'utilisateur est un client (limite de 1 vidéo par semaine)
    if (_userRole == 'client') {
      // La validation sera faite côté backend, mais on peut afficher un message informatif
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Ajouter une vidéo'),
          content: const Text('En tant que client, vous pouvez ajouter 1 vidéo par semaine.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const VideoUploadPage()),
                ).then((_) => _loadData());
              },
              child: const Text('Continuer'),
            ),
          ],
        ),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const VideoUploadPage()),
      ).then((_) => _loadData());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: CustomAppBar(
        showLogo: false,
        showBackButton: false,
        title: 'Vidéos',
        actions: [
          if (_userRole == 'client' || _userRole == 'commercant' || _userRole == 'grossiste' || _userRole == 'admin')
            IconButton(
              icon: const Icon(Icons.add_circle_outline, color: AppColors.primary, size: 28),
              onPressed: _onAddVideo,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : Column(
              children: [
                TabBar(
                  controller: _tabController,
                  indicatorColor: AppColors.primary,
                  labelColor: AppColors.primary,
                  unselectedLabelColor: AppColors.textSecondary,
                  tabs: const [
                    Tab(text: 'Toutes les vidéos'),
                    Tab(text: 'Mes vidéos'),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildVideosGrid(_videos),
                      _buildVideosGrid(_myVideos, showEmptyMessage: true),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildVideosGrid(List<dynamic> videos, {bool showEmptyMessage = false}) {
    if (videos.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              showEmptyMessage ? Icons.video_library_outlined : Icons.videocam_off_outlined,
              size: 64,
              color: AppColors.textTertiary,
            ),
            const SizedBox(height: 16),
            Text(
              showEmptyMessage ? 'Vous n\'avez pas encore de vidéos' : 'Aucune vidéo disponible',
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            if (showEmptyMessage) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _onAddVideo,
                icon: const Icon(Icons.add),
                label: const Text('Ajouter ma première vidéo'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                ),
              ),
            ],
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.75,
      ),
      itemCount: videos.length,
      itemBuilder: (context, index) {
        final video = videos[index];
        return _buildVideoCard(video);
      },
    );
  }

  Widget _buildVideoCard(Map<String, dynamic> video) {
    final thumbnail = video['thumbnail_path'] ?? video['thumbnail_url'];
    final title = toStringSafe(video['title']);
    final views = toIntSafe(video['views_count'] ?? video['views'] ?? 0);

    return GestureDetector(
      onTap: () => _onVideoTap(video),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.backgroundLight,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                children: [
                  Positioned.fill(
                    child: thumbnail != null && thumbnail.toString().isNotEmpty
                        ? ClipRRect(
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                            child: CachedNetworkImage(
                              imageUrl: _getFullImageUrl(thumbnail),
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Container(
                                color: AppColors.backgroundLight,
                                child: const Center(
                                  child: CircularProgressIndicator(color: AppColors.primary),
                                ),
                              ),
                              errorWidget: (context, url, error) => Container(
                                color: AppColors.backgroundLight,
                                child: const Center(
                                  child: Icon(Icons.videocam_off, color: AppColors.textTertiary),
                                ),
                              ),
                            ),
                          )
                        : Container(
                            color: AppColors.backgroundLight,
                            child: const Center(
                              child: Icon(Icons.videocam_off, color: AppColors.textTertiary),
                            ),
                          ),
                  ),
                  const Center(
                    child: Icon(
                      Icons.play_circle_outline,
                      size: 48,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.visibility_outlined, size: 12, color: AppColors.textTertiary),
                      const SizedBox(width: 4),
                      Text(
                        '$views vues',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textTertiary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getFullImageUrl(String? path) {
    if (path == null || path.isEmpty) return '';
    if (path.startsWith('http')) return path;
    if (path.startsWith('/storage')) {
      return '${AppConstants.apiBaseUrl.replaceAll('/api', '')}$path';
    }
    return '${AppConstants.apiBaseUrl.replaceAll('/api', '')}/storage/$path';
  }
}
