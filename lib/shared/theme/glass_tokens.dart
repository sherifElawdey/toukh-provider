import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Design tokens for frosted-glass surfaces (aligned with Toukh landing CSS).
abstract final class GlassTokens {
  static const double blurCard = 12;
  static const double blurBar = 16;

  static const double radiusCard = 16;
  static const double radiusBar = 0;
  static const double radiusSheet = 24;

  /// rgba(255, 255, 255, 0.72) — card fill light
  static const Color fillLightCard = Color(0xB8FFFFFF);

  /// rgba(255, 255, 255, 0.55) — bar fill light
  static const Color fillLightBar = Color(0x8CFFFFFF);

  /// rgba(18, 28, 40, 0.72) — bar fill dark
  static const Color fillDarkBar = Color(0xB8121C28);

  static Color fillCard(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark
        ? Colors.white.withValues(alpha: 0.06)
        : fillLightCard;
  }

  static Color fillBar(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? fillDarkBar : fillLightBar;
  }

  static Color borderColor(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return AppColors.appColor.withValues(alpha: isDark ? 0.25 : 0.35);
  }

  static Color borderColorSubtle(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return AppColors.appColor.withValues(alpha: isDark ? 0.15 : 0.2);
  }

  static List<BoxShadow> cardShadow({bool emphasized = false}) {
    if (emphasized) {
      return [
        BoxShadow(
          color: AppColors.appColor.withValues(alpha: 0.12),
          blurRadius: 32,
          spreadRadius: 2,
          offset: const Offset(0, 12),
        ),
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.08),
          blurRadius: 16,
          offset: const Offset(0, 4),
        ),
      ];
    }
    return [
      BoxShadow(
        color: AppColors.appColor.withValues(alpha: 0.08),
        blurRadius: 24,
        offset: const Offset(0, 8),
      ),
    ];
  }
}
