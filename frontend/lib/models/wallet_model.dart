class WalletTransactionModel {
  final String id;
  final String type;
  final double amount;
  final String description;
  final String? bookingId;
  final DateTime? createdAt;

  WalletTransactionModel({
    required this.id,
    required this.type,
    required this.amount,
    this.description = '',
    this.bookingId,
    this.createdAt,
  });

  factory WalletTransactionModel.fromJson(Map<String, dynamic> json) {
    return WalletTransactionModel(
      id: json['_id'] ?? '',
      type: json['type'] ?? '',
      amount: (json['amount'] ?? 0).toDouble(),
      description: json['description'] ?? '',
      bookingId: json['booking']?.toString(),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'])
          : null,
    );
  }
}

class WalletModel {
  final String id;
  final double balance;
  final List<WalletTransactionModel> transactions;

  WalletModel({
    required this.id,
    this.balance = 0,
    this.transactions = const [],
  });

  factory WalletModel.fromJson(Map<String, dynamic> json) {
    return WalletModel(
      id: json['_id'] ?? '',
      balance: (json['balance'] ?? 0).toDouble(),
      transactions: (json['transactions'] as List?)
              ?.map<WalletTransactionModel>(
                  (e) => WalletTransactionModel.fromJson(e))
              .toList() ??
          [],
    );
  }
}
