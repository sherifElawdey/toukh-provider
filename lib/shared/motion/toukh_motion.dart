import 'package:flutter/material.dart';

/// Shared motion constants for Toukh apps.
abstract final class ToukhMotion {
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration normal = Duration(milliseconds: 220);
  static const Duration slow = Duration(milliseconds: 320);
  static const Duration entrance = Duration(milliseconds: 450);

  static const Curve standard = Curves.easeOutCubic;
  static const Curve spring = Curves.easeOutBack;
  static const Curve iosPush = Curves.fastOutSlowIn;

  static const double fadeUpOffset = 24;

  static const Duration staggerStep = Duration(milliseconds: 60);
  static const Duration staggerDelay = Duration(milliseconds: 40);

  static bool reducesMotion(BuildContext context) =>
      MediaQuery.disableAnimationsOf(context);
}
