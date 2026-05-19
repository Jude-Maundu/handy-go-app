import 'package:flutter/material.dart';

enum Flavor { client, fundi }

class FlavorConfig {
  final Flavor flavor;
  final String appName;
  final String appId;
  final Color primaryColor;
  final Color secondaryColor;
  final String baseUrl;

  const FlavorConfig({
    required this.flavor,
    required this.appName,
    required this.appId,
    required this.primaryColor,
    required this.secondaryColor,
    required this.baseUrl,
  });

  static late FlavorConfig _instance;

  static bool get _initialized {
    try {
      _instance;
      return true;
    } catch (_) {
      return false;
    }
  }

  static void setFlavor(FlavorConfig config) {
    _instance = config;
  }

  static FlavorConfig get instance {
    if (!_initialized) {
      throw Exception(
        'FlavorConfig has not been initialized. Call FlavorConfig.setFlavor() before using the app.',
      );
    }
    return _instance;
  }

  bool get isClient => flavor == Flavor.client;
  bool get isFundi => flavor == Flavor.fundi;

  String get apiUrl {
    final envApiUrl = const String.fromEnvironment('API_URL', defaultValue: '');
    return envApiUrl.isNotEmpty ? envApiUrl : baseUrl;
  }

  String get websocketUrl {
    final envWsUrl = const String.fromEnvironment(
      'WEBSOCKET_URL',
      defaultValue: '',
    );
    return envWsUrl.isNotEmpty ? envWsUrl : '$baseUrl/ws';
  }

  bool get isProduction =>
      const bool.fromEnvironment('isProduction', defaultValue: false);

  String get environment =>
      const String.fromEnvironment('ENV', defaultValue: 'dev');

  @override
  String toString() {
    return 'FlavorConfig(flavor: ${flavor.name}, appName: $appName, appId: $appId, baseUrl: $baseUrl)';
  }
}
