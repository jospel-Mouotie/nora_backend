import 'package:flutter/material.dart';
import '../../../config/app_colors.dart';
import '../../../services/video_api_service.dart';
import '../../../services/storage_service.dart';
import '../../../utils/converters.dart';

class CommentSheet extends StatefulWidget {
  final int videoId;
  final int commentsCount;
  final void Function(int newCount)? onCountChanged;

  const CommentSheet({
    super.key,
    required this.videoId,
    required this.commentsCount,
    this.onCountChanged,
  });

  @override
  State<CommentSheet> createState() => _CommentSheetState();
}

class _CommentSheetState extends State<CommentSheet> {
  final VideoApiService _videoApiService = VideoApiService();
  final TextEditingController _commentController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();

  List<Map<String, dynamic>> _comments = [];
  bool _isLoading = true;
  bool _isSending = false;
  String? _token;
  int _totalCount = 0;

  @override
  void initState() {
    super.initState();
    _totalCount = widget.commentsCount;
    _loadToken();
    _loadComments();
  }

  @override
  void dispose() {
    _commentController.dispose();
    _focusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadToken() async {
    _token = await StorageService().getToken();
    if (mounted) setState(() {});
  }

  Future<void> _loadComments() async {
    setState(() => _isLoading = true);

    try {
      final result = await _videoApiService.getComments(widget.videoId);
      if (result['success']) {
        final raw = result['comments'];
        List<Map<String, dynamic>> list = [];
        if (raw is List) {
          list = raw.map((c) => Map<String, dynamic>.from(c)).toList();
        } else if (raw is Map && raw['data'] is List) {
          list = (raw['data'] as List)
              .map((c) => Map<String, dynamic>.from(c))
              .toList();
        }
        if (mounted) {
          setState(() {
            _comments = list;
            _isLoading = false;
          });
        }
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint('Erreur chargement commentaires: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _sendComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;

    if (_token == null) {
      _showError('Connectez-vous pour commenter');
      return;
    }

    setState(() => _isSending = true);
    _focusNode.unfocus();

    try {
      final result = await _videoApiService.addComment(
        widget.videoId,
        text,
        _token!,
      );

      if (result['success']) {
        _commentController.clear();
        setState(() {
          _totalCount++;
        });
        widget.onCountChanged?.call(_totalCount);
        await _loadComments();
        // Scroll to top to see new comment
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            0,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      } else {
        _showError(result['message'] ?? 'Erreur lors de l\'envoi');
      }
    } catch (e) {
      _showError('Erreur de connexion');
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String _formatDate(String? dateTimeStr) {
    if (dateTimeStr == null) return 'récemment';
    final dateTime = DateTime.tryParse(dateTimeStr);
    if (dateTime == null) return 'récemment';

    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 30) {
      return '${difference.inDays ~/ 30} mois';
    } else if (difference.inDays > 7) {
      return '${difference.inDays ~/ 7} sem';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} j';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} h';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} min';
    } else {
      return 'à l\'instant';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.78,
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 4),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.chat_bubble_rounded,
                          size: 16, color: AppColors.primary),
                      const SizedBox(width: 6),
                      Text(
                        '$_totalCount commentaires',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close_rounded,
                      color: AppColors.textSecondary),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          Divider(height: 0, color: AppColors.border.withOpacity(0.5)),

          // Liste des commentaires
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  )
                : _comments.isEmpty
                    ? _buildEmptyState()
                    : ListView.separated(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        itemCount: _comments.length,
                        separatorBuilder: (_, __) => Divider(
                          height: 16,
                          color: AppColors.border.withOpacity(0.3),
                        ),
                        itemBuilder: (context, index) {
                          final comment = _comments[index];
                          return _buildCommentItem(comment);
                        },
                      ),
          ),

          // Zone de saisie
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline_rounded,
            size: 56,
            color: AppColors.textTertiary,
          ),
          const SizedBox(height: 12),
          const Text(
            'Aucun commentaire',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Soyez le premier à commenter !',
            style: TextStyle(
              color: AppColors.textTertiary,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 12,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      decoration: BoxDecoration(
        color: AppColors.background,
        border: Border(
          top: BorderSide(color: AppColors.border.withOpacity(0.5)),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar utilisateur (placeholder)
          CircleAvatar(
            radius: 18,
            backgroundColor: AppColors.primary.withOpacity(0.15),
            child: Icon(Icons.person_rounded,
                color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: _commentController,
              focusNode: _focusNode,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14,
              ),
              decoration: InputDecoration(
                hintText: _token != null
                    ? 'Ajouter un commentaire...'
                    : 'Connectez-vous pour commenter',
                hintStyle:
                    TextStyle(color: AppColors.textTertiary, fontSize: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: AppColors.backgroundLight,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
              ),
              enabled: _token != null,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _sendComment(),
            ),
          ),
          const SizedBox(width: 10),
          _isSending
              ? const SizedBox(
                  width: 36,
                  height: 36,
                  child: Center(
                    child: SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                )
              : GestureDetector(
                  onTap: _sendComment,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.send_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
        ],
      ),
    );
  }

  Widget _buildCommentItem(Map<String, dynamic> comment) {
    final user = comment['user'];
    final userName = toStringSafe(user?['name']);
    final avatar = user?['avatar'];
    final content = toStringSafe(comment['content']);
    final createdAt = comment['created_at']?.toString();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Avatar
        CircleAvatar(
          radius: 18,
          backgroundColor: AppColors.primary,
          backgroundImage: avatar != null && avatar.toString().isNotEmpty
              ? NetworkImage(avatar)
              : null,
          child: (avatar == null || avatar.toString().isEmpty)
              ? Text(
                  userName.isNotEmpty ? userName[0].toUpperCase() : '?',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                )
              : null,
        ),
        const SizedBox(width: 10),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Name + Date
              Row(
                children: [
                  Text(
                    userName.isNotEmpty ? userName : 'Utilisateur',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _formatDate(createdAt),
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.textTertiary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),

              // Contenu
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppColors.backgroundLight,
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(16),
                    bottomLeft: Radius.circular(16),
                    bottomRight: Radius.circular(16),
                  ),
                ),
                child: Text(
                  content,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textPrimary,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}