import 'item_model.dart';
import 'user_model.dart';

class BookingModel {
  final String id;
  final ItemModel? item;
  final String? itemId;
  final UserModel? renter;
  final UserModel? owner;
  final DateTime startDate;
  final DateTime endDate;
  final double totalPrice;
  final double securityDeposit;
  final String status;
  final String deliveryOption;
  final String estimatedDeliveryTime;
  final DateTime? scheduledPickupTime;
  final String renterNote;
  final String ownerNote;
  final DateTime? createdAt;

  BookingModel({
    required this.id,
    this.item,
    this.itemId,
    this.renter,
    this.owner,
    required this.startDate,
    required this.endDate,
    required this.totalPrice,
    required this.securityDeposit,
    this.status = 'pending',
    this.deliveryOption = 'pickup',
    this.estimatedDeliveryTime = '',
    this.scheduledPickupTime,
    this.renterNote = '',
    this.ownerNote = '',
    this.createdAt,
  });

  factory BookingModel.fromJson(Map<String, dynamic> json) {
    return BookingModel(
      id: json['_id'] ?? '',
      item: json['item'] is Map<String, dynamic>
          ? ItemModel.fromJson(json['item'])
          : null,
      itemId: json['item'] is String ? json['item'] : null,
      renter: json['renter'] is Map<String, dynamic>
          ? UserModel.fromJson(json['renter'])
          : null,
      owner: json['owner'] is Map<String, dynamic>
          ? UserModel.fromJson(json['owner'])
          : null,
      startDate: DateTime.parse(
          json['startDate'] ?? DateTime.now().toIso8601String()),
      endDate: DateTime.parse(
          json['endDate'] ?? DateTime.now().toIso8601String()),
      totalPrice: (json['totalPrice'] ?? 0).toDouble(),
      securityDeposit: (json['securityDeposit'] ?? 0).toDouble(),
      status: json['status'] ?? 'pending',
      deliveryOption: json['deliveryOption'] ?? 'pickup',
      estimatedDeliveryTime: json['estimatedDeliveryTime'] ?? '',
      scheduledPickupTime: json['scheduledPickupTime'] != null
          ? DateTime.tryParse(json['scheduledPickupTime'])
          : null,
      renterNote: json['renterNote'] ?? '',
      ownerNote: json['ownerNote'] ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'])
          : null,
    );
  }

  String get statusLabel {
    switch (status) {
      case 'pending':
        return 'Pending';
      case 'accepted':
        return 'Accepted';
      case 'rejected':
        return 'Rejected';
      case 'active':
        return 'Active';
      case 'completed':
        return 'Completed';
      case 'cancelled':
        return 'Cancelled';
      default:
        return status;
    }
  }

  int get rentalDays => endDate.difference(startDate).inDays.clamp(1, 9999);
}
