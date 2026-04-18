import 'user_model.dart';
import 'booking_model.dart';

class DisputeModel {
  final String id;
  final String? bookingId;
  final BookingModel? booking;
  final UserModel? raisedBy;
  final UserModel? againstUser;
  final String reason;
  final String description;
  final List<String> images;
  final String status;
  final String resolution;
  final DateTime? createdAt;

  DisputeModel({
    required this.id,
    this.bookingId,
    this.booking,
    this.raisedBy,
    this.againstUser,
    required this.reason,
    required this.description,
    this.images = const [],
    this.status = 'open',
    this.resolution = '',
    this.createdAt,
  });

  factory DisputeModel.fromJson(Map<String, dynamic> json) {
    return DisputeModel(
      id: json['id'] ?? json['_id'] ?? '',
      bookingId: json['booking'] is String ? json['booking'] : null,
      booking: json['booking'] is Map<String, dynamic>
          ? BookingModel.fromJson(json['booking'])
          : null,
      raisedBy: json['raisedBy'] is Map<String, dynamic>
          ? UserModel.fromJson(json['raisedBy'])
          : null,
      againstUser: json['againstUser'] is Map<String, dynamic>
          ? UserModel.fromJson(json['againstUser'])
          : null,
      reason: json['reason'] ?? '',
      description: json['description'] ?? '',
      images: (json['images'] as List?)
              ?.map<String>((e) => e.toString())
              .toList() ??
          [],
      status: json['status'] ?? 'open',
      resolution: json['resolution'] ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'])
          : null,
    );
  }

  String get statusLabel {
    switch (status) {
      case 'open':
        return 'Open';
      case 'under_review':
        return 'Under Review';
      case 'resolved':
        return 'Resolved';
      case 'dismissed':
        return 'Dismissed';
      default:
        return status;
    }
  }
}
