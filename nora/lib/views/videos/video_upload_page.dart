import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';
import '../../../config/app_colors.dart';
import '../../../services/video_api_service.dart';
import '../../../services/storage_service.dart';
import '../../../config/routes.dart';

class VideoUploadPage extends StatefulWidget {
  final Map<String, dynamic>? videoToEdit;

  const VideoUploadPage({super.key, this.videoToEdit});

  @override
  State<VideoUploadPage> createState() => _VideoUploadPageState();
}

class _VideoUploadPageState extends State<VideoUploadPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final VideoApiService _videoApiService = VideoApiService();
  final ImagePicker _picker = ImagePicker();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  File? _videoFile;
  File? _thumbnailFile;
  VideoPlayerController? _videoController;
  bool _isUploading = false;
  double _uploadProgress = 0;
  String? _uploadStatusMessage;

  bool _needsTrimming = false;
  double _trimStart = 0.0;
  double _trimEnd = 0.0;

  List<dynamic> _myVideos = [];
  bool _isVideosLoading = false;

  // Paramètres de publication
  bool _isPublic = true;
  bool _allowComments = true;
  bool _allowDownloads = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    
    // Si on est en mode édition, charger les données de la vidéo
    if (widget.videoToEdit != null) {
      _titleController.text = widget.videoToEdit!['title'] ?? '';
      _descriptionController.text = widget.videoToEdit!['description'] ?? '';
      _isPublic = widget.videoToEdit!['is_public'] ?? true;
      _allowComments = widget.videoToEdit!['allow_comments'] ?? true;
      _allowDownloads = widget.videoToEdit!['allow_downloads'] ?? false;
    }
    
    _loadMyVideos();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  void _safePop() {
    if (Navigator.of(context).canPop()) {
      context.pop();
    } else {
      context.go('/home');
    }
  }

  Future<void> _loadMyVideos() async {
    setState(() => _isVideosLoading = true);
    final token = await StorageService().getToken();
    if (token == null) {
      setState(() => _isVideosLoading = false);
      return;
    }
    try {
      final result = await _videoApiService.getMyVideos(token);
      if (result['success'] && result['videos'] != null) {
        setState(() => _myVideos = result['videos']);
      }
    } catch (e) {
      debugPrint('Erreur chargement vidéos: $e');
    } finally {
      if (mounted) setState(() => _isVideosLoading = false);
    }
  }

  Future<void> _pickVideo() async {
    final XFile? video = await _picker.pickVideo(
      source: ImageSource.gallery,
      maxDuration: const Duration(minutes: 10),
    );
    if (video != null) {
      final file = File(video.path);
      final sizeBytes = await file.length();
      final sizeMb = sizeBytes / (1024 * 1024);

      if (sizeMb > 500) {
        _showSnackBar('La vidéo dépasse 500 Mo. Veuillez choisir une vidéo plus courte.');
        return;
      }

      setState(() {
        _videoFile = file;
        _uploadStatusMessage = null;
        _needsTrimming = false;
        _trimStart = 0.0;
        _trimEnd = 0.0;
      });

      await _initializeVideoController(video.path);
    }
  }

  Future<void> _pickThumbnail() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1280,
      maxHeight: 720,
      imageQuality: 85,
    );
    if (image != null) {
      setState(() => _thumbnailFile = File(image.path));
    }
  }

  Future<void> _initializeVideoController(String videoPath) async {
    _videoController?.dispose();
    try {
      final controller = VideoPlayerController.file(File(videoPath));
      await controller.initialize();
      if (mounted) {
        final duration = controller.value.duration.inSeconds.toDouble();
        setState(() {
          _videoController = controller;
          if (duration > 60.0) {
            _needsTrimming = true;
            _trimStart = 0.0;
            _trimEnd = 60.0;
          } else {
            _needsTrimming = false;
            _trimStart = 0.0;
            _trimEnd = duration;
          }
        });

        controller.addListener(() {
          if (!mounted) return;
          if (_needsTrimming && _videoController != null && _videoController!.value.isPlaying) {
            final currentPos = _videoController!.value.position.inMilliseconds / 1000.0;
            if (currentPos >= _trimEnd || currentPos < _trimStart) {
              _videoController!.seekTo(Duration(milliseconds: (_trimStart * 1000).toInt()));
            }
          }
        });
      } else {
        controller.dispose();
      }
    } catch (e) {
      debugPrint('Erreur initialisation vidéo: $e');
    }
  }

  Future<void> _uploadVideo() async {
    if (_videoFile == null) {
      _showSnackBar('Sélectionnez une vidéo d\'abord');
      return;
    }

    if (_titleController.text.trim().isEmpty) {
      _showSnackBar('Ajoutez un titre');
      return;
    }

    final token = await StorageService().getToken();
    if (token == null) {
      _showSnackBar('Connectez-vous pour uploader');
      context.go('/login');
      return;
    }

    if (!mounted) return;

    setState(() {
      _isUploading = true;
      _uploadProgress = 0;
      _uploadStatusMessage = 'Envoi de la vidéo en cours...';
    });

    // Simuler la progression pendant l'upload
    _simulateProgress();

    try {
      final result = await _videoApiService.uploadVideo(
        videoFile: _videoFile!,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        isPublic: _isPublic,
        allowComments: _allowComments,
        allowDownloads: _allowDownloads,
        token: token,
        thumbnail: _thumbnailFile,
        trimStart: _needsTrimming ? _trimStart : null,
        trimEnd: _needsTrimming ? _trimEnd : null,
      );

      if (mounted) {
        if (result['success']) {
          setState(() {
            _uploadProgress = 1.0;
            _uploadStatusMessage = 'Vidéo publiée avec succès !';
          });

          await Future.delayed(const Duration(seconds: 1));

          _showSnackBar('Vidéo publiée avec succès !', isSuccess: true);
          _titleController.clear();
          _descriptionController.clear();
          setState(() {
            _videoFile = null;
            _thumbnailFile = null;
            _uploadStatusMessage = null;
          });
          _videoController?.dispose();
          _videoController = null;
          await _loadMyVideos();
          _tabController.animateTo(1);
        } else {
          setState(() => _uploadStatusMessage = null);
          _showSnackBar(result['message'] ?? 'Erreur lors de l\'upload');
        }
      }
    } catch (e) {
      debugPrint('Erreur upload: $e');
      if (mounted) {
        setState(() => _uploadStatusMessage = null);
        _showSnackBar('Erreur: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  Future<void> _updateVideo() async {
    if (widget.videoToEdit == null) {
      _showSnackBar('Aucune vidéo à modifier');
      return;
    }

    if (_titleController.text.trim().isEmpty) {
      _showSnackBar('Ajoutez un titre');
      return;
    }

    final token = await StorageService().getToken();
    if (token == null) {
      _showSnackBar('Connectez-vous pour modifier');
      context.go('/login');
      return;
    }

    if (!mounted) return;

    setState(() {
      _isUploading = true;
      _uploadProgress = 0;
      _uploadStatusMessage = 'Mise à jour de la vidéo en cours...';
    });

    // Simuler la progression pendant la mise à jour
    _simulateProgress();

    try {
      final result = await _videoApiService.updateVideo(
        videoId: widget.videoToEdit!['id'],
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        isPublic: _isPublic,
        allowComments: _allowComments,
        allowDownloads: _allowDownloads,
        token: token,
        thumbnail: _thumbnailFile,
      );

      if (mounted) {
        if (result['success']) {
          setState(() {
            _uploadProgress = 1.0;
            _uploadStatusMessage = 'Vidéo mise à jour avec succès !';
          });

          await Future.delayed(const Duration(seconds: 1));

          _showSnackBar('Vidéo mise à jour avec succès !', isSuccess: true);
          setState(() {
            _thumbnailFile = null;
            _uploadStatusMessage = null;
          });
          await _loadMyVideos();
          _safePop();
        } else {
          setState(() => _uploadStatusMessage = null);
          _showSnackBar(result['message'] ?? 'Erreur lors de la mise à jour');
        }
      }
    } catch (e) {
      debugPrint('Erreur update: $e');
      if (mounted) {
        setState(() => _uploadStatusMessage = null);
        _showSnackBar('Erreur: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  void _simulateProgress() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(milliseconds: 300));
      if (!mounted || !_isUploading) return false;
      if (_uploadProgress >= 0.92) return false;
      setState(() => _uploadProgress += 0.04);
      return true;
    });
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
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final token = await StorageService().getToken();
    if (token == null) return;

    try {
      final result = await _videoApiService.deleteVideo(videoId, token);
      if (result['success']) {
        _showSnackBar('Vidéo supprimée', isSuccess: true);
        _loadMyVideos();
      } else {
        _showSnackBar(result['message'] ?? 'Erreur de suppression');
      }
    } catch (e) {
      _showSnackBar('Erreur lors de la suppression');
    }
  }

  void _showSnackBar(String message, {bool isSuccess = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isSuccess ? AppColors.success : AppColors.error,
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: isSuccess ? 2 : 4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(widget.videoToEdit != null ? 'Modifier la vidéo' : 'Vidéos'),
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: _safePop,
        ),
        bottom: widget.videoToEdit != null
            ? null
            : TabBar(
                controller: _tabController,
                labelColor: AppColors.primary,
                unselectedLabelColor: AppColors.textSecondary,
                indicatorColor: AppColors.primary,
                tabs: const [
                  Tab(text: 'Nouvelle vidéo', icon: Icon(Icons.video_call)),
                  Tab(text: 'Mes publications', icon: Icon(Icons.video_library)),
                ],
              ),
      ),
      body: widget.videoToEdit != null
          ? _buildUploadFormTab()
          : TabBarView(
              controller: _tabController,
              children: [
                _buildUploadFormTab(),
                _buildPublicationsTab(),
              ],
            ),
    );
  }

  Widget _buildUploadFormTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Sélection vidéo (caché en mode édition)
          if (widget.videoToEdit == null) ...[
            GestureDetector(
              onTap: _isUploading ? null : _pickVideo,
              child: Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.backgroundLight,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _videoFile != null ? AppColors.primary : AppColors.border,
                    width: _videoFile != null ? 2 : 1,
                  ),
                ),
                child: _buildPreviewWidget(),
              ),
            ),

            if (_videoFile != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.check_circle, color: AppColors.success, size: 16),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      _videoFile!.path.split('/').last,
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  TextButton(
                    onPressed: _isUploading ? null : () {
                      setState(() {
                        _videoFile = null;
                        _videoController?.dispose();
                        _videoController = null;
                        _needsTrimming = false;
                        _trimStart = 0.0;
                        _trimEnd = 0.0;
                      });
                    },
                    child: const Text('Changer', style: TextStyle(fontSize: 12)),
                  ),
                ],
              ),
            ],
          ] else ...[
            if (_needsTrimming && _videoController != null && _videoController!.value.isInitialized) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.backgroundLight,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.cut, color: AppColors.primary, size: 16),
                        const SizedBox(width: 8),
                        const Text(
                          'Sélectionnez un extrait (Max 1 min)',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary),
                        ),
                        const Spacer(),
                        Text(
                          'Durée: ${(_trimEnd - _trimStart).toStringAsFixed(1)}s',
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: AppColors.primary),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    RangeSlider(
                      values: RangeValues(_trimStart, _trimEnd),
                      min: 0.0,
                      max: _videoController!.value.duration.inSeconds.toDouble(),
                      divisions: _videoController!.value.duration.inSeconds > 0
                          ? _videoController!.value.duration.inSeconds
                          : 1,
                      activeColor: AppColors.primary,
                      inactiveColor: AppColors.border,
                      labels: RangeLabels(
                        _formatDuration(_trimStart.toInt()),
                        _formatDuration(_trimEnd.toInt()),
                      ),
                      onChanged: (RangeValues values) {
                        double start = values.start;
                        double end = values.end;
                        if (end - start > 60.0) {
                          if (start != _trimStart) {
                            end = start + 60.0;
                          } else {
                            start = end - 60.0;
                          }
                        }
                        setState(() {
                          _trimStart = start;
                          _trimEnd = end;
                        });
                        _videoController?.seekTo(Duration(milliseconds: (start * 1000).toInt()));
                      },
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Début: ${_formatDuration(_trimStart.toInt())}',
                          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                        ),
                        Text(
                          'Fin: ${_formatDuration(_trimEnd.toInt())}',
                          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
            // Afficher la miniature de la vidéo existante en mode édition
            if (widget.videoToEdit!['thumbnail_url'] != null)
              Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.backgroundLight,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    widget.videoToEdit!['thumbnail_url'],
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: AppColors.backgroundLight,
                      child: const Icon(Icons.video_library, size: 40, color: AppColors.primary),
                    ),
                  ),
                ),
              ),
          ],

          const SizedBox(height: 16),

          // Miniature personnalisée
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _isUploading ? null : _pickThumbnail,
                  icon: const Icon(Icons.image, size: 18),
                  label: Text(
                    _thumbnailFile != null ? 'Miniature sélectionnée ✓' : 'Choisir une miniature',
                    style: const TextStyle(fontSize: 13),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _thumbnailFile != null ? AppColors.success : AppColors.primary,
                    side: BorderSide(
                      color: _thumbnailFile != null ? AppColors.success : AppColors.border,
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Titre
          TextField(
            controller: _titleController,
            enabled: !_isUploading,
            decoration: const InputDecoration(
              labelText: 'Titre *',
              hintText: 'Donnez un titre à votre vidéo',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.title),
            ),
          ),

          const SizedBox(height: 12),

          // Description
          TextField(
            controller: _descriptionController,
            enabled: !_isUploading,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Description',
              hintText: 'Décrivez votre vidéo, ajoutez des #hashtags',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.description),
              alignLabelWithHint: true,
            ),
          ),

          const SizedBox(height: 16),

          // Options de publication
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.backgroundLight,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Options de publication',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  title: const Text('Vidéo publique', style: TextStyle(fontSize: 14)),
                  subtitle: const Text('Visible par tous les utilisateurs', style: TextStyle(fontSize: 12)),
                  value: _isPublic,
                  onChanged: _isUploading ? null : (v) => setState(() => _isPublic = v),
                  activeColor: AppColors.primary,
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                ),
                SwitchListTile(
                  title: const Text('Autoriser les commentaires', style: TextStyle(fontSize: 14)),
                  value: _allowComments,
                  onChanged: _isUploading ? null : (v) => setState(() => _allowComments = v),
                  activeColor: AppColors.primary,
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                ),
                SwitchListTile(
                  title: const Text('Autoriser les téléchargements', style: TextStyle(fontSize: 14)),
                  value: _allowDownloads,
                  onChanged: _isUploading ? null : (v) => setState(() => _allowDownloads = v),
                  activeColor: AppColors.primary,
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Barre de progression
          if (_isUploading) ...[
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _uploadStatusMessage ?? 'Envoi en cours...',
                      style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                    ),
                    Text(
                      '${(_uploadProgress * 100).toInt()}%',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: _uploadProgress,
                    backgroundColor: AppColors.border,
                    valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                    minHeight: 8,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],

          // Bouton publier/modifier
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isUploading
                  ? null
                  : (widget.videoToEdit != null ? _updateVideo : _uploadVideo),
              icon: _isUploading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Icon(Icons.cloud_upload),
              label: Text(
                _isUploading
                    ? (widget.videoToEdit != null ? 'Modification en cours...' : 'Publication en cours...')
                    : (widget.videoToEdit != null ? 'Modifier la vidéo' : 'Publier la vidéo'),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                disabledBackgroundColor: AppColors.textTertiary,
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Info sur les formats acceptés
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.info.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.info.withOpacity(0.3)),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline, size: 16, color: AppColors.info),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Formats: MP4, MOV, AVI · Taille max: 500 Mo · Durée max: 10 min',
                    style: TextStyle(fontSize: 11, color: AppColors.info),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildPublicationsTab() {
    if (_isVideosLoading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }

    if (_myVideos.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.video_library, size: 64, color: AppColors.textTertiary),
            const SizedBox(height: 16),
            const Text(
              'Aucune publication pour le moment',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
            ),
            const SizedBox(height: 8),
            const Text(
              'Vos vidéos publiées apparaîtront ici',
              style: TextStyle(color: AppColors.textTertiary, fontSize: 13),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _tabController.animateTo(0),
              icon: const Icon(Icons.add),
              label: const Text('Publier une vidéo'),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadMyVideos,
      child: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.75,
        ),
        itemCount: _myVideos.length,
        itemBuilder: (context, index) {
          final video = _myVideos[index];
          return _buildVideoCard(video);
        },
      ),
    );
  }

  Widget _buildVideoCard(Map<String, dynamic> video) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Thumbnail
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (video['thumbnail_url'] != null &&
                      video['thumbnail_url'].toString().isNotEmpty)
                    Image.network(
                      video['thumbnail_url'],
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: AppColors.backgroundLight,
                        child: const Icon(Icons.video_library, size: 40, color: AppColors.primary),
                      ),
                    )
                  else
                    Container(
                      color: AppColors.backgroundLight,
                      child: const Icon(Icons.play_circle_outline, size: 40, color: AppColors.primary),
                    ),
                  // Gradient overlay
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Colors.black.withOpacity(0.5)],
                      ),
                    ),
                  ),
                  // Durée
                  Positioned(
                    bottom: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        _formatDuration(video['duration_seconds']),
                        style: const TextStyle(color: Colors.white, fontSize: 10),
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
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
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
                    const SizedBox(width: 8),
                    const Icon(Icons.favorite, size: 12, color: AppColors.textSecondary),
                    const SizedBox(width: 4),
                    Text(
                      '${video['likes_count'] ?? 0}',
                      style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => context.push('${AppRoutes.videoPlayer}/${video['id']}'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'Voir',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    GestureDetector(
                      onTap: () => _deleteVideo(video['id']),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: AppColors.error.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Icon(Icons.delete, size: 16, color: AppColors.error),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(int? seconds) {
    if (seconds == null || seconds == 0) return '00:00';
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  Widget _buildPreviewWidget() {
    if (_videoController != null && _videoController!.value.isInitialized) {
      return Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: _videoController!.value.size.width,
                height: _videoController!.value.size.height,
                child: VideoPlayer(_videoController!),
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: Colors.black26,
            ),
          ),
          Center(
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.8),
                borderRadius: BorderRadius.circular(30),
              ),
              child: const Icon(Icons.play_arrow, color: Colors.white, size: 40),
            ),
          ),
          Positioned(
            bottom: 8,
            left: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                _formatDuration(_videoController!.value.duration.inSeconds),
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
          ),
        ],
      );
    }

    if (_videoFile != null) {
      return Stack(
        children: [
          Center(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.video_file, size: 50, color: AppColors.primary),
            ),
          ),
          const Positioned(
            bottom: 12,
            left: 0,
            right: 0,
            child: Text(
              'Vidéo sélectionnée — aperçu indisponible',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
            ),
          ),
        ],
      );
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.video_call, size: 56, color: AppColors.textTertiary),
        const SizedBox(height: 8),
        const Text(
          'Tapez pour sélectionner une vidéo',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
        ),
        const SizedBox(height: 4),
        const Text(
          'MP4, MOV · max 500 Mo · max 10 min',
          style: TextStyle(color: AppColors.textTertiary, fontSize: 11),
        ),
      ],
    );
  }
}
