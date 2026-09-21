import 'package:flutter/material.dart';

/// Spacing, typography scale, radii, and icon sizes used across Toukh apps.
abstract final class AppSizes {
  static const double spaceXs = 4;
  static const double spaceSm = 8;
  static const double spaceMd = 12;
  static const double spaceBase = 16;
  static const double spaceLg = 20;
  static const double spaceXl = 24;
  static const double space2xl = 32;
  static const double space3xl = 40;
  static const double space4xl = 48;

  static const double radiusSm = 10;
  static const double radiusMd = 14;
  static const double radiusLg = 18;
  static const double radiusXl = 24;
  static const double radiusFull = 999;

  static const double fontDisplay = 28;
  static const double fontHeadline = 24;
  static const double fontTitle = 18;
  static const double fontBody = 16;
  static const double fontLabel = 14;
  static const double fontCaption = 12;

  static const double iconSm = 20;
  static const double iconMd = 22;
  static const double iconLg = 28;

  static const double logoAuth = 88;

  static const double logoLoading = 104;

  static EdgeInsets get screenHorizontal =>
      const EdgeInsets.symmetric(horizontal: spaceXl);

  static EdgeInsets get screenPadding =>
      const EdgeInsets.symmetric(horizontal: spaceBase, vertical: spaceMd);
}
