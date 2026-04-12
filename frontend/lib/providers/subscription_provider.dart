import 'package:flutter/material.dart';
import '../services/api_service.dart';

class SubscriptionModel {
  final String id;
  final String plan;
  final int freeListingsRemaining;
  final int freeContactViewsRemaining;
  final DateTime? expiresAt;

  SubscriptionModel({
    required this.id,
    this.plan = 'free',
    this.freeListingsRemaining = 3,
    this.freeContactViewsRemaining = 5,
    this.expiresAt,
  });

  factory SubscriptionModel.fromJson(Map<String, dynamic> json) {
    return SubscriptionModel(
      id: json['_id'] ?? '',
      plan: json['plan'] ?? 'free',
      freeListingsRemaining: json['freeListingsRemaining'] ?? 3,
      freeContactViewsRemaining: json['freeContactViewsRemaining'] ?? 5,
      expiresAt: json['expiresAt'] != null
          ? DateTime.tryParse(json['expiresAt'])
          : null,
    );
  }

  bool get isPremium => plan == 'premium' && (expiresAt == null || expiresAt!.isAfter(DateTime.now()));
  bool get isBasic => plan == 'basic' && (expiresAt == null || expiresAt!.isAfter(DateTime.now()));
  bool get isFree => plan == 'free' || (expiresAt != null && expiresAt!.isBefore(DateTime.now()));
}

class SubscriptionProvider extends ChangeNotifier {
  final ApiService _api = ApiService();

  SubscriptionModel? _subscription;
  Map<String, dynamic>? _plans;
  bool _isLoading = false;
  String? _error;

  SubscriptionModel? get subscription => _subscription;
  Map<String, dynamic>? get plans => _plans;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchSubscription() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await _api.get('/subscription');
      _subscription = SubscriptionModel.fromJson(data['subscription']);
      _plans = data['plans'] as Map<String, dynamic>?;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> purchasePlan(String plan) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await _api.post('/subscription/purchase', body: {'plan': plan});
      _subscription = SubscriptionModel.fromJson(data['subscription']);
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
