import 'package:flutter/foundation.dart';
import '../models/mb_coin_model.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';

class MBCoinProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  final StorageService _storageService = StorageService();

  MBCoin? _mbCoin;
  List<MBReward> _rewards = [];
  List<MBTransaction> _transactions = [];
  bool _isLoading = false;
  String? _errorMessage;

  MBCoin? get mbCoin => _mbCoin;
  List<MBReward> get rewards => _rewards;
  List<MBTransaction> get transactions => _transactions;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  double get balance => _mbCoin?.balance ?? 0.0;

  MBCoinProvider() {
    loadBalance();
  }

  Future<void> loadBalance() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final token = await _storageService.getToken();
      if (token == null) {
        _isLoading = false;
        notifyListeners();
        return;
      }

      final result = await _apiService.getMbCoinsBalance(token);

      if (result['success']) {
        _mbCoin = MBCoin.fromJson(result['balance']);
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Erreur lors du chargement du solde';
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadRewards({String? status}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final token = await _storageService.getToken();
      if (token == null) {
        _isLoading = false;
        notifyListeners();
        return;
      }

      final result = await _apiService.getMbRewards(status: status);

      if (result['success']) {
        _rewards = (result['rewards'] as List)
            .map((r) => MBReward.fromJson(r as Map<String, dynamic>))
            .toList();
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Erreur lors du chargement des récompenses';
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadTransactions({
    String? type,
    String? startDate,
    String? endDate,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final token = await _storageService.getToken();
      if (token == null) {
        _isLoading = false;
        notifyListeners();
        return;
      }

      final result = await _apiService.getMbCoinsTransactions(
        type: type,
        startDate: startDate,
        endDate: endDate,
        token: token,
      );

      if (result['success']) {
        _transactions = (result['transactions'] as List)
            .map((t) => MBTransaction.fromJson(t as Map<String, dynamic>))
            .toList();
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Erreur lors du chargement des transactions';
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> claimReward(int rewardId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final token = await _storageService.getToken();
      if (token == null) {
        _errorMessage = 'Veuillez vous connecter';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final result = await _apiService.claimMbReward(rewardId, token);

      if (result['success']) {
        await loadBalance();
        await loadRewards();
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = result['message'] ?? 'Erreur lors de la réclamation';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Erreur de connexion au serveur';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> requestWithdrawal({
    required double amount,
    required String method,
    required Map<String, dynamic> details,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final token = await _storageService.getToken();
      if (token == null) {
        _errorMessage = 'Veuillez vous connecter';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final result = await _apiService.requestMbWithdrawal(
        amount: amount,
        method: method,
        details: details,
        token: token,
      );

      if (result['success']) {
        await loadBalance();
        await loadTransactions();
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = result['message'] ?? 'Erreur lors de la demande';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Erreur de connexion au serveur';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> claimDailyBonus() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final token = await _storageService.getToken();
      if (token == null) {
        _errorMessage = 'Veuillez vous connecter';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // TODO: Implement daily bonus API
      _errorMessage = 'Fonctionnalité à implémenter';
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Erreur de connexion au serveur';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
