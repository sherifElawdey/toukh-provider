import 'package:flutter/material.dart';

/// Optional extra bottom margin for [AppSnack] when a screen has a persistent
/// bottom bar (e.g. shell navigation) above the safe area.
class AppSnackInsets extends InheritedWidget {
  const AppSnackInsets({
    super.key,
    required this.bottomInset,
    required super.child,
  });

  final double bottomInset;

  static AppSnackInsets? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<AppSnackInsets>();
  }

  @override
  bool updateShouldNotify(AppSnackInsets oldWidget) {
    return bottomInset != oldWidget.bottomInset;
  }
}
