import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../config/app_colors.dart';
import '../../../config/routes.dart';
import '../../../services/api_service.dart';
import '../../../services/storage_service.dart';
import '../../../utils/converters.dart';

class ChatAdminConversationPage extends StatefulWidget {
  final int userId;

  const ChatAdminConversationPage({super.key, required this.userId});

  @override
  State<ChatAdminConversationPage> createState() => _ChatAdminConversationPageState();
}

class _ChatAdminConversationPageState extends State<ChatAdminConversationPage> {
  final ApiService _apiService = ApiService();
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _messageController = TextEditingController();
  
  List<Map<String, dynamic>> _messages = [];
  Map<String, dynamic>? _user;
  bool _isLoading = true;
  bool _isSending = false;
  String? _token;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    _token = await StorageService().getToken();
    if (_token == null) {
      setState(() => _isLoading = false);
      return;
    }
    
    try {
      await Future.wait([
        _loadUser(),
        _loadMessages(),
      ]);
    } catch (e) {
      print('Erreur chargement: $e');
      _loadTestData();
    } finally {
      setState(() => _isLoading = false);
    }
    _scrollToBottom();
  }

  Future<void> _loadUser() async {
    try {
      final result = await _apiService.getUserById(widget.userId, _token!);
      if (result['success'] && result['user'] != null) {
        setState(() {
          _user = result['user'];
        });
      } else {
        _user = {
          'id': widget.userId,
          'name': 'Utilisateur ${widget.userId}',
          'email': 'user@example.com',
        };
      }
    } catch (e) {
      print('Erreur chargement user: $e');
    }
  }

  Future<void> _loadMessages() async {
    try {
      final result = await _apiService.getAdminConversation(widget.userId, _token!);
      if (result['success'] && result['messages'] != null) {
        setState(() {
          _messages = List<Map<String, dynamic>>.from(result['messages']);
        });
      } else {
        _loadTestMessages();
      }
    } catch (e) {
      _loadTestMessages();
    }
  }

  void _loadTestData() {
    setState(() {
      _user = {
        'id': widget.userId,
        'name': 'Jean Dupont',
        'email': 'jean@example.com',
      };
      _messages = [
        {
          'id': 1,
          'content': 'Bonjour, j\'ai un problème avec ma commande',
          'is_from_admin': false,
          'created_at': DateTime.now().subtract(const Duration(minutes: 30)).toIso8601String(),
        },
        {
          'id': 2,
          'content': 'Bonjour, je vous écoute. Quel est votre numéro de commande ?',
          'is_from_admin': true,
          'created_at': DateTime.now().subtract(const Duration(minutes: 28)).toIso8601String(),
        },
        {
          'id': 3,
          'content': 'Ma commande N°ORD-20260516-001 n\'est toujours pas livrée',
          'is_from_admin': false,
          'created_at': DateTime.now().subtract(const Duration(minutes: 25)).toIso8601String(),
        },
        {
          'id': 4,
          'content': 'Je vérifie cela immédiatement et vous tiens informé.',
          'is_from_admin': true,
          'created_at': DateTime.now().subtract(const Duration(minutes: 23)).toIso8601String(),
        },
      ];
    });
  }

  void _loadTestMessages() {
    setState(() {
      _messages = [];
    });
  }

  Future<void> _sendMessage() async {
    final content = _messageController.text.trim();
    if (content.isEmpty) return;
    
    setState(() => _isSending = true);
    
    // Ajout local temporaire
    final tempMessage = {
      'id': DateTime.now().millisecondsSinceEpoch,
      'content': content,
      'is_from_admin': true,
      'created_at': DateTime.now().toIso8601String(),
      'is_temp': true,
    };
    
    setState(() {
      _messages.add(tempMessage);
      _messageController.clear();
    });
    _scrollToBottom();
    
    // Envoi réel
    if (_token != null) {
      try {
        final result = await _apiService.sendAdminMessage(widget.userId, content, _token!);
        if (result['success']) {
          // Remplacer le message temporaire
          setState(() {
            final index = _messages.indexWhere((m) => m['id'] == tempMessage['id']);
            if (index != -1) {
              _messages[index] = result['message'];
              _messages[index]['is_temp'] = false;
            }
          });
        } else {
          // Supprimer en cas d'erreur
          setState(() {
            _messages.removeWhere((m) => m['id'] == tempMessage['id']);
          });
          _showError(result['message'] ?? 'Erreur d\'envoi');
        }
      } catch (e) {
        setState(() {
          _messages.removeWhere((m) => m['id'] == tempMessage['id']);
        });
        _showError('Erreur de connexion');
      }
    }
    
    setState(() => _isSending = false);
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
      ),
    );
  }

  String _formatTime(String dateTimeStr) {
    try {
      final dateTime = DateTime.parse(dateTimeStr);
      return DateFormat('HH:mm').format(dateTime);
    } catch (e) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final userName = toStringSafe(_user?['name']);
    final userEmail = toStringSafe(_user?['email']);

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
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              userName,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              userEmail,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
            ),
          ],
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
                        'Connectez-vous pour accéder au chat',
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
              : Column(
                  children: [
                    // Messages
                    Expanded(
                      child: ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          final message = _messages[index];
                          final isFromAdmin = message['is_from_admin'] == true;
                          final content = toStringSafe(message['content']);
                          final createdAt = toStringSafe(message['created_at']);
                          final isTemp = message['is_temp'] == true;
                          
                          return _buildMessageBubble(
                            message: content,
                            isFromAdmin: isFromAdmin,
                            time: _formatTime(createdAt),
                            isTemp: isTemp,
                          );
                        },
                      ),
                    ),
                    
                    // Zone de saisie
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        border: Border(top: BorderSide(color: AppColors.border)),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _messageController,
                              decoration: InputDecoration(
                                hintText: 'Écrivez votre message...',
                                hintStyle: TextStyle(color: AppColors.textTertiary),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(25),
                                  borderSide: BorderSide.none,
                                ),
                                filled: true,
                                fillColor: AppColors.backgroundLight,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              ),
                              onSubmitted: (_) => _sendMessage(),
                            ),
                          ),
                          const SizedBox(width: 12),
                          GestureDetector(
                            onTap: _isSending ? null : _sendMessage,
                            child: Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                gradient: AppColors.primaryGradient,
                                shape: BoxShape.circle,
                              ),
                              child: _isSending
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Icon(
                                      Icons.send,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildMessageBubble({
    required String message,
    required bool isFromAdmin,
    required String time,
    bool isTemp = false,
  }) {
    return Align(
      alignment: isFromAdmin ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        child: Column(
          crossAxisAlignment: isFromAdmin ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isFromAdmin ? AppColors.primary : AppColors.backgroundLight,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: isFromAdmin ? const Radius.circular(16) : Radius.zero,
                  bottomRight: isFromAdmin ? Radius.zero : const Radius.circular(16),
                ),
              ),
              child: Text(
                message,
                style: TextStyle(
                  color: isFromAdmin ? Colors.white : AppColors.textPrimary,
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isTemp)
                  const Text(
                    'Envoi... ',
                    style: TextStyle(
                      fontSize: 10,
                      color: AppColors.textTertiary,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                Text(
                  time,
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.textTertiary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _messageController.dispose();
    super.dispose();
  }
}