import 'package:flutter/material.dart';
import '../config/map_config.dart';

class AppColors {
  // Dark palette
  static const Color background = Color(0xFF0D0D1A);
  static const Color surface = Color(0xFF1A1A2E);
  static const Color card = Color(0xFF16213E);
  static const Color inputFill = Color(0xFF1E1E30);
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Color(0xFF8E8EA0);
  static const Color divider = Color(0xFF2A2A3E);

  // Light palette
  static const Color backgroundLight = Color(0xFFF5F5F7);
  static const Color surfaceLight = Colors.white;
  static const Color cardLight = Colors.white;
  static const Color inputFillLight = Color(0xFFEEEEF2);
  static const Color textPrimaryLight = Color(0xFF0D0D1A);
  static const Color textSecondaryLight = Color(0xFF6E6E80);
  static const Color dividerLight = Color(0xFFE5E5EA);

  // Accents (same for both modes)
  static const Color yellow = Color(0xFFF5C518);
  static const Color green = Color(0xFF4CAF50);
}

// Use AC.xxx(context) everywhere instead of AppColors.xxx constants
class AC {
  static bool _dark(BuildContext ctx) => Theme.of(ctx).brightness == Brightness.dark;

  static Color bg(BuildContext ctx) => _dark(ctx) ? AppColors.background : AppColors.backgroundLight;
  static Color surface(BuildContext ctx) => _dark(ctx) ? AppColors.surface : AppColors.surfaceLight;
  static Color card(BuildContext ctx) => _dark(ctx) ? AppColors.card : AppColors.cardLight;
  static Color input(BuildContext ctx) => _dark(ctx) ? AppColors.inputFill : AppColors.inputFillLight;
  static Color text(BuildContext ctx) => _dark(ctx) ? AppColors.textPrimary : AppColors.textPrimaryLight;
  static Color textSec(BuildContext ctx) => _dark(ctx) ? AppColors.textSecondary : AppColors.textSecondaryLight;
  static Color div(BuildContext ctx) => _dark(ctx) ? AppColors.divider : AppColors.dividerLight;

  // CartoDB tiles — free, no API key
  static String mapTileUrl(BuildContext ctx) =>
      MapConfig.tileUrl(dark: _dark(ctx));

  static List<String> mapSubdomains(BuildContext ctx) => MapConfig.subdomains;
}
