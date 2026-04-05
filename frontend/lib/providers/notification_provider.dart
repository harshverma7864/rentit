import 'package:flutter/material.dart';
import '../models/notification_model.dart';
import '../services/api_service.dart';

class NotificationProvider extends ChangeNotifier {
  final ApiService _api = ApiService();

  List<NotificationModel> _notifications = [];
  int _unreadCount = 0;
  bool _isLoading = false;

  List<NotificationModel> get notifications => _notifications;
  int get unreadCount => _unreadCount;
  bool get isLoading => _isLoading;

  Future<void> fetchNotifications() async {
    _isLoading = true;
    notifyListeners();

    try {
      final data = await _api.get('/notifications');
      _notifications = (data['notifications'] as List)
          .map<NotificationModel>((e) => NotificationModel.fromJson(e))
          .toList();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchUnreadCount() async {
    try {
      final data = await _api.get('/notifications/unread-count');
      _unreadCount = data['count'] ?? 0;
      notifyListeners();
    } catch (_) {}
  }

  Future<void> markAsRead(String id) async {
    try {
      await _api.patch('/notifications/$id/read');
      final idx = _notifications.indexWhere((n) => n.id == id);
      if (idx != -1) {
        _unreadCount = (_unreadCount - 1).clamp(0, 9999);
        notifyListeners();
      }
      await fetchNotifications();
    } catch (_) {}
  }

  Future<void> markAllRead() async {
    try {
      await _api.patch('/notifications/read-all');
      _unreadCount = 0;
      await fetchNotifications();
    } catch (_) {}
  }

  void addNotification(NotificationModel notification) {
    _notifications.insert(0, notification);
    _unreadCount++;
    notifyListeners();
  }
}
