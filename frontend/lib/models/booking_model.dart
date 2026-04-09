import 'item_model.dart';
import 'user_model.dart';

class NegotiationEntry {
  final String from;
  final double amount;
  final String message;
  final DateTime? timestamp;

  NegotiationEntry({
    required this.from,
    required this.amount,
    this.message = '',
    this.timestamp,
  });

  factory NegotiationEntry.fromJson(Map<String, dynamic> json) {
    return NegotiationEntry(
      from: json['from'] ?? '',
      amount: (json['amount'] ?? 0).toDouble(),
      message: json['message'] ?? '',
      timestamp: json['timestamp'] != null
          ? DateTime.tryParse(json['timestamp'])
          : null,
    );
  }
}

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
  final int quantity;
  final String status;
  final String deliveryOption;
  final String deliveryStatus;
  final String estimatedDeliveryTime;
  final DateTime? scheduledPickupTime;
  final String renterNote;
  final String ownerNote;
  final String paymentStatus;
  final DateTime? paymentDate;
  final DateTime? createdAt;
  final double? proposedPrice;
  final String negotiationStatus;
  final List<NegotiationEntry> negotiationHistory;
  final double? finalPrice;

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
    this.quantity = 1,
    this.status = 'pending',
    this.deliveryOption = 'pickup',
    this.deliveryStatus = 'none',
    this.estimatedDeliveryTime = '',
    this.scheduledPickupTime,
    this.renterNote = '',
    this.ownerNote = '',
    this.paymentStatus = 'unpaid',
    this.paymentDate,
    this.createdAt,
    this.proposedPrice,
    this.negotiationStatus = 'none',
    this.negotiationHistory = const [],
    this.finalPrice,
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
      quantity: json['quantity'] ?? 1,
      status: json['status'] ?? 'pending',
      deliveryOption: json['deliveryOption'] ?? 'pickup',
      deliveryStatus: json['deliveryStatus'] ?? 'none',
      estimatedDeliveryTime: json['estimatedDeliveryTime'] ?? '',
      scheduledPickupTime: json['scheduledPickupTime'] != null
          ? DateTime.tryParse(json['scheduledPickupTime'])
          : null,
      renterNote: json['renterNote'] ?? '',
      ownerNote: json['ownerNote'] ?? '',
      paymentStatus: json['paymentStatus'] ?? 'unpaid',
      paymentDate: json['paymentDate'] != null
          ? DateTime.tryParse(json['paymentDate'])
          : null,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'])
          : null,
      proposedPrice: json['proposedPrice'] != null
          ? (json['proposedPrice']).toDouble()
          : null,
      negotiationStatus: json['negotiationStatus'] ?? 'none',
      negotiationHistory: (json['negotiationHistory'] as List?)
              ?.map<NegotiationEntry>((e) => NegotiationEntry.fromJson(e))
              .toList() ??
          [],
      finalPrice: json['finalPrice'] != null
          ? (json['finalPrice']).toDouble()
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
