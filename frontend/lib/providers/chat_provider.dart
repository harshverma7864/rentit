import 'package:flutter/material.dart';
import '../models/chat_model.dart';
import '../services/api_service.dart';

class ChatProvider extends ChangeNotifier {
  final ApiService _api = ApiService();

  List<ChatModel> _chats = [];
  List<ChatMessageModel> _messages = [];
  ChatModel? _currentChat;
  bool _isLoading = false;
  String? _error;
  int _unreadCount = 0;

  List<ChatModel> get chats => _chats;
  List<ChatMessageModel> get messages => _messages;
  ChatModel? get currentChat => _currentChat;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get unreadCount => _unreadCount;

  Future<void> fetchChats() async {
    _isLoading = true;
    notifyListeners();

    try {
      final data = await _api.get('/chats');
      _chats = (data['chats'] as List)
          .map<ChatModel>((e) => ChatModel.fromJson(e))
          .toList();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<ChatModel?> getOrCreateChat({
    required String userId,
    String? itemId,
    String? bookingId,
  }) async {
    try {
      final body = <String, dynamic>{'userId': userId};
      if (itemId != null) body['itemId'] = itemId;
      if (bookingId != null) body['bookingId'] = bookingId;

      final data = await _api.post('/chats', body: body);
      _currentChat = ChatModel.fromJson(data['chat']);
      notifyListeners();
      return _currentChat;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  Future<void> fetchMessages(String chatId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final data = await _api.get('/chats/$chatId/messages');
      _messages = (data['messages'] as List)
          .map<ChatMessageModel>((e) => ChatMessageModel.fromJson(e))
          .toList();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> sendMessage(String chatId, String text) async {
    try {
      final data = await _api.post('/chats/$chatId/messages', body: {'text': text});
      final msg = ChatMessageModel.fromJson(data['message']);
      _messages.add(msg);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<void> markChatRead(String chatId) async {
    try {
      await _api.patch('/chats/$chatId/read');
      await fetchUnreadCount();
    } catch (_) {}
  }

  Future<void> fetchUnreadCount() async {
    try {
      final data = await _api.get('/chats/unread-count');
      _unreadCount = data['unreadCount'] ?? 0;
      notifyListeners();
    } catch (_) {}
  }
}
