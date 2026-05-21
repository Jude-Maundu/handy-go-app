import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class TomTomService {
  static const String _key = 'sEQDj4OdM1V5fJQQ5aNkkBwSoGfhoneh';

  /// Returns road-following route points between two coordinates.
  static Future<List<LatLng>> getRoute(LatLng origin, LatLng dest) async {
    final url =
        'https://api.tomtom.com/routing/1/calculateRoute'
        '/${origin.latitude},${origin.longitude}'
        ':${dest.latitude},${dest.longitude}'
        '/json?key=$_key&travelMode=car&traffic=true';
    try {
      final resp = await http.get(Uri.parse(url));
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        final points =
            data['routes'][0]['legs'][0]['points'] as List<dynamic>;
        return points
            .map((p) => LatLng(
                  (p['latitude'] as num).toDouble(),
                  (p['longitude'] as num).toDouble(),
                ))
            .toList();
      }
    } catch (_) {}
    return [];
  }

  /// Converts an address string to coordinates (Kenya-biased).
  static Future<LatLng?> geocode(String address) async {
    final encoded = Uri.encodeComponent(address);
    final url =
        'https://api.tomtom.com/search/2/geocode/$encoded.json'
        '?key=$_key&countrySet=KE&limit=1';
    try {
      final resp = await http.get(Uri.parse(url));
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        final results = data['results'] as List<dynamic>;
        if (results.isNotEmpty) {
          final pos = results[0]['position'];
          return LatLng(
            (pos['lat'] as num).toDouble(),
            (pos['lon'] as num).toDouble(),
          );
        }
      }
    } catch (_) {}
    return null;
  }

  /// Reverse geocode: coordinates → nearest address string.
  static Future<String?> reverseGeocode(LatLng point) async {
    final url =
        'https://api.tomtom.com/search/2/reverseGeocode'
        '/${point.latitude},${point.longitude}.json?key=$_key';
    try {
      final resp = await http.get(Uri.parse(url));
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        final results = data['addresses'] as List<dynamic>;
        if (results.isNotEmpty) {
          return results[0]['address']['freeformAddress'] as String?;
        }
      }
    } catch (_) {}
    return null;
  }
}
