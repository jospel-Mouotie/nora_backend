import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_constants.dart';

class DriverApiService {
  static const String baseUrl = AppConstants.apiBaseUrl;

  Map<String, String> _headers(String token) => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

  /// Récupérer les missions du livreur
  Future<Map<String, dynamic>> getMyMissions(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/driver/missions'),
        headers: _headers(token),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'missions': data['missions'] ?? data['data'] ?? data,
        };
      } else {
        return {'success': false, 'missions': []};
      }
    } catch (e) {
      print('Erreur getMyMissions: $e');
      return {'success': false, 'missions': []};
    }
  }

  /// Récupérer les statistiques du livreur
  Future<Map<String, dynamic>> getDriverStats(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/driver/stats'),
        headers: _headers(token),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'stats': data['stats'] ?? data,
        };
      } else {
        return {'success': false, 'stats': null};
      }
    } catch (e) {
      print('Erreur getDriverStats: $e');
      return {'success': false, 'stats': null};
    }
  }

  /// Récupérer les gains du livreur
  Future<Map<String, dynamic>> getDriverEarnings(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/driver/earnings'),
        headers: _headers(token),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'earnings': data['earnings'] ?? data,
        };
      } else {
        return {'success': false, 'earnings': null};
      }
    } catch (e) {
      print('Erreur getDriverEarnings: $e');
      return {'success': false, 'earnings': null};
    }
  }

  /// Accepter une mission
  Future<Map<String, dynamic>> acceptMission(int missionId, String token) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/driver/missions/$missionId/accept'),
        headers: _headers(token),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'message': data['message'] ?? 'Mission acceptée',
          'mission': data['mission'],
        };
      } else {
        final data = jsonDecode(response.body);
        return {
          'success': false,
          'message': data['message'] ?? 'Erreur lors de l\'acceptation',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Erreur de connexion'};
    }
  }

  /// Marquer une mission comme terminée
  Future<Map<String, dynamic>> completeMission(int missionId, String token) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/driver/missions/$missionId/complete'),
        headers: _headers(token),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'message': data['message'] ?? 'Mission terminée',
          'mission': data['mission'],
        };
      } else {
        final data = jsonDecode(response.body);
        return {
          'success': false,
          'message': data['message'] ?? 'Erreur lors de la finalisation',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Erreur de connexion'};
    }
  }
}
