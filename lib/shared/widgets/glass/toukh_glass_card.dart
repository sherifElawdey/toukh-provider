import 'dart:ui';

import 'package:flutter/material.dart';

import '../../theme/glass_tokens.dart';
import '../../motion/toukh_motion.dart';

/// Frosted-glass card with backdrop blur.
class ToukhGlassCard extends StatelessWidget {
  const ToukhGlassCard({
    required this.child,
    this.padding,
    this.borderRadius = GlassTokens.radiusCard,
    this.emphasizedShadow = false,
    this.useBlur = true,
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double borderRadius;
  final bool emphasizedShadow;
  final bool useBlur;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(borderRadius);
    final reduceBlur = ToukhMotion.reducesMotion(context) || !useBlur;

    final content = Container(
      padding: padding ?? const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: GlassTokens.fillCard(context),
        borderRadius: radius,
        border: Border.all(color: GlassTokens.borderColorSubtle(context)),
        boxShadow: GlassTokens.cardShadow(emphasized: emphasizedShadow),
      ),
      child: child,
    );

    if (reduceBlur) {
      return ClipRRect(borderRadius: radius, child: content);
    }

    return ClipRRect(
      borderRadius: radius,
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: GlassTokens.blurCard,
          sigmaY: GlassTokens.blurCard,
        ),
        child: content,
      ),
    );
  }
}
