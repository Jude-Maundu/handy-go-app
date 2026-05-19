import 'package:flutter/material.dart';
import '../../config/flavor_config.dart';
import '../../constants/app_colors.dart';

class AuthHeader extends StatelessWidget {
  final Color accent;
  final bool isDark;
  const AuthHeader({super.key, required this.accent, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(28, 60, 28, 40),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            accent.withValues(alpha: isDark ? 0.25 : 0.18),
            accent.withValues(alpha: isDark ? 0.08 : 0.05),
          ],
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.15),
              shape: BoxShape.circle,
              border: Border.all(color: accent.withValues(alpha: 0.3), width: 2),
            ),
            child: Icon(Icons.home_repair_service, color: accent, size: 36),
          ),
          const SizedBox(height: 14),
          Text(
            FlavorConfig.instance.appName,
            style: TextStyle(
              color: accent,
              fontSize: 22,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            FlavorConfig.instance.isClient
                ? 'Find skilled fundis near you'
                : 'Earn by sharing your skills',
            style: TextStyle(color: AC.textSec(context), fontSize: 13),
          ),
        ],
      ),
    );
  }
}
