import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:handygo/providers/auth_provider.dart';
import 'package:handygo/config/flavor_config.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  static const Duration _splashDuration = Duration(seconds: 2);
  static const double _logoSize = 120;
  static const double _appNameFontSize = 32;
  static const double _taglineFontSize = 16;
  static const double _spacing32 = 32;
  static const double _spacing16 = 16;
  static const double _spacing48 = 48;

  @override
  void initState() {
    super.initState();
    // Use addPostFrameCallback to ensure widget is mounted before navigation
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _navigateToNextScreen();
    });
  }

  Future<void> _navigateToNextScreen() async {
    try {
      // Wait for splash duration
      await Future.delayed(_splashDuration);

      // Check if widget is still mounted
      if (!mounted) return;

      // Check authentication status (also verifies role matches this flavor)
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final expectedRole = FlavorConfig.instance.isClient ? 'client' : 'fundi';
      bool isLoggedIn = false;

      try {
        isLoggedIn = await authProvider.checkAuthStatus(requiredRole: expectedRole);
      } catch (e) {
        debugPrint('Auth check failed: $e');
        // Default to login screen on error
        isLoggedIn = false;
      }

      // Check mounted again before navigating
      if (!mounted) return;

      // Navigate based on auth status, role, and flavor
      final config = FlavorConfig.instance;
      if (isLoggedIn) {
        // Admin goes to admin screen regardless of flavor
        final route = authProvider.role == 'admin'
            ? '/admin'
            : (config.isClient ? '/client/home' : '/fundi/home');
        Navigator.pushReplacementNamed(context, route);
      } else {
        // Navigate to login screen
        Navigator.pushReplacementNamed(context, '/login');
      }
    } catch (e) {
      debugPrint('Navigation error: $e');
      // Fallback to login screen on any error
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/login');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final config = FlavorConfig.instance;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [config.primaryColor, config.secondaryColor],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLogo(config),
              const SizedBox(height: _spacing32),
              _buildAppName(config),
              const SizedBox(height: _spacing16),
              _buildTagline(config),
              const SizedBox(height: _spacing48),
              _buildLoadingIndicator(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogo(FlavorConfig config) {
    return Container(
      width: _logoSize,
      height: _logoSize,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Icon(
        config.isClient ? Icons.home_repair_service : Icons.construction,
        size: 60,
        color: config.primaryColor,
      ),
    );
  }

  Widget _buildAppName(FlavorConfig config) {
    return Text(
      config.appName,
      textAlign: TextAlign.center,
      style: const TextStyle(
        fontSize: _appNameFontSize,
        fontWeight: FontWeight.bold,
        color: Colors.white,
        letterSpacing: 1.5,
      ),
    );
  }

  Widget _buildTagline(FlavorConfig config) {
    final tagline = config.isClient
        ? "Find trusted fundis near you"
        : "Earn money with your skills";

    return Text(
      tagline,
      textAlign: TextAlign.center,
      style: const TextStyle(fontSize: _taglineFontSize, color: Colors.white70),
    );
  }

  Widget _buildLoadingIndicator() {
    return Semantics(
      label: 'Loading indicator',
      child: const CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
      ),
    );
  }
}
