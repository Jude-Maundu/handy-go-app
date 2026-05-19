class MapConstants {
  // Default location (Nairobi, Kenya - adjust to your city)
  static const double defaultLatitude = -1.286389;
  static const double defaultLongitude = 36.817223;
  static const double defaultZoom = 13.0;

  // Map style (FREE - OpenStreetMap)
  static const String mapStyleUrl =
      'https://tiles.openstreetmap.org/{z}/{x}/{y}.png';

  // For MapLibre - use this style URL
  static const String maplibreStyle =
      'https://demotiles.maplibre.org/style.json';

  // Distance thresholds (in meters)
  static const double fundiArrivedThreshold = 50.0; // Fundi arrived at client
  static const double fundiNearbyThreshold = 200.0; // Fundi is nearby

  // Update intervals (in seconds)
  static const int locationUpdateInterval = 5; // Update every 5 seconds
  static const int etaUpdateInterval = 10; // Update ETA every 10 seconds
}
