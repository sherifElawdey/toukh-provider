import 'dart:ui';

import 'package:flutter/material.dart';

import '../../theme/glass_tokens.dart';
import '../../motion/toukh_motion.dart';

/// Full-width frosted bar (nav header, sidebar panel edge).
class ToukhGlassSurface extends StatelessWidget {
  const ToukhGlassSurface({
    required this.child,
    this.showShadow = false,
    this.borderOnTop = false,
    this.useBlur = true,
    super.key,
  });

  final Widget child;
  final bool showShadow;
  final bool borderOnTop;
  final bool useBlur;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = GlassTokens.borderColor(context);
    final reduceBlur = ToukhMotion.reducesMotion(context) || !useBlur;

    final content = DecoratedBox(
      decoration: BoxDecoration(
        color: GlassTokens.fillBar(context),
        border: Border(
          top: borderOnTop ? BorderSide(color: borderColor) : BorderSide.none,
          bottom:
              borderOnTop ? BorderSide.none : BorderSide(color: borderColor),
        ),
        boxShadow: showShadow
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.12),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ]
            : null,
      ),
      child: SizedBox(width: double.infinity, child: child),
    );

    if (reduceBlur) {
      return content;
    }

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: GlassTokens.blurBar,
          sigmaY: GlassTokens.blurBar,
        ),
        child: content,
      ),
    );
  }
}
