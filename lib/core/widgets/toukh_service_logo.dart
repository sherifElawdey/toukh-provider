import 'package:flutter/material.dart';
import 'package:toukh_provider/shared/shared.dart';

/// Havit brand mark used across provider auth, registration, and status UI.
class ToukhServiceLogo extends StatelessWidget {
  const ToukhServiceLogo({
    super.key,
    this.size = 88,
    this.fit = BoxFit.contain,
    this.borderRadius,
  });

  final double size;
  final BoxFit fit;
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    return HavitBrandIcon(
      size: size,
      fit: fit,
      borderRadius: borderRadius,
    );
  }
}
