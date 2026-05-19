import 'package:flutter/material.dart';
import 'app.dart';
import 'config/flavor_config.dart';

void main() {
  FlavorConfig.setFlavor(
    const FlavorConfig(
      flavor: Flavor.client,
      appName: 'HandyGo Client',
      appId: 'com.handygo.client',
      primaryColor: Color(0xFF2196F3),
      secondaryColor: Color(0xFF1976D2),
      baseUrl: 'https://api.handygo.com',
    ),
  );

  runApp(const MyApp());
}
