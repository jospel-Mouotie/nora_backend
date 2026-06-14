import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_constants.dart';

class AdminOrderChatService {
  static final AdminOrderChatService _instance = AdminOrderChatService._internal();
  factory AdminOrderChatService() => _instance;
  AdminOrderChatService._internal();

  final String _baseUrl = AppConstants.apiBaseUrl;

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<Map<String, dynamic>> getClientMessages(int orderId) async {
    final token = await _getToken();
    if (token == null) {
      return {'success': false, 'message': 'Non authentifié'};
    }

    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/admin-order-chat/client/$orderId/messages'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {'success': true, 'messages': data['messages'] ?? []};
      } else {
        return {'success': false, 'message': 'Erreur lors du chargement'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Erreur de connexion'};
    }
  }

  Future<Map<String, dynamic>> sendClientMessage(int orderId, String message) async {
    final token = await _getToken();
    if (token == null) {
      return {'success': false, 'message': 'Non authentifié'};
    }

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/admin-order-chat/client/$orderId/send'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'message': message}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return {'success': true, 'message': data['message']};
      } else {
        return {'success': false, 'message': 'Erreur lors de l\'envoi'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Erreur de connexion'};
    }
  }

  Future<Map<String, dynamic>> getShopMessages(int orderId) async {
    final token = await _getToken();
    if (token == null) {
      return {'success': false, 'message': 'Non authentifié'};
    }

    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/admin-order-chat/shop/$orderId/messages'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {'success': true, 'messages': data['messages'] ?? []};
      } else {
        return {'success': false, 'message': 'Erreur lors du chargement'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Erreur de connexion'};
    }
  }

  Future<Map<String, dynamic>> sendShopMessage(int orderId, String message) async {
    final token = await _getToken();
    if (token == null) {
      return {'success': false, 'message': 'Non authentifié'};
    }

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/admin-order-chat/shop/$orderId/send'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'message': message}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return {'success': true, 'message': data['message']};
      } else {
        return {'success': false, 'message': 'Erreur lors de l\'envoi'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Erreur de connexion'};
    }
  }

  Future<Map<String, dynamic>> markAsRead(int orderId, String chatType) async {
    final token = await _getToken();
    if (token == null) {
      return {'success': false, 'message': 'Non authentifié'};
    }

    try {
      final response = await http.put(
        Uri.parse('$_baseUrl/admin-order-chat/$orderId/mark-read'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'chat_type': chatType}),
      );

      if (response.statusCode == 200) {
        return {'success': true};
      } else {
        return {'success': false, 'message': 'Erreur lors du marquage'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Erreur de connexion'};
    }
  }

  Future<Map<String, dynamic>> getUnreadCount(String chatType) async {
    final token = await _getToken();
    if (token == null) {
      return {'success': false, 'message': 'Non authentifié'};
    }

    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/admin-order-chat/unread-count?chat_type=$chatType'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {'success': true, 'unread_count': data['unread_count']};
      } else {
        return {'success': false, 'message': 'Erreur lors du chargement'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Erreur de connexion'};
    }
  }
}
