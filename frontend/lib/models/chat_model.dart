import 'user_model.dart';

class ChatMessageModel {
  final String id;
  final UserModel? sender;
  final String senderId;
  final String text;
  final List<String> readBy;
  final DateTime? createdAt;

  ChatMessageModel({
    required this.id,
    this.sender,
    this.senderId = '',
    required this.text,
    this.readBy = const [],
    this.createdAt,
  });

  factory ChatMessageModel.fromJson(Map<String, dynamic> json) {
    return ChatMessageModel(
      id: json['_id'] ?? '',
      sender: json['sender'] is Map<String, dynamic>
          ? UserModel.fromJson(json['sender'])
          : null,
      senderId: json['sender'] is String ? json['sender'] : '',
      text: json['text'] ?? '',
      readBy: (json['readBy'] as List?)
              ?.map<String>((e) => e.toString())
              .toList() ??
          [],
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'])
          : null,
    );
  }
}

class ChatModel {
  final String id;
  final List<UserModel> participants;
  final String? itemId;
  final String? bookingId;
  final String lastMessage;
  final DateTime? lastMessageAt;
  final List<ChatMessageModel> messages;

  ChatModel({
    required this.id,
    this.participants = const [],
    this.itemId,
    this.bookingId,
    this.lastMessage = '',
    this.lastMessageAt,
    this.messages = const [],
  });

  factory ChatModel.fromJson(Map<String, dynamic> json) {
    return ChatModel(
      id: json['_id'] ?? '',
      participants: (json['participants'] as List?)
              ?.map<UserModel>((e) =>
                  e is Map<String, dynamic> ? UserModel.fromJson(e) : UserModel(id: e.toString(), name: '', email: ''))
              .toList() ??
          [],
      itemId: json['item'] is Map<String, dynamic>
          ? json['item']['_id']
          : json['item']?.toString(),
      bookingId: json['booking']?.toString(),
      lastMessage: json['lastMessage'] ?? '',
      lastMessageAt: json['lastMessageAt'] != null
          ? DateTime.tryParse(json['lastMessageAt'])
          : null,
      messages: (json['messages'] as List?)
              ?.map<ChatMessageModel>(
                  (e) => ChatMessageModel.fromJson(e))
              .toList() ??
          [],
    );
  }
}
