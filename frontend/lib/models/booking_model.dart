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
  // Clothing rental fields
  final DateTime? eventDate;
  final String renterSize;
  final Map<String, dynamic> sizeDetails;
  final String alterationRequests;
  final String alterationStatus;
  final String securityDepositStatus;
  final String returnStatus;
  final String returnNote;

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
    this.eventDate,
    this.renterSize = '',
    this.sizeDetails = const {},
    this.alterationRequests = '',
    this.alterationStatus = 'none',
    this.securityDepositStatus = 'unpaid',
    this.returnStatus = 'none',
    this.returnNote = '',
  });

  factory BookingModel.fromJson(Map<String, dynamic> json) {
    return BookingModel(
      id: json['id'] ?? json['_id'] ?? '',
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
      startDate: DateTime.tryParse(json['startDate'] ?? '') ?? DateTime.now(),
      endDate: DateTime.tryParse(json['endDate'] ?? '') ?? DateTime.now(),
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
      eventDate: json['eventDate'] != null
          ? DateTime.tryParse(json['eventDate'])
          : null,
      renterSize: json['renterSize'] ?? '',
      sizeDetails: (json['sizeDetails'] as Map<String, dynamic>?) ?? {},
      alterationRequests: json['alterationRequests'] ?? '',
      alterationStatus: json['alterationStatus'] ?? 'none',
      securityDepositStatus: json['securityDepositStatus'] ?? 'unpaid',
      returnStatus: json['returnStatus'] ?? 'none',
      returnNote: json['returnNote'] ?? '',
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
