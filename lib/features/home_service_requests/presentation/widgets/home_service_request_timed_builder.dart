import 'dart:async';

import 'package:flutter/material.dart';
import 'package:toukh_provider/domain/entities/provider_home_service_request.dart';
import 'package:toukh_ui/toukh_ui.dart';

/// Rebuilds [builder] every second from request [createdAt] while incoming.
class HomeServiceRequestTimedBuilder extends StatefulWidget {
  const HomeServiceRequestTimedBuilder({
    super.key,
    required this.request,
    required this.builder,
  });

  final ProviderHomeServiceRequest request;
  final Widget Function(
    BuildContext context,
    Duration elapsed,
    IncomingOrderUrgency urgency,
    bool hasCreatedTime,
  ) builder;

  @override
  State<HomeServiceRequestTimedBuilder> createState() =>
      _HomeServiceRequestTimedBuilderState();
}

class _HomeServiceRequestTimedBuilderState
    extends State<HomeServiceRequestTimedBuilder> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _syncTimer();
  }

  @override
  void didUpdateWidget(HomeServiceRequestTimedBuilder oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.request.id != widget.request.id ||
        oldWidget.request.createdAt?.millisecondsSinceEpoch !=
            widget.request.createdAt?.millisecondsSinceEpoch) {
      setState(() {});
      _syncTimer();
    }
  }

  DateTime? get _createdAt => widget.request.createdAt;

  void _syncTimer() {
    _timer?.cancel();
    _timer = null;
    if (_createdAt == null) return;
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
    final createdAt = _createdAt;
    final hasCreatedTime = createdAt != null;
    final elapsed = providerIncomingOrderElapsedSince(createdAt);
    final urgency = hasCreatedTime
        ? providerIncomingOrderUrgencyFromElapsed(elapsed)
        : IncomingOrderUrgency.normal;
    return widget.builder(
      context,
      elapsed,
      urgency,
      hasCreatedTime,
    );
  }
}
