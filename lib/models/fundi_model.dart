import 'package:handygo/models/location_model.dart';

class FundiModel {
  final String id;
  final String userId;
  final String profession;
  final List<String> skills;
  final double rating;
  final int completedJobs;
  final double experienceYears;
  final bool isAvailable;
  final String? idNumber;
  final String? certificateUrl;
  final double pricePerHour;
  final LocationModel? currentLocation;
  final List<String> portfolioImages;

  FundiModel({
    required this.id,
    required this.userId,
    required this.profession,
    required this.skills,
    this.rating = 0.0,
    this.completedJobs = 0,
    this.experienceYears = 0,
    this.isAvailable = true,
    this.idNumber,
    this.certificateUrl,
    required this.pricePerHour,
    this.currentLocation,
    this.portfolioImages = const [],
  });

  factory FundiModel.fromJson(Map<String, dynamic> json) {
    return FundiModel(
      id: json['id'] as String,
      userId: json['userId'] as String,
      profession: json['profession'] as String,
      skills: List<String>.from(json['skills'] ?? []),
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      completedJobs: json['completedJobs'] as int? ?? 0,
      experienceYears: (json['experienceYears'] as num?)?.toDouble() ?? 0.0,
      isAvailable: json['isAvailable'] as bool? ?? true,
      idNumber: json['idNumber'] as String?,
      certificateUrl: json['certificateUrl'] as String?,
      pricePerHour: (json['pricePerHour'] as num).toDouble(),
      currentLocation: json['currentLocation'] != null 
          ? LocationModel.fromJson(json['currentLocation']) 
          : null,
      portfolioImages: List<String>.from(json['portfolioImages'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'profession': profession,
      'skills': skills,
      'rating': rating,
      'completedJobs': completedJobs,
      'experienceYears': experienceYears,
      'isAvailable': isAvailable,
      'idNumber': idNumber,
      'certificateUrl': certificateUrl,
      'pricePerHour': pricePerHour,
      'currentLocation': currentLocation?.toJson(),
      'portfolioImages': portfolioImages,
    };
  }
}