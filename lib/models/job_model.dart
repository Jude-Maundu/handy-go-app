import 'package:cloud_firestore/cloud_firestore.dart';
import '../config/build_config.dart';

enum JobStatus { pending, accepted, inProgress, completed, cancelled }

class Job {
  final String id;
  final String title;
  final String category;
  final double budget;
  final String location;
  final String description;
  final DateTime createdAt;
  final String? clientId;
  final String? clientName;
  final double? clientRating;
  final String? clientPhoto;
  final String? fundiId;
  final String? fundiName;
  final double? fundiRating;
  final int? applicantsCount;
  final DateTime? scheduledDate;
  final JobStatus status;
  final double? serviceFee;
  final double? fundiEarnings;
  final double? latitude;
  final double? longitude;
  final double? fundiLatitude;
  final double? fundiLongitude;
  final double destinationLatitude;
  final double destinationLongitude;
  final double distanceToFundi;
  final double progress;
  final List<String> photoUrls;
  final String paymentStatus; // 'none' | 'pending' | 'paid' | 'failed'
  final String? clientPhone;

  Job({
    required this.id,
    required this.title,
    required this.category,
    required this.budget,
    required this.location,
    required this.description,
    required this.createdAt,
    this.clientId,
    this.clientName,
    this.clientRating,
    this.clientPhoto,
    this.fundiId,
    this.fundiName,
    this.fundiRating,
    this.applicantsCount,
    this.scheduledDate,
    this.status = JobStatus.pending,
    this.serviceFee,
    this.fundiEarnings,
    this.latitude,
    this.longitude,
    this.fundiLatitude,
    this.fundiLongitude,
    this.destinationLatitude = 0.0,
    this.destinationLongitude = 0.0,
    this.distanceToFundi = 0.0,
    this.progress = 0.0,
    this.photoUrls = const [],
    this.paymentStatus = 'none',
    this.clientPhone,
  });

  bool get isClientJob => BuildConfig.isClient && clientId != null;
  bool get isFundiJob => BuildConfig.isFundi && fundiId != null;

  String get statusText {
    switch (status) {
      case JobStatus.pending:
        return 'Pending';
      case JobStatus.accepted:
        return 'Accepted';
      case JobStatus.inProgress:
        return 'In Progress';
      case JobStatus.completed:
        return 'Completed';
      case JobStatus.cancelled:
        return 'Cancelled';
    }
  }

  String get statusColor {
    switch (status) {
      case JobStatus.pending:
        return '#FFC107';
      case JobStatus.accepted:
        return '#2196F3';
      case JobStatus.inProgress:
        return '#FF9800';
      case JobStatus.completed:
        return '#4CAF50';
      case JobStatus.cancelled:
        return '#F44336';
    }
  }

  factory Job.fromJson(Map<String, dynamic> json) {
    return Job(
      id: json['id'] as String,
      title: json['title'] as String,
      category: json['category'] as String,
      budget: (json['budget'] as num).toDouble(),
      location: json['location'] as String,
      description: json['description'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      clientId: json['clientId'] as String?,
      clientName: json['clientName'] as String?,
      clientRating: (json['clientRating'] as num?)?.toDouble(),
      clientPhoto: json['clientPhoto'] as String?,
      fundiId: json['fundiId'] as String?,
      fundiName: json['fundiName'] as String?,
      fundiRating: (json['fundiRating'] as num?)?.toDouble(),
      applicantsCount: json['applicantsCount'] as int?,
      scheduledDate: json['scheduledDate'] != null
          ? DateTime.parse(json['scheduledDate'] as String)
          : null,
      status: JobStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => JobStatus.pending,
      ),
      serviceFee: (json['serviceFee'] as num?)?.toDouble(),
      fundiEarnings: (json['fundiEarnings'] as num?)?.toDouble(),
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      fundiLatitude: (json['fundiLatitude'] as num?)?.toDouble(),
      fundiLongitude: (json['fundiLongitude'] as num?)?.toDouble(),
      destinationLatitude: (json['destinationLatitude'] as num?)?.toDouble() ?? 0.0,
      destinationLongitude: (json['destinationLongitude'] as num?)?.toDouble() ?? 0.0,
      distanceToFundi: (json['distanceToFundi'] as num?)?.toDouble() ?? 0.0,
      progress: (json['progress'] as num?)?.toDouble() ?? 0.0,
      photoUrls: (json['photoUrls'] as List<dynamic>?)?.cast<String>() ?? [],
      paymentStatus: json['paymentStatus'] as String? ?? 'none',
      clientPhone: json['clientPhone'] as String?,
    );
  }

