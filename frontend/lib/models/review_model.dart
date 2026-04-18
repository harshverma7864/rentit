import 'user_model.dart';

class ReviewModel {
  final String id;
  final UserModel? reviewer;
  final String revieweeId;
  final String bookingId;
  final int rating;
  final String comment;
  final DateTime? createdAt;

  ReviewModel({
    required this.id,
    this.reviewer,
    this.revieweeId = '',
    this.bookingId = '',
    required this.rating,
    this.comment = '',
    this.createdAt,
  });

  factory ReviewModel.fromJson(Map<String, dynamic> json) {
    return ReviewModel(
      id: json['id'] ?? json['_id'] ?? '',
      reviewer: json['reviewer'] is Map<String, dynamic>
          ? UserModel.fromJson(json['reviewer'])
          : null,
      revieweeId: json['reviewee'] is String ? json['reviewee'] : '',
      bookingId: json['booking'] is String ? json['booking'] : '',
      rating: json['rating'] ?? 0,
      comment: json['comment'] ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'])
          : null,
    );
  }
}
