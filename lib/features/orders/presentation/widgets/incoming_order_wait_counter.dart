import 'dart:async';

import 'package:flutter/material.dart';
import 'package:toukh_ui/toukh_ui.dart';

/// Live stopwatch from slice [createdAt], ticking every second.
class IncomingOrderWaitCounter extends StatelessWidget {
  const IncomingOrderWaitCounter({
    super.key,
    required this.elapsed,
    required this.urgency,
    this.hasPlacementTime = true,
  });

  final Duration elapsed;
  final IncomingOrderUrgency urgency;
  final bool hasPlacementTime;

  static String formatElapsed(Duration elapsed) {
    final hours = elapsed.inHours;
    final minutes = elapsed.inMinutes % 60;
    final seconds = elapsed.inSeconds % 60;
    if (hours > 0) {
      return '$hours:${minutes.toString().padLeft(2, '0')}:'
          '${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}';
  }

  Color _accentColor(ColorScheme scheme) {
    return switch (urgency) {
      IncomingOrderUrgency.critical => scheme.error,
      IncomingOrderUrgency.warning => AppColors.warning,
      IncomingOrderUrgency.normal => AppColors.secondColor,
    };
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final accent = _accentColor(scheme);
    final label = hasPlacementTime ? formatElapsed(elapsed) : '--:--';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accent.withValues(alpha: 0.45)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(ToukhIcons.clock, size: 14, color: accent),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: accent,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

/// Rebuilds [builder] every second from slice [createdAt] while incoming.
class IncomingOrderTimedBuilder extends StatefulWidget {
  const IncomingOrderTimedBuilder({
    super.key,
    required this.row,
    required this.builder,
  });

  final ProviderMasterOrderRow row;
  final Widget Function(
    BuildContext context,
    Duration elapsed,
    IncomingOrderUrgency urgency,
    bool hasPlacementTime,
  ) builder;

  @override
  State<IncomingOrderTimedBuilder> createState() =>
      _IncomingOrderTimedBuilderState();
}

class _IncomingOrderTimedBuilderState extends State<IncomingOrderTimedBuilder> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _syncTimer();
  }

  @override
  void didUpdateWidget(IncomingOrderTimedBuilder oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.row.id != widget.row.id ||
        oldWidget.row.slice.createdAt?.millisecondsSinceEpoch !=
            widget.row.slice.createdAt?.millisecondsSinceEpoch) {
      setState(() {});
      _syncTimer();
    }
  }

  DateTime? get _placementTime => providerSlicePlacementTime(widget.row.slice);

  void _syncTimer() {
    _timer?.cancel();
    _timer = null;
    if (_placementTime == null) return;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final placedAt = _placementTime;
    final hasPlacementTime = placedAt != null;
    final elapsed = providerIncomingOrderElapsedSince(placedAt);
    final urgency = hasPlacementTime
        ? providerIncomingOrderUrgencyFromElapsed(elapsed)
        : IncomingOrderUrgency.normal;
    return widget.builder(
      context,
      elapsed,
      urgency,
      hasPlacementTime,
    );
  }
}

/// Card surface colors for [IncomingOrderUrgency].
({Color background, Color border, double borderWidth}) incomingOrderUrgencyDecoration(
  IncomingOrderUrgency urgency,
  ColorScheme scheme,
) {
  return switch (urgency) {
    IncomingOrderUrgency.critical => (
        background: scheme.errorContainer.withValues(alpha: 0.35),
        border: scheme.error,
        borderWidth: 1.5,
      ),
    IncomingOrderUrgency.warning => (
        background: AppColors.warning.withValues(alpha: 0.16),
        border: AppColors.warning,
        borderWidth: 1.5,
      ),
    IncomingOrderUrgency.normal => (
        background: scheme.surfaceContainerHighest.withValues(alpha: 0.45),
        border: Colors.transparent,
        borderWidth: 0,
      ),
  };
}
