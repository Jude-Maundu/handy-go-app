class LocationModel {
  final double latitude;
  final double longitude;
  final String? address;
  final String? city;
  final String? country;

  LocationModel({
    required this.latitude,
    required this.longitude,
    this.address,
    this.city,
    this.country,
  });

  factory LocationModel.fromJson(Map<String, dynamic> json) {
    return LocationModel(
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      address: json['address'] as String?,
      city: json['city'] as String?,
      country: json['country'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
      'city': city,
      'country': country,
    };
  }

  // Calculate distance to another location in km
  double distanceTo(LocationModel other) {
    const double earthRadius = 6371;
    double dLat = _toRadians(other.latitude - latitude);
    double dLon = _toRadians(other.longitude - longitude);
    
    double a = _sin(dLat / 2) * _sin(dLat / 2) +
        _cos(_toRadians(latitude)) * _cos(_toRadians(other.latitude)) *
        _sin(dLon / 2) * _sin(dLon / 2);
    
    double c = 2 * _atan2(_sqrt(a), _sqrt(1 - a));
    return earthRadius * c;
  }

  double _toRadians(double degree) => degree * 3.141592653589793 / 180;
  double _sin(double x) => throw UnimplementedError();
  double _cos(double x) => throw UnimplementedError();
  double _sqrt(double x) => throw UnimplementedError();
  double _atan2(double y, double x) => throw UnimplementedError();
}