class BookingModel {
  final String id;
  final String jobId;
  final String clientId;
  final String fundiId;
  final DateTime bookingDate;
  final DateTime? startTime;
  final DateTime? endTime;
  final double totalAmount;
  final String status; // pending, confirmed, in_progress, completed, cancelled
  final String? cancellationReason;

  BookingModel({
    required this.id,
    required this.jobId,
    required this.clientId,
    required this.fundiId,
    required this.bookingDate,
    this.startTime,
    this.endTime,
    required this.totalAmount,
    required this.status,
    this.cancellationReason,
  });

  factory BookingModel.fromJson(Map<String, dynamic> json) {
    return BookingModel(
      id: json['id'] as String,
      jobId: json['jobId'] as String,
      clientId: json['clientId'] as String,
      fundiId: json['fundiId'] as String,
      bookingDate: DateTime.parse(json['bookingDate'] as String),
      startTime: json['startTime'] != null
          ? DateTime.parse(json['startTime'] as String)
          : null,
      endTime: json['endTime'] != null
          ? DateTime.parse(json['endTime'] as String)
          : null,
      totalAmount: (json['totalAmount'] as num).toDouble(),
      status: json['status'] as String,
      cancellationReason: json['cancellationReason'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'jobId': jobId,
      'clientId': clientId,
      'fundiId': fundiId,
      'bookingDate': bookingDate.toIso8601String(),
      'startTime': startTime?.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'totalAmount': totalAmount,
      'status': status,
      'cancellationReason': cancellationReason,
    };
  }
}
