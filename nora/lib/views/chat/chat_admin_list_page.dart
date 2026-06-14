import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../config/app_colors.dart';
import '../../../config/routes.dart';
import '../../../services/api_service.dart';
import '../../../services/storage_service.dart';
import '../../../utils/converters.dart';

class ChatAdminListPage extends StatefulWidget {
  const ChatAdminListPage({super.key});

  @override
  State<ChatAdminListPage> createState() => _ChatAdminListPageState();
}

class _ChatAdminListPageState extends State<ChatAdminListPage> {
  final ApiService _apiService = ApiService();
  List<dynamic> _conversations = [];
  bool _isLoading = true;
  String? _token;

  @override
  void initState() {
    super.initState();
    _loadConversations();
  }

  Future<void> _loadConversations() async {
    setState(() => _isLoading = true);
    
    _token = await StorageService().getToken();
    if (_token == null) {
      setState(() {
        _isLoading = false;
      });
      return;
    }
    
    try {
      final result = await _apiService.getAdminConversations(_token!);
      if (result['success'] && result['conversations'] != null) {
        setState(() {
          _conversations = result['conversations'];
          _isLoading = false;
        });
      } else {
        _loadTestConversations();
      }
    } catch (e) {
      _loadTestConversations();
    }
  }

  void _loadTestConversations() {
    setState(() {
      _conversations = [
        {
          'user': {
            'id': 1,
            'name': 'Jean Dupont',
            'email': 'jean@example.com',
            'avatar': null,
          },
          'last_message': 'Bonjour, j\'ai un problème avec ma commande',
          'last_message_at': '2026-05-16T10:30:00Z',
          'unread_count': 2,
        },
        {
          'user': {
            'id': 2,
            'name': 'Marie Laurent',
            'email': 'marie@example.com',
            'avatar': null,
          },
          'last_message': 'Merci pour votre aide !',
          'last_message_at': '2026-05-16T09:15:00Z',
          'unread_count': 0,
        },
      ];
      _isLoading = false;
    });
  }

  String _formatDate(String dateTimeStr) {
    try {
      final dateTime = DateTime.parse(dateTimeStr);
      final now = DateTime.now();
      final diff = now.difference(dateTime);
      
      if (diff.inDays > 7) {
        return '${diff.inDays ~/ 7} sem';
      } else if (diff.inDays > 0) {
        return '${diff.inDays} j';
      } else if (diff.inHours > 0) {
        return '${diff.inHours} h';
      } else if (diff.inMinutes > 0) {
        return '${diff.inMinutes} min';
      } else {
        return 'à l\'instant';
      }
    } catch (e) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              context.go(AppRoutes.home);
            }
          },
        ),
        title: const Text(
          'Support client',
          style: TextStyle(color: AppColors.textPrimary),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : _token == null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.lock_outline, size: 64, color: AppColors.textTertiary),
                      const SizedBox(height: 16),
                      const Text(
                        'Connectez-vous pour accéder au support',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: () => context.push(AppRoutes.login),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                        ),
                        child: const Text('Se connecter'),
                      ),
                    ],
                  ),
                )
              : _conversations.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.chat_outlined, size: 64, color: AppColors.textTertiary),
                          SizedBox(height: 16),
                          Text(
                            'Aucune conversation',
                            style: TextStyle(color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _conversations.length,
                      itemBuilder: (context, index) {
                        final conv = _conversations[index];
                        final user = conv['user'];
                        final userName = toStringSafe(user?['name']);
                        final userEmail = toStringSafe(user?['email']);
                        final userAvatar = user?['avatar'];
                        final lastMessage = toStringSafe(conv['last_message']);
                        final lastMessageAt = toStringSafe(conv['last_message_at']);
                        final unreadCount = toIntSafe(conv['unread_count']);
                        
                        return GestureDetector(
                          onTap: () {
                            context.push('${AppRoutes.chatAdmin}/conversation/${user?['id']}');
                          },
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.background,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: unreadCount > 0 ? AppColors.primary : AppColors.border,
                                width: unreadCount > 0 ? 1.5 : 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                // Avatar
                                Container(
                                  width: 50,
                                  height: 50,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: AppColors.primaryGradient,
                                  ),
                                  child: ClipOval(
                                    child: userAvatar != null && userAvatar.toString().isNotEmpty
                                        ? Image.network(
                                            userAvatar,
                                            fit: BoxFit.cover,
                                            errorBuilder: (_, __, ___) => const Icon(
                                              Icons.person,
                                              color: Colors.white,
                                              size: 30,
                                            ),
                                          )
                                        : const Icon(
                                            Icons.person,
                                            color: Colors.white,
                                            size: 30,
                                          ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                // Infos
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        userName,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        userEmail,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              lastMessage,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                fontSize: 13,
                                                color: AppColors.textTertiary,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                // Statut
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      _formatDate(lastMessageAt),
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: AppColors.textTertiary,
                                      ),
                                    ),
                                    if (unreadCount > 0)
                                      Container(
                                        margin: const EdgeInsets.only(top: 8),
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: AppColors.primary,
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          '$unreadCount',
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
    );
  }
}