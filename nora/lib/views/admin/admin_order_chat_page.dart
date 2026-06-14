import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../config/app_colors.dart';
import '../../../services/admin_order_chat_service.dart';
import '../../../services/language_service.dart';

class AdminOrderChatPage extends StatefulWidget {
  final int orderId;
  final String chatType; // 'admin_client' ou 'admin_shop'

  const AdminOrderChatPage({
    super.key,
    required this.orderId,
    required this.chatType,
  });

  @override
  State<AdminOrderChatPage> createState() => _AdminOrderChatPageState();
}

class _AdminOrderChatPageState extends State<AdminOrderChatPage> {
  final AdminOrderChatService _chatService = AdminOrderChatService();
  final LanguageService _languageService = LanguageService();
  final TextEditingController _messageController = TextEditingController();

  List<dynamic> _messages = [];
  bool _isLoading = true;
  bool _isSending = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  Future<void> _loadMessages() async {
    setState(() => _isLoading = true);

    final result = widget.chatType == 'admin_client'
        ? await _chatService.getClientMessages(widget.orderId)
        : await _chatService.getShopMessages(widget.orderId);

    if (result['success']) {
      setState(() {
        _messages = result['messages'] ?? [];
        _isLoading = false;
        _errorMessage = null;
      });
    } else {
      setState(() {
        _isLoading = false;
        _errorMessage = result['message'];
      });
    }
  }

  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;

    setState(() => _isSending = true);

    final result = widget.chatType == 'admin_client'
        ? await _chatService.sendClientMessage(widget.orderId, message)
        : await _chatService.sendShopMessage(widget.orderId, message);

    if (result['success']) {
      _messageController.clear();
      await _loadMessages();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message']),
          backgroundColor: AppColors.error,
        ),
      );
    }

    setState(() => _isSending = false);
  }

  void _safePop() {
    if (Navigator.of(context).canPop()) {
      context.pop();
    } else {
      context.go('/home');
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
          onPressed: _safePop,
        ),
        title: Text(
          widget.chatType == 'admin_client'
              ? 'Chat avec le client'
              : 'Chat avec la boutique',
          style: const TextStyle(color: AppColors.textPrimary),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : _errorMessage != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _errorMessage!,
                              style: const TextStyle(color: AppColors.error),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _loadMessages,
                              child: Text(_languageService.translate('try_again')),
                            ),
                          ],
                        ),
                      )
                    : _messages.isEmpty
                        ? Center(
                            child: Text(
                              'Aucun message',
                              style: const TextStyle(color: AppColors.textSecondary),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _messages.length,
                            itemBuilder: (context, index) {
                              final message = _messages[index];
                              final isAdmin = message['sender_type'] == 'admin';
                              
                              return Align(
                                alignment: isAdmin ? Alignment.centerRight : Alignment.centerLeft,
                                child: Container(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: isAdmin
                                        ? AppColors.primary
                                        : AppColors.backgroundLight,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        message['message'] ?? '',
                                        style: TextStyle(
                                          color: isAdmin ? Colors.white : AppColors.textPrimary,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        _formatTime(message['created_at']),
                                        style: TextStyle(
                                          color: isAdmin
                                              ? Colors.white70
                                              : AppColors.textSecondary,
                                          fontSize: 10,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.background,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: _languageService.translate('type_message'),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: _isSending
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.primary,
                          ),
                        )
                      : const Icon(Icons.send, color: AppColors.primary),
                  onPressed: _isSending ? null : _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(String? dateTime) {
    if (dateTime == null) return '';
    try {
      final date = DateTime.parse(dateTime);
      return '${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return '';
    }
  }
}
