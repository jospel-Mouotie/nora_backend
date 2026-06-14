import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_constants.dart';

class MbCoinsApiService {
  static const String baseUrl = AppConstants.apiBaseUrl;

  // Récupérer le solde MB Coins
  Future<Map<String, dynamic>> getMbCoinsBalance(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/mb-coins/balance'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'balance': data,
        };
      } else {
        return {'success': false, 'message': 'Erreur lors du chargement du solde'};
      }
    } catch (e) {
      print('Erreur getMbCoinsBalance: $e');
      return {'success': false, 'message': 'Erreur de connexion'};
    }
  }

  // ✅ Vérifier si le bonus quotidien a été réclamé
  Future<Map<String, dynamic>> checkDailyBonus(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/mb-rewards/daily-bonus/status'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'claimed': data['claimed'] ?? false,
          'next_claim_at': data['next_claim_at'],
        };
      } else {
        return {'success': false, 'claimed': true};
      }
    } catch (e) {
      print('Erreur checkDailyBonus: $e');
      return {'success': false, 'claimed': true};
    }
  }

  // ✅ Réclamer le bonus quotidien
  Future<Map<String, dynamic>> claimDailyBonus(String token) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/mb-rewards/daily-bonus/claim'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'amount': data['amount'] ?? 10,
          'message': data['message'] ?? 'Bonus quotidien réclamé !',
          'new_balance': data['new_balance'],
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Erreur lors de la réclamation',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Erreur de connexion au serveur',
      };
    }
  }

  // Demander un retrait MB Coins
  Future<Map<String, dynamic>> requestMbWithdrawal({
    required double amount,
    required String method,
    required Map<String, dynamic> details,
    required String token,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/mb-coins/withdraw'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'amount': amount,
          'method': method,
          'details': details,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': data['message'] ?? 'Demande envoyée',
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Erreur lors de la demande',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Erreur de connexion au serveur',
      };
    }
  }

  // Récupérer l'historique des transactions MB Coins
  Future<Map<String, dynamic>> getMbCoinsTransactions({
    String? type,
    String? startDate,
    String? endDate,
    int limit = 20,
    required String token,
  }) async {
    try {
      final queryParams = <String, String>{};
      queryParams['limit'] = limit.toString();
      if (type != null) queryParams['type'] = type;
      if (startDate != null) queryParams['start_date'] = startDate;
      if (endDate != null) queryParams['end_date'] = endDate;

      final uri = Uri.parse('$baseUrl/api/mb-coins/transactions').replace(queryParameters: queryParams);
      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'transactions': data['transactions'] ?? data,
          'summary': data['summary'],
        };
      } else {
        return {'success': false, 'transactions': []};
      }
    } catch (e) {
      print('Erreur getMbCoinsTransactions: $e');
      return {'success': false, 'transactions': []};
    }
  }

  // Récupérer les récompenses MB disponibles
  Future<Map<String, dynamic>> getMbRewards({String? status, int limit = 20}) async {
    try {
      final queryParams = <String, String>{};
      queryParams['limit'] = limit.toString();
      if (status != null) queryParams['status'] = status;

      final uri = Uri.parse('$baseUrl/api/mb-rewards').replace(queryParameters: queryParams);
      final response = await http.get(
        uri,
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'rewards': data['rewards'] ?? data,
          'summary': data['summary'],
        };
      } else {
        return {'success': false, 'rewards': []};
      }
    } catch (e) {
      print('Erreur getMbRewards: $e');
      return {'success': false, 'rewards': []};
    }
  }

  // Réclamer une récompense
  Future<Map<String, dynamic>> claimMbReward(int rewardId, String token) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/mb-rewards/$rewardId/claim'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': data['message'] ?? 'Récompense réclamée',
          'new_balance': data['new_balance'],
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Erreur lors du réclamation',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Erreur de connexion au serveur',
      };
    }
  }

  // Récupérer la liste des boutiques MB
  Future<Map<String, dynamic>> getMbShops() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/mb-shops'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'shops': data['shops'] ?? data,
        };
      } else {
        return {'success': false, 'shops': []};
      }
    } catch (e) {
      print('Erreur getMbShops: $e');
      return {'success': false, 'shops': []};
    }
  }

  // Récupérer les paramètres globaux (taux et pourcentage)
  Future<Map<String, dynamic>> getGlobalSettings(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/mb-coins/settings'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {'success': true, 'rate': data['rate'] ?? 0.0, 'percentage': data['percentage'] ?? 100.0};
      }
      return {'success': false, 'rate': 0.0, 'percentage': 100.0};
    } catch (e) {
      return {'success': false, 'rate': 0.0, 'percentage': 100.0};
    }
  }

  // Mettre à jour les paramètres globaux (Admin)
  Future<Map<String, dynamic>> saveGlobalSettings({
    required double rate,
    required double percentage,
    required String token,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/admin/mb-coins/settings'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'rate': rate, 'percentage': percentage}),
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {'success': true, 'message': data['message'] ?? 'Paramètres mis à jour'};
      }
      return {'success': false, 'message': data['error'] ?? data['message'] ?? 'Erreur lors de la mise à jour'};
    } catch (e) {
      return {'success': false, 'message': 'Erreur de connexion'};
    }
  }

  // Réclamer des coins pour une action (visionnage, like, commentaire, login)
  Future<Map<String, dynamic>> earnCoins({
    required String action,
    int? videoId,
    required String token,
  }) async {
    try {
      final body = <String, dynamic>{'action': action};
      if (videoId != null) body['video_id'] = videoId;

      final response = await http.post(
        Uri.parse('$baseUrl/api/mb-coins/earn'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {
          'success': true,
          'earned': (data['earned'] as num?)?.toDouble() ?? 0.0,
          'balance': (data['balance'] as num?)?.toDouble() ?? 0.0,
          'message': data['message'] ?? 'Coins gagnés !',
        };
      }
      return {'success': false, 'message': data['error'] ?? data['message'] ?? 'Action déjà créditée'};
    } catch (e) {
      return {'success': false, 'message': 'Erreur de connexion'};
    }
  }

  // Convertir des MB Coins en FCFA
  Future<Map<String, dynamic>> convertCoins({
    required double amount,
    required String token,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/mb-coins/convert'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'amount': amount}),
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {
          'success': true,
          'converted_coins': (data['converted_coins'] as num?)?.toDouble() ?? amount,
          'cash_received': (data['cash_received'] as num?)?.toDouble() ?? 0.0,
          'new_mb_balance': (data['new_mb_balance'] as num?)?.toDouble() ?? 0.0,
          'new_wallet_balance': (data['new_wallet_balance'] as num?)?.toDouble() ?? 0.0,
          'message': data['message'] ?? 'Conversion réussie !',
        };
      }
      return {'success': false, 'message': data['error'] ?? data['message'] ?? 'Erreur de conversion'};
    } catch (e) {
      return {'success': false, 'message': 'Erreur de connexion'};
    }
  }
}
