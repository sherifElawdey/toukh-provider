import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:toukh_provider/features/orders/presentation/widgets/incoming_order_wait_counter.dart';
import 'package:toukh_ui/toukh_ui.dart';

/// Ticking mm:ss (h:mm:ss) since [anchor] for active orders: accepted /
/// in-progress orders and orders out for delivery.
class ActiveOrderElapsedTimer extends StatefulWidget {
  const ActiveOrderElapsedTimer({
    super.key,
    required this.anchor,
    this.labelKey,
    this.fontSize = 12,
  });

  final DateTime? anchor;

  /// Optional prefix, e.g. "Since dispatch".
  final String? labelKey;
  final double fontSize;

  @override
  State<ActiveOrderElapsedTimer> createState() => _ActiveOrderElapsedTimerState();
}

class _ActiveOrderElapsedTimerState extends State<ActiveOrderElapsedTimer> {
  Timer? _timer;
  Duration _elapsed = Duration.zero;

  @override
  void initState() {
    super.initState();
    _restart();
  }

  @override
  void didUpdateWidget(covariant ActiveOrderElapsedTimer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.anchor != widget.anchor) _restart();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _restart() {
    _timer?.cancel();
    _tick();
    if (widget.anchor != null) {
      _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
    }
  }

  void _tick() {
    final anchor = widget.anchor;
    final next = anchor == null ? Duration.zero : DateTime.now().difference(anchor);
    final clamped = next.isNegative ? Duration.zero : next;
    if (clamped != _elapsed && mounted) setState(() => _elapsed = clamped);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final time = widget.anchor == null
        ? '--:--'
        : IncomingOrderWaitCounter.formatElapsed(_elapsed);
    final color = scheme.onSurface.withValues(alpha: 0.75);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(ToukhIcons.clock, size: widget.fontSize + 1, color: scheme.onSurfaceVariant),
        const SizedBox(width: 4),
        if (widget.labelKey != null) ...[
          Text(
            widget.labelKey!.tr,
            style: TextStyle(fontSize: widget.fontSize, color: color),
          ),
          const SizedBox(width: 4),
        ],
        Text(
          time,
          textDirection: TextDirection.ltr,
          style: TextStyle(
            fontSize: widget.fontSize,
            fontWeight: FontWeight.w700,
            color: color,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}
