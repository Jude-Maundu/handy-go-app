import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

/// Location Provider
/// Manages user location, coordinates, and location-based data
class LocationProvider extends ChangeNotifier {
  // Location state
  double? _latitude;
  double? _longitude;
  String? _currentCity;
  String? _currentAddress;
  bool _isLocationLoading = false;
  String? _locationError;

  // Tracking state (for Fundi app)
  Position? _currentPosition;
  StreamSubscription<Position>? _positionStream;
  bool _isTracking = false;
  bool _isSearchLoading = false;
  List<PlaceSearchResult> _searchResults = [];

  // Getters
  double? get latitude => _latitude;
  double? get longitude => _longitude;
  String? get currentCity => _currentCity;
  String? get currentAddress => _currentAddress;
  bool get isLocationLoading => _isLocationLoading;
  bool get isLoading => _isLocationLoading || _isSearchLoading;
  List<PlaceSearchResult> get searchResults => _searchResults;
  String? get locationError => _locationError;
  Position? get currentLocation => _currentPosition;
  Position? get currentPosition => _currentPosition;
  bool get isTracking => _isTracking;

  // Check if user has a location
  bool get hasLocation => _latitude != null && _longitude != null;

  /// Get user's current location with Geolocator
  Future<bool> getCurrentLocation() async {
    _isLocationLoading = true;
    _locationError = null;
    notifyListeners();

    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _locationError = 'Location services are disabled. Please enable them.';
        _isLocationLoading = false;
        notifyListeners();
        return false;
      }

      // Check and request permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _locationError =
              'Location permission denied. Please grant permission.';
          _isLocationLoading = false;
          notifyListeners();
          return false;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _locationError =
            'Location permission permanently denied. Please enable from settings.';
        _isLocationLoading = false;
        notifyListeners();
        return false;
      }

      // Get current position
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      _latitude = position.latitude;
      _longitude = position.longitude;
      _currentPosition = position;

      // Get address from coordinates
      await _getAddressFromCoordinates(position.latitude, position.longitude);

      _locationError = null;
      return true;
    } catch (e) {
      _locationError = 'Error getting location: ${e.toString()}';
      return false;
    } finally {
      _isLocationLoading = false;
      notifyListeners();
    }
  }

  /// Get address from coordinates using Geocoding
  Future<void> _getAddressFromCoordinates(
    double latitude,
    double longitude,
  ) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        latitude,
        longitude,
      );

      if (placemarks.isNotEmpty) {
        final place = placemarks.first;

        // Build a readable address
        List<String> addressParts = [];
        if (place.name != null && place.name!.isNotEmpty)
          addressParts.add(place.name!);
        if (place.street != null && place.street!.isNotEmpty)
          addressParts.add(place.street!);
        if (place.subLocality != null && place.subLocality!.isNotEmpty)
          addressParts.add(place.subLocality!);
        if (place.locality != null && place.locality!.isNotEmpty) {
          addressParts.add(place.locality!);
          _currentCity = place.locality;
        }
        if (place.administrativeArea != null &&
            place.administrativeArea!.isNotEmpty)
          addressParts.add(place.administrativeArea!);
        if (place.country != null && place.country!.isNotEmpty)
          addressParts.add(place.country!);

        _currentAddress = addressParts.join(", ");
      }
    } catch (e) {
      debugPrint('Error getting address: $e');
      _currentAddress = 'Address not found';
    }
  }

  /// Start tracking location changes (for Fundi app live tracking)
  void startTracking() {
    if (_isTracking) return;

    _isTracking = true;
    _positionStream =
        Geolocator.getPositionStream(
          locationSettings: LocationSettings(
            accuracy: LocationAccuracy.high,
            distanceFilter: 10, // Update every 10 meters
          ),
        ).listen((Position position) {
          _latitude = position.latitude;
          _longitude = position.longitude;
          _currentPosition = position;
          notifyListeners();
        });
  }

  /// Stop tracking location changes
  void stopTracking() {
    _positionStream?.cancel();
    _isTracking = false;
    notifyListeners();
  }

  /// Update location manually (for testing or manual updates)
  void updateLocation({
    required double latitude,
    required double longitude,
    String? city,
    String? address,
  }) {
    _latitude = latitude;
    _longitude = longitude;
    _currentCity = city;
    _currentAddress = address;
    _locationError = null;
    notifyListeners();
  }

  /// Get distance between two points (in kilometers)
  double? getDistance({
    required double otherLatitude,
    required double otherLongitude,
  }) {
    if (_latitude == null || _longitude == null) return null;

    // Use Geolocator's built-in distance calculation
    return Geolocator.distanceBetween(
          _latitude!,
          _longitude!,
          otherLatitude,
          otherLongitude,
        ) /
        1000; // Convert meters to kilometers
  }

  /// Get ETA string based on distance
  String getETA(double distanceInKm) {
    // Assuming average speed of 30 km/h in city
    const averageSpeed = 30.0;
    double timeInHours = distanceInKm / averageSpeed;
    int timeInMinutes = (timeInHours * 60).round();

    if (timeInMinutes < 1) return "< 1 minute";
    if (timeInMinutes == 1) return "1 minute";
    return "$timeInMinutes minutes";
  }

  /// Format distance for display
  Future<List<PlaceSearchResult>> searchLocation(String query) async {
    _isSearchLoading = true;
    notifyListeners();

    try {
      if (query.isEmpty) {
        _searchResults = [];
        return _searchResults;
      }

      final locations = await locationFromAddress(query);
      _searchResults = locations
          .map(
            (loc) => PlaceSearchResult(
              name:
                  '${loc.latitude.toStringAsFixed(4)}, ${loc.longitude.toStringAsFixed(4)}',
              address: query,
              latitude: loc.latitude,
              longitude: loc.longitude,
            ),
          )
          .toList();
      return _searchResults;
    } catch (e) {
      _searchResults = [];
      debugPrint('Location search error: $e');
      return [];
    } finally {
      _isSearchLoading = false;
      notifyListeners();
    }
  }

  String formatDistance(double distanceInKm) {
    if (distanceInKm < 1) {
      return "${(distanceInKm * 1000).round()} m";
    }
    return "${distanceInKm.toStringAsFixed(1)} km";
  }

  /// Clear location data
  void clearLocation() {
    stopTracking();
    _latitude = null;
    _longitude = null;
    _currentCity = null;
    _currentAddress = null;
    _currentPosition = null;
    _locationError = null;
    notifyListeners();
  }

  /// Clear error message
  void clearError() {
    _locationError = null;
    notifyListeners();
  }

  @override
  void dispose() {
    stopTracking();
    super.dispose();
  }
}

class PlaceSearchResult {
  final String name;
  final String address;
  final double latitude;
  final double longitude;

  PlaceSearchResult({
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
  });
}
