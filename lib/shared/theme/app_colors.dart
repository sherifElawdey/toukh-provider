import 'package:flutter/material.dart';

/// Brand palette for Toukh apps (consumer + delivery).
abstract final class AppColors {
  static const Color appColor = Color(0xFF4EC3E0);
  static const Color secondColor = Color(0xFF2D70BA);
  static const Color thirdColor = Color(0xFFB2EBF2);

  static const Color success = Color(0xFF2E7D32);

  static const Color error = Color(0xFFB3261E);
  static const Color onError = Color(0xFFFFFFFF);

  static const Color warning = Color(0xFFF57C00);
  static const Color onWarning = Color(0xFFFFFFFF);

  static const Color surface = Color(0xFFFFFFFF);
  static const Color onSurface = Color(0xFF1A2B3C);

  static const Color bottomNavPill = appColor;

  /// Hairline glass borders: barely-there, semi-transparent.
  static Color get borderSubtle => appColor.withValues(alpha: 0.14);

  /// Semi-transparent neutral hairline (was opaque grey).
  static const Color borderStrong = Color(0x2E9E9E9E);

  static const Color borderFocus = appColor;

  static Color get scrim => const Color(0xFF000000).withValues(alpha: 0.48);

  static const Color transparent = Color(0x00000000);

  static Color get splashTitle => appColor;

  static Color get inputTextHidden => onSurface.withValues(alpha: 0.001);

  static Color fieldFill(BuildContext context) =>
      thirdColor.withValues(alpha: 0.45);
}
