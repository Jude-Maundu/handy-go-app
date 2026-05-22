import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../app.dart';
import '../config/flavor_config.dart';
import '../firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');

  FlavorConfig.setFlavor(
    const FlavorConfig(
      flavor: Flavor.client,
      appName: 'HandyGo Client',
      appId: 'com.handygo.client',
      primaryColor: Color(0xFFF5C518),
      secondaryColor: Color(0xFFE6B800),
      baseUrl: 'https://api.handygo.com',
    ),
  );

  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
  } catch (e) {
    runApp(_FirebaseErrorApp(error: e.toString()));
    return;
  }

  runApp(const MyApp());
}

class _FirebaseErrorApp extends StatelessWidget {
  final String error;
  const _FirebaseErrorApp({required this.error});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: const Color(0xFF2196F3),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.cloud_off, size: 72, color: Colors.white),
                const SizedBox(height: 24),
                const Text('Firebase not configured',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 12),
                const Text(
                  'Run: flutterfire configure\nin your project folder.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70, fontSize: 15),
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(8)),
                  child: Text(error, style: const TextStyle(color: Colors.white60, fontSize: 11)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
