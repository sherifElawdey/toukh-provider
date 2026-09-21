import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

/// Branded gradient backdrop with transparent content slot for glass UI.
class ToukhGlassScaffold extends StatefulWidget {
  const ToukhGlassScaffold({
    required this.body,
    this.animateBackground = true,
    super.key,
  });

  final Widget body;
  final bool animateBackground;

  @override
  State<ToukhGlassScaffold> createState() => _ToukhGlassScaffoldState();
}

class _ToukhGlassScaffoldState extends State<ToukhGlassScaffold>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    );
    if (widget.animateBackground) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = widget.animateBackground ? _controller.value : 0.35;
        return DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [
                      Color.lerp(
                        const Color(0xFF0A1628),
                        AppColors.secondColor.withValues(alpha: 0.4),
                        t,
                      )!,
                      Color.lerp(
                        const Color(0xFF121C28),
                        AppColors.appColor.withValues(alpha: 0.15),
                        t,
                      )!,
                      const Color(0xFF0D1820),
                    ]
                  : [
                      Color.lerp(
                        AppColors.thirdColor.withValues(alpha: 0.55),
                        AppColors.secondColor.withValues(alpha: 0.35),
                        t,
                      )!,
                      Color.lerp(
                        AppColors.surface,
                        AppColors.appColor.withValues(alpha: 0.12),
                        t,
                      )!,
                      AppColors.surface,
                    ],
              stops: const [0.0, 0.45, 1.0],
            ),
          ),
          child: child,
        );
      },
      child: widget.body,
    );
  }
}
