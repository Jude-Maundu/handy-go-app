import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'config/build_config.dart';
import 'config/flavor_config.dart';
import 'constants/app_theme.dart';
import 'providers/auth_provider.dart';
import 'providers/job_provider.dart';
import 'providers/location_provider.dart';
import 'providers/admin_provider.dart';
import 'providers/theme_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/auth/reset_password.dart';
import 'screens/client/home_screen.dart';
import 'screens/client/request_fundi_screen.dart';
import 'screens/client/search_screen.dart';
import 'screens/client/payments_screen.dart';
import 'screens/fundi/home_screen.dart';
import 'screens/fundi/earnings_screen.dart';
import 'screens/fundi/navigate_screen.dart';
import 'screens/fundi/schedule_screen.dart';
import 'screens/fundi/withdrawal_screen.dart';
import 'screens/sharedscreens/splash_screen.dart';
import 'screens/sharedscreens/notification_screen.dart';
import 'screens/sharedscreens/settings_screen.dart';
import 'screens/sharedscreens/help_screen.dart';
import 'screens/admin/admin_dash.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final config = FlavorConfig.instance;
    BuildConfig.printConfig();

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => LocationProvider()),
        ChangeNotifierProvider(create: (_) => JobProvider()),
        ChangeNotifierProvider(create: (_) => AdminProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) => MaterialApp(
        title: config.appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme(config.primaryColor),
        darkTheme: AppTheme.darkTheme(config.primaryColor),
        themeMode: themeProvider.mode,
        home: const SplashScreen(),
        routes: {
          '/login': (_) => const LoginScreen(),
          '/register': (_) => const RegisterScreen(),
          '/reset': (_) => const ResetPasswordScreen(),
          // Client
          '/client/home': (_) => const ClientMainScreen(),
          '/request-fundi': (_) => const RequestFundiScreen(),
          '/search': (_) => const ClientSearchScreen(),
          '/payments': (_) => const PaymentsScreen(),
          // Fundi
          '/fundi/home': (_) => const FundiMainScreen(),
          '/fundi/earnings': (_) => const EarningsScreen(),
          '/fundi/navigate': (_) => const NavigateScreen(),
          '/fundi/schedule': (_) => const FundiScheduleScreen(),
          '/fundi/withdrawal': (_) => const WithdrawalScreen(),
          // Shared
          '/notifications': (_) => const NotificationScreen(),
          '/settings': (_) => const SettingsScreen(),
          '/help': (_) => const HelpScreen(),
          // Admin (all tabs live inside AdminDashScreen)
          '/admin': (_) => const AdminDashScreen(),
        },
      ),
      ),
    );
  }
}
