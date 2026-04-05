import 'package:flutter/material.dart';
import '../models/wallet_model.dart';
import '../services/api_service.dart';

class WalletProvider extends ChangeNotifier {
  final ApiService _api = ApiService();

  WalletModel? _wallet;
  bool _isLoading = false;
  String? _error;

  WalletModel? get wallet => _wallet;
  bool get isLoading => _isLoading;
  String? get error => _error;
  double get balance => _wallet?.balance ?? 0;

  Future<void> fetchWallet() async {
    _isLoading = true;
    notifyListeners();

    try {
      final data = await _api.get('/wallet');
      _wallet = WalletModel.fromJson(data['wallet']);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addMoney(double amount) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await _api.post('/wallet/add', body: {'amount': amount});
      _wallet = WalletModel.fromJson(data['wallet']);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> payForBooking(String bookingId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await _api.post('/wallet/pay', body: {'bookingId': bookingId});
      _wallet = WalletModel.fromJson(data['wallet']);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> requestRefund(String bookingId, {String? reason}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final body = <String, dynamic>{'bookingId': bookingId};
      if (reason != null) body['reason'] = reason;
      final data = await _api.post('/wallet/refund', body: body);
      _wallet = WalletModel.fromJson(data['wallet']);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}
