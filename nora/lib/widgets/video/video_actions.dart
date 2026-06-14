import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../config/app_colors.dart';
import '../../../utils/converters.dart';

class VideoActions extends StatelessWidget {
  final Map<String, dynamic> video;
  final bool isLiked;
  final bool isSaved;
  final VoidCallback onLike;
  final VoidCallback onComment;
  final VoidCallback onShare;
  final VoidCallback onSave;
  final VoidCallback onProfile;
  final VoidCallback? onShop;

  const VideoActions({
    super.key,
    required this.video,
    required this.isLiked,
    required this.isSaved,
    required this.onLike,
    required this.onComment,
    required this.onShare,
    required this.onSave,
    required this.onProfile,
    this.onShop,
  });

  @override
  Widget build(BuildContext context) {
    final likesCount = toIntSafe(video['likes_count']);
    final commentsCount = toIntSafe(video['comments_count']);
    final userAvatar = video['user']?['avatar'];
    final userName = toStringSafe(video['user']?['name']);
    final shop = video['shop'];
    final hasShop = shop != null && shop['id'] != null;

    return Padding(
      padding: const EdgeInsets.only(right: 12, bottom: 80),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // Avatar du profil
          _AvatarButton(
            userAvatar: userAvatar,
            onTap: onProfile,
          ),

          const SizedBox(height: 8),

          // Nom (petit)
          Text(
            userName.length > 10 ? '${userName.substring(0, 10)}...' : userName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),

          const SizedBox(height: 24),

          // Like (animé)
          _LikeButton(
            isLiked: isLiked,
            likesCount: likesCount,
            onLike: () {
              HapticFeedback.lightImpact();
              onLike();
            },
          ),

          const SizedBox(height: 20),

          // Commentaire
          _buildActionButton(
            icon: Icons.chat_bubble_rounded,
            color: Colors.white,
            count: commentsCount,
            onTap: onComment,
          ),

          const SizedBox(height: 20),

          // Partager
          _buildActionButton(
            icon: Icons.share_rounded,
            color: Colors.white,
            count: null,
            onTap: onShare,
          ),

          const SizedBox(height: 20),

          // Sauvegarder
          _buildActionButton(
            icon: isSaved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
            color: isSaved ? AppColors.primary : Colors.white,
            count: null,
            onTap: () {
              HapticFeedback.selectionClick();
              onSave();
            },
          ),

          // Boutique (si disponible)
          if (hasShop && onShop != null) ...[
            const SizedBox(height: 20),
            _buildShopButton(shop, onShop!),
          ],
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required int? count,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.black26,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 26),
          ),
          if (count != null) ...[
            const SizedBox(height: 4),
            Text(
              _formatCount(count),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                shadows: [
                  Shadow(color: Colors.black54, blurRadius: 4),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildShopButton(Map<String, dynamic> shop, VoidCallback onTap) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        onTap();
      },
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.4),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: const Icon(Icons.storefront_rounded, color: Colors.white, size: 24),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.8),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              'Boutique',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 9,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
              ),
            ),
          ),
        ],
      ),
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

// Widget animé pour le bouton Like
class _LikeButton extends StatefulWidget {
  final bool isLiked;
  final int likesCount;
  final VoidCallback onLike;

  const _LikeButton({
    required this.isLiked,
    required this.likesCount,
    required this.onLike,
  });

  @override
  State<_LikeButton> createState() => _LikeButtonState();
}

class _LikeButtonState extends State<_LikeButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.35), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.35, end: 1.0), weight: 50),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTap() {
    _controller.forward(from: 0);
    widget.onLike();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleTap,
      child: Column(
        children: [
          AnimatedBuilder(
            animation: _scaleAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _scaleAnimation.value,
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: widget.isLiked
                        ? Colors.red.withOpacity(0.2)
                        : Colors.black26,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    widget.isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                    color: widget.isLiked ? Colors.red : Colors.white,
                    size: 26,
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 4),
          Text(
            _formatCount(widget.likesCount),
            style: TextStyle(
              color: widget.isLiked ? Colors.red : Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              shadows: const [
                Shadow(color: Colors.black54, blurRadius: 4),
              ],
            ),
          ),
        ],
      ),
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

// Widget Avatar avec badge "+"
class _AvatarButton extends StatelessWidget {
  final dynamic userAvatar;
  final VoidCallback onTap;

  const _AvatarButton({required this.userAvatar, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
            ),
            child: ClipOval(
              child: userAvatar != null && userAvatar.toString().isNotEmpty
                  ? Image.network(
                      userAvatar,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: AppColors.primary,
                        child: const Icon(Icons.person, color: Colors.white, size: 24),
                      ),
                    )
                  : Container(
                      color: AppColors.primary,
                      child: const Icon(Icons.person, color: Colors.white, size: 24),
                    ),
            ),
          ),
          Positioned(
            bottom: -4,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.black, width: 1),
                ),
                child: const Icon(Icons.add, color: Colors.white, size: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}