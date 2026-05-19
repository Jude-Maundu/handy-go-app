class EarningsModel {
  final String id;
  final String fundiId;
  final double totalEarned;
  final double availableBalance;
  final double withdrawnAmount;
  final DateTime lastUpdated;
  final List<TransactionModel> transactions;

  EarningsModel({
    required this.id,
    required this.fundiId,
    required this.totalEarned,
    required this.availableBalance,
    required this.withdrawnAmount,
    required this.lastUpdated,
    this.transactions = const [],
  });

  factory EarningsModel.fromJson(Map<String, dynamic> json) {
    return EarningsModel(
      id: json['id'] as String,
      fundiId: json['fundiId'] as String,
      totalEarned: (json['totalEarned'] as num).toDouble(),
      availableBalance: (json['availableBalance'] as num).toDouble(),
      withdrawnAmount: (json['withdrawnAmount'] as num).toDouble(),
      lastUpdated: DateTime.parse(json['lastUpdated'] as String),
      transactions: (json['transactions'] as List?)
          ?.map((e) => TransactionModel.fromJson(e))
          .toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fundiId': fundiId,
      'totalEarned': totalEarned,
      'availableBalance': availableBalance,
      'withdrawnAmount': withdrawnAmount,
      'lastUpdated': lastUpdated.toIso8601String(),
      'transactions': transactions.map((e) => e.toJson()).toList(),
    };
  }
}

class TransactionModel {
  final String id;
  final double amount;
  final String type; // earning, withdrawal, bonus
  final String status;
  final DateTime createdAt;
  final String? description;

  TransactionModel({
    required this.id,
    required this.amount,
    required this.type,
    required this.status,
    required this.createdAt,
    this.description,
  });

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      id: json['id'] as String,
      amount: (json['amount'] as num).toDouble(),
      type: json['type'] as String,
      status: json['status'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      description: json['description'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'amount': amount,
      'type': type,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
      'description': description,
    };
  }
}