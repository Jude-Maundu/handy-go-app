enum PaymentMethod { mpesa, card, cash }
enum PaymentStatus { pending, completed, failed, refunded }

class PaymentModel {
  final String id;
  final String bookingId;
  final String clientId;
  final String? fundiId;
  final double amount;
  final double serviceFee;
  final double fundiEarnings;
  final PaymentMethod method;
  final PaymentStatus status;
  final String? transactionId;
  final DateTime createdAt;
  final DateTime? completedAt;

  PaymentModel({
    required this.id,
    required this.bookingId,
    required this.clientId,
    this.fundiId,
    required this.amount,
    required this.serviceFee,
    required this.fundiEarnings,
    required this.method,
    required this.status,
    this.transactionId,
    required this.createdAt,
    this.completedAt,
  });

  factory PaymentModel.fromJson(Map<String, dynamic> json) {
    return PaymentModel(
      id: json['id'] as String,
      bookingId: json['bookingId'] as String,
      clientId: json['clientId'] as String,
      fundiId: json['fundiId'] as String?,
      amount: (json['amount'] as num).toDouble(),
      serviceFee: (json['serviceFee'] as num).toDouble(),
      fundiEarnings: (json['fundiEarnings'] as num).toDouble(),
      method: PaymentMethod.values.firstWhere(
        (e) => e.toString() == 'PaymentMethod.${json['method']}',
      ),
      status: PaymentStatus.values.firstWhere(
        (e) => e.toString() == 'PaymentStatus.${json['status']}',
      ),
      transactionId: json['transactionId'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      completedAt: json['completedAt'] != null 
          ? DateTime.parse(json['completedAt'] as String) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'bookingId': bookingId,
      'clientId': clientId,
      'fundiId': fundiId,
      'amount': amount,
      'serviceFee': serviceFee,
      'fundiEarnings': fundiEarnings,
      'method': method.toString().split('.').last,
      'status': status.toString().split('.').last,
      'transactionId': transactionId,
      'createdAt': createdAt.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
    };
  }
}