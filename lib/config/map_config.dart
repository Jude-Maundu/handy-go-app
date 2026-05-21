import 'package:flutter_map/flutter_map.dart';

class MapConfig {
  // CartoDB — free, no key, reliable on all devices
  static const String _night =
      'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png';
  static const String _day =
      'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png';

  static const List<String> subdomains = ['a', 'b', 'c', 'd'];

  static List<TileLayer> tileLayers({required bool dark, bool traffic = false}) {
    return [
      TileLayer(
        urlTemplate: dark ? _night : _day,
        subdomains: subdomains,
        userAgentPackageName: 'com.handygo',
        maxNativeZoom: 19,
      ),
    ];
  }

  static String tileUrl({required bool dark}) => dark ? _night : _day;
}