  factory Job.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data()!;
    DateTime createdAt;
    final raw = d['createdAt'];
    if (raw is Timestamp) {
      createdAt = raw.toDate();
    } else if (raw is String) {
      createdAt = DateTime.parse(raw);
    } else {
      createdAt = DateTime.now();
    }
    return Job(
      id: doc.id,
      title: d['title'] as String? ?? '',
      category: d['category'] as String? ?? '',
      budget: (d['budget'] as num?)?.toDouble() ?? 0.0,
      location: d['location'] as String? ?? '',
      description: d['description'] as String? ?? '',
      createdAt: createdAt,
      clientId: d['clientId'] as String?,
      clientName: d['clientName'] as String?,
      clientRating: (d['clientRating'] as num?)?.toDouble(),
      clientPhoto: d['clientPhoto'] as String?,
      fundiId: d['fundiId'] as String?,
      fundiName: d['fundiName'] as String?,
      fundiRating: (d['fundiRating'] as num?)?.toDouble(),
      applicantsCount: d['applicantsCount'] as int?,
      scheduledDate: d['scheduledDate'] is Timestamp
          ? (d['scheduledDate'] as Timestamp).toDate()
          : null,
      status: JobStatus.values.firstWhere(
        (e) => e.name == d['status'],
        orElse: () => JobStatus.pending,
      ),
      serviceFee: (d['serviceFee'] as num?)?.toDouble(),
      fundiEarnings: (d['fundiEarnings'] as num?)?.toDouble(),
      latitude: (d['latitude'] as num?)?.toDouble(),
      longitude: (d['longitude'] as num?)?.toDouble(),
      fundiLatitude: (d['fundiLatitude'] as num?)?.toDouble(),
      fundiLongitude: (d['fundiLongitude'] as num?)?.toDouble(),
      destinationLatitude: (d['destinationLatitude'] as num?)?.toDouble() ?? 0.0,
      destinationLongitude: (d['destinationLongitude'] as num?)?.toDouble() ?? 0.0,
      distanceToFundi: (d['distanceToFundi'] as num?)?.toDouble() ?? 0.0,
      progress: (d['progress'] as num?)?.toDouble() ?? 0.0,
      photoUrls: (d['photoUrls'] as List<dynamic>?)?.cast<String>() ?? [],
      paymentStatus: d['paymentStatus'] as String? ?? 'none',
      clientPhone: d['clientPhone'] as String?,
    );
  }

  Job copyWith({
    String? id,
    String? title,
    String? category,
    double? budget,
    String? location,
    String? description,
    DateTime? createdAt,
    String? clientId,
    String? clientName,
    double? clientRating,
    String? clientPhoto,
    String? fundiId,
    String? fundiName,
    double? fundiRating,
    int? applicantsCount,
    DateTime? scheduledDate,
    JobStatus? status,
    double? serviceFee,
    double? fundiEarnings,
    double? latitude,
    double? longitude,
    double? fundiLatitude,
    double? fundiLongitude,
    double? destinationLatitude,
    double? destinationLongitude,
    double? distanceToFundi,
    double? progress,
    List<String>? photoUrls,
    String? paymentStatus,
    String? clientPhone,
  }) {
    return Job(
      id: id ?? this.id,
      title: title ?? this.title,
      category: category ?? this.category,
      budget: budget ?? this.budget,
      location: location ?? this.location,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      clientId: clientId ?? this.clientId,
      clientName: clientName ?? this.clientName,
      clientRating: clientRating ?? this.clientRating,
      clientPhoto: clientPhoto ?? this.clientPhoto,
      fundiId: fundiId ?? this.fundiId,
      fundiName: fundiName ?? this.fundiName,
      fundiRating: fundiRating ?? this.fundiRating,
      applicantsCount: applicantsCount ?? this.applicantsCount,
      scheduledDate: scheduledDate ?? this.scheduledDate,
      status: status ?? this.status,
      serviceFee: serviceFee ?? this.serviceFee,
      fundiEarnings: fundiEarnings ?? this.fundiEarnings,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      fundiLatitude: fundiLatitude ?? this.fundiLatitude,
      fundiLongitude: fundiLongitude ?? this.fundiLongitude,
      destinationLatitude: destinationLatitude ?? this.destinationLatitude,
      destinationLongitude: destinationLongitude ?? this.destinationLongitude,
      distanceToFundi: distanceToFundi ?? this.distanceToFundi,
      progress: progress ?? this.progress,
      photoUrls: photoUrls ?? this.photoUrls,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      clientPhone: clientPhone ?? this.clientPhone,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'category': category,
      'budget': budget,
      'location': location,
      'description': description,
      'createdAt': createdAt.toIso8601String(),
      'clientId': clientId,
      'clientName': clientName,
      'clientRating': clientRating,
      'clientPhoto': clientPhoto,
      'fundiId': fundiId,
      'fundiName': fundiName,
      'fundiRating': fundiRating,
      'applicantsCount': applicantsCount,
      'scheduledDate': scheduledDate?.toIso8601String(),
      'status': status.toString().split('.').last,
      'serviceFee': serviceFee,
      'fundiEarnings': fundiEarnings,
      'latitude': latitude,
      'longitude': longitude,
      'fundiLatitude': fundiLatitude,
      'fundiLongitude': fundiLongitude,
      'destinationLatitude': destinationLatitude,
      'destinationLongitude': destinationLongitude,
      'distanceToFundi': distanceToFundi,
      'progress': progress,
      'photoUrls': photoUrls,
      'paymentStatus': paymentStatus,
      'clientPhone': clientPhone,
    };
  }
}
