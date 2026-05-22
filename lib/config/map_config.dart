import 'package:flutter_map/flutter_map.dart';

class MapConfig {
  // CartoDB Voyager — colourful light style, free, no API key required
  static const String _day =
      'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png';

  static const List<String> subdomains = ['a', 'b', 'c', 'd'];

  static List<TileLayer> tileLayers({bool dark = false, bool traffic = false}) {
    return [
      TileLayer(
        urlTemplate: _day,
        subdomains: subdomains,
        userAgentPackageName: 'com.handygo',
        maxNativeZoom: 19,
      ),
    ];
  }

  static String tileUrl({bool dark = false}) => _day;
}
