import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../widgets/app_logo_loading.dart';

class AppLoadingMark extends StatelessWidget {
  const AppLoadingMark({super.key});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: AppColors.thirdColor.withValues(alpha: 0.65),
            blurRadius: 36,
            spreadRadius: 4,
          ),
        ],
      ),
      child: const Padding(
        padding: EdgeInsets.all(20),
        child: AppLogoLoading(),
      ),
    );
  }
}

/// How [AppLoading.showWhile] presents the blocking loader.
enum AppLoadingPresentation {
  /// Root [Navigator] [DialogRoute] — modal barrier and route semantics (focus, back).
  dialog,

  /// Root [Overlay] [OverlayEntry] — use when a dialog route is problematic
  /// (e.g. nested navigator); not dismissible via barrier tap.
  overlay,
}

/// Full-screen scrim + centered [AppLoadingMark]. Shared by dialog body, overlay entry,
/// and [AppLoadingOverlay].
class _AppLoadingScrim extends StatelessWidget {
  const _AppLoadingScrim();

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: SizedBox.expand(
        child: ColoredBox(
          color: AppColors.scrim,
          child: const Center(child: AppLoadingMark()),
        ),
      ),
    );
  }
}

class AppLoadingOverlay extends StatelessWidget {
  const AppLoadingOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return const Positioned.fill(
      child: _AppLoadingScrim(),
    );
  }
}

abstract final class AppLoading {
  const AppLoading._();

  /// Runs [task] while showing the blocking loader (dialog or root overlay).
  ///
  /// [presentation.dialog] uses a [DialogRoute] with [useSafeArea]: false so the
  /// scrim fills the screen; barrier uses [Colors.transparent] and the scrim is
  /// drawn by [_AppLoadingScrim].
  ///
  /// [presentation.overlay] inserts an [OverlayEntry] on the root overlay.
  static Future<T> showWhile<T>(
    BuildContext context,
    Future<T> Function() task, {
    AppLoadingPresentation presentation = AppLoadingPresentation.dialog,
    bool barrierDismissible = false,
  }) async {
    if (!context.mounted) {
      throw StateError('AppLoading.showWhile: context is not mounted');
    }

    return switch (presentation) {
      AppLoadingPresentation.dialog => _showWhileDialog<T>(
          context,
          task,
          barrierDismissible: barrierDismissible,
        ),
      AppLoadingPresentation.overlay => _showWhileOverlay<T>(context, task),
    };
  }

  static Future<T> _showWhileDialog<T>(
    BuildContext context,
    Future<T> Function() task, {
    required bool barrierDismissible,
  }) async {
    final navigator = Navigator.of(context, rootNavigator: true);

    final route = DialogRoute<void>(
      context: context,
      barrierDismissible: barrierDismissible,
      barrierColor: Colors.transparent,
      useSafeArea: false,
      builder: (_) => PopScope(
        canPop: barrierDismissible,
        child: const _AppLoadingScrim(),
      ),
    );

    navigator.push(route);
    await WidgetsBinding.instance.endOfFrame;

    try {
      return await task();
    } finally {
      if (route.isActive) {
        navigator.removeRoute(route);
      }
    }
  }

  static Future<T> _showWhileOverlay<T>(
    BuildContext context,
    Future<T> Function() task,
  ) async {
    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null) {
      throw StateError('AppLoading.showWhile: root overlay is unavailable');
    }

    final entry = OverlayEntry(
      builder: (_) => const _AppLoadingScrim(),
    );
    overlay.insert(entry);
    await WidgetsBinding.instance.endOfFrame;

    try {
      return await task();
    } finally {
      if (entry.mounted) {
        entry.remove();
      }
    }
  }

  /// Prefer [showWhile].
  @Deprecated('Use AppLoading.showWhile instead')
  static Future<T> run<T>(
    BuildContext context,
    Future<T> Function() task, {
    bool barrierDismissible = false,
  }) =>
      showWhile<T>(
        context,
        task,
        presentation: AppLoadingPresentation.dialog,
        barrierDismissible: barrierDismissible,
      );
}

extension AppLoadingContext on BuildContext {
  Future<T> withAppLoading<T>(
    Future<T> Function() task, {
    AppLoadingPresentation presentation = AppLoadingPresentation.dialog,
    bool barrierDismissible = false,
  }) =>
      AppLoading.showWhile<T>(
        this,
        task,
        presentation: presentation,
        barrierDismissible: barrierDismissible,
      );
}
