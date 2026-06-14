import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../../../config/app_colors.dart';
import '../../../services/api_service.dart';
import '../../../services/storage_service.dart';
import '../../../widgets/chat/chat_bubble.dart';
import '../../../widgets/chat/message_input.dart';
import '../../../utils/converters.dart';

class ChatDeliveryPage extends StatefulWidget {
  final int deliveryId;

  const ChatDeliveryPage({super.key, required this.deliveryId});

  @override
  State<ChatDeliveryPage> createState() => _ChatDeliveryPageState();
}

class _ChatDeliveryPageState extends State<ChatDeliveryPage> {
  final ApiService _apiService = ApiService();
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _messageController = TextEditingController();
  
  List<Map<String, dynamic>> _messages = [];
  bool _isLoading = true;
  String? _token;
  WebSocketChannel? _channel;

  @override
  void initState() {
    super.initState();
    _loadToken();
    _loadMessages();
    _connectWebSocket();
  }

  Future<void> _loadToken() async {
    _token = await StorageService().getToken();
  }

  Future<void> _loadMessages() async {
    setState(() => _isLoading = true);
    
    try {
      final result = await _apiService.getDeliveryMessages(widget.deliveryId);
      if (result['success'] && result['messages'] != null) {
        setState(() {
          _messages = List<Map<String, dynamic>>.from(result['messages']);
          _isLoading = false;
        });
        _scrollToBottom();
      } else {
        _loadTestMessages();
      }
    } catch (e) {
      _loadTestMessages();
    }
  }

  void _loadTestMessages() {
    setState(() {
      _messages = [
        {
          'id': 1,
          'content': 'Bonjour, je suis en route !',
          'is_from_delivery': true,
          'created_at': DateTime.now().subtract(const Duration(minutes: 10)).toIso8601String(),
        },
        {
          'id': 2,
          'content': 'D\'accord, je vous attends.',
          'is_from_delivery': false,
          'created_at': DateTime.now().subtract(const Duration(minutes: 9)).toIso8601String(),
        },
        {
          'id': 3,
          'content': 'Je serai là dans 5 minutes.',
          'is_from_delivery': true,
          'created_at': DateTime.now().subtract(const Duration(minutes: 2)).toIso8601String(),
        },
      ];
      _isLoading = false;
    });
    _scrollToBottom();
  }

  void _connectWebSocket() {
    // TODO: Connecter WebSocket pour messages en temps réel
    // _channel = WebSocketChannel.connect(
    //   Uri.parse('ws://192.168.43.145:8000/chat/delivery/${widget.deliveryId}'),
    // );
    // _channel?.stream.listen(_onMessageReceived);
  }

  void _onMessageReceived(dynamic data) {
    final message = Map<String, dynamic>.from(data);
    setState(() {
      _messages.add(message);
    });
    _scrollToBottom();
  }

  Future<void> _sendMessage() async {
    final content = _messageController.text.trim();
    if (content.isEmpty) return;
    
    _messageController.clear();
    
    // Ajout local immédiat
    final tempMessage = {
      'id': DateTime.now().millisecondsSinceEpoch,
      'content': content,
      'is_from_delivery': false,
      'created_at': DateTime.now().toIso8601String(),
      'is_temp': true,
    };
    
    setState(() {
      _messages.add(tempMessage);
    });
    _scrollToBottom();
    
    // Envoi via API
    if (_token != null) {
      try {
        final result = await _apiService.sendDeliveryMessage(
          widget.deliveryId,
          content,
          _token!,
        );
        
        if (result['success']) {
          // Remplacer le message temporaire par le vrai
          setState(() {
            final index = _messages.indexWhere((m) => m['id'] == tempMessage['id']);
            if (index != -1) {
              _messages[index] = result['message'];
              _messages[index]['is_temp'] = false;
            }
          });
        } else {
          // Supprimer le message temporaire en cas d'erreur
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Chat Livreur',
          style: TextStyle(color: AppColors.textPrimary),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final message = _messages[index];
                      final isFromDelivery = message['is_from_delivery'] == true;
                      final content = toStringSafe(message['content']);
                      final createdAt = DateTime.tryParse(toStringSafe(message['created_at'])) ?? DateTime.now();
                      final isTemp = message['is_temp'] == true;
                      
                      return ChatBubble(
                        message: content,
                        isMe: !isFromDelivery,
                        timestamp: createdAt,
                        showAvatar: !isFromDelivery && !isTemp,
                      );
                    },
                  ),
          ),
          MessageInput(
            controller: _messageController,
            onSend: _sendMessage,
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _channel?.sink.close();
    _scrollController.dispose();
    _messageController.dispose();
    super.dispose();
  }
}