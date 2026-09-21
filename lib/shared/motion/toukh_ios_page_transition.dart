import 'package:flutter/material.dart';

import 'toukh_motion.dart';

/// iOS-style page transition builders for GoRouter [CustomTransitionPage].
abstract final class ToukhPageTransitions {
  static Widget ios(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    if (ToukhMotion.reducesMotion(context)) {
      return FadeTransition(opacity: animation, child: child);
    }
    final slide = Tween<Offset>(
      begin: const Offset(0.08, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: animation, curve: ToukhMotion.iosPush));
    final fade = CurvedAnimation(parent: animation, curve: ToukhMotion.standard);
    return FadeTransition(
      opacity: fade,
      child: SlideTransition(position: slide, child: child),
    );
  }

  static Widget fadeThrough(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return FadeTransition(
      opacity: CurvedAnimation(parent: animation, curve: ToukhMotion.standard),
      child: child,
    );
  }
}
