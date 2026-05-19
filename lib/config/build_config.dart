import 'package:flutter/material.dart';
import 'flavor_config.dart';

class BuildConfig {
  const BuildConfig._();

  static bool get isClient => FlavorConfig.instance.isClient;
  static bool get isFundi => FlavorConfig.instance.isFundi;

  static String get appType => FlavorConfig.instance.flavor.name;
  static String get apiUrl => FlavorConfig.instance.apiUrl;
  static String get websocketUrl => FlavorConfig.instance.websocketUrl;
  static String get appName => FlavorConfig.instance.appName;
  static String get baseUrl => FlavorConfig.instance.baseUrl;

  static Color get primaryColor => FlavorConfig.instance.primaryColor;
  static Color get secondaryColor => FlavorConfig.instance.secondaryColor;

  static String get homeRoute => isClient ? '/client/home' : '/fundi/home';

  static String get jobsEndpoint =>
      isClient ? '/jobs/available' : '/jobs/nearby';

  static String get myJobsEndpoint =>
      isClient ? '/jobs/my-bookings' : '/jobs/my-jobs';

  static void printConfig() {
    debugPrint('BuildConfig:');
    debugPrint('  appType: $appType');
    debugPrint('  appName: $appName');
    debugPrint('  apiUrl: $apiUrl');
    debugPrint('  websocketUrl: $websocketUrl');
    debugPrint('  homeRoute: $homeRoute');
  }
}
