import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_map/flutter_map.dart';

class MapConfig {
  static String get _key => dotenv.env['TOMTOM_KEY'] ?? '';

  static String get _night =>
      'https://api.tomtom.com/map/1/tile/basic/night/{z}/{x}/{y}.png?key=$_key';
  static String get _day =>
      'https://api.tomtom.com/map/1/tile/basic/main/{z}/{x}/{y}.png?key=$_key';
  static String get _traffic =>
      'https://api.tomtom.com/traffic/map/4/tile/flow/relative-delay/{z}/{x}/{y}.png?key=$_key';

  static const List<String> subdomains = [];

  static List<TileLayer> tileLayers({required bool dark, bool traffic = true}) {
    return [
      TileLayer(
        urlTemplate: dark ? _night : _day,
        userAgentPackageName: 'com.handygo',
        maxNativeZoom: 22,
      ),
      if (traffic)
        TileLayer(
          urlTemplate: _traffic,
          userAgentPackageName: 'com.handygo',
          maxNativeZoom: 22,
          tileBuilder: (context, widget, tile) => Opacity(opacity: 0.8, child: widget),
        ),
    ];
  }

  // Legacy helpers
  static String tileUrl({required bool dark}) => dark ? _night : _day;
  static String labelsUrl() => _traffic;
}
