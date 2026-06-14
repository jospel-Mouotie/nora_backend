import 'package:flutter/material.dart';
import '../../../config/app_colors.dart';

class ChatBubble extends StatelessWidget {
  final String message;
  final bool isMe;
  final DateTime timestamp;
  final bool showAvatar;

  const ChatBubble({
    super.key,
    required this.message,
    required this.isMe,
    required this.timestamp,
    this.showAvatar = true,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isMe && showAvatar)
            CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.primary,
              child: const Icon(Icons.person, size: 16, color: Colors.white),
            ),
          if (!isMe && showAvatar) const SizedBox(width: 8),
          
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isMe ? AppColors.primary : AppColors.backgroundLight,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: isMe ? const Radius.circular(16) : Radius.zero,
                  bottomRight: isMe ? Radius.zero : const Radius.circular(16),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message,
                    style: TextStyle(
                      color: isMe ? Colors.white : AppColors.textPrimary,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatTime(timestamp),
                    style: TextStyle(
                      color: isMe ? Colors.white70 : AppColors.textTertiary,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          if (isMe && showAvatar) const SizedBox(width: 8),
          if (isMe && showAvatar)
            CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.primaryLight,
              child: const Icon(Icons.person, size: 16, color: Colors.white),
            ),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}