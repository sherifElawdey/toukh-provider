import 'dart:async';

import 'package:flutter/material.dart';
import 'package:toukh_provider/di/service_locator.dart';
import 'package:toukh_provider/domain/repositories/provider_drivers_repository.dart';
import 'package:toukh_ui/toukh_ui.dart';

/// Puts the number of couriers waiting for approval before [child].
class DriverRequestsBadge extends StatefulWidget {
  const DriverRequestsBadge({
    super.key,
    required this.providerId,
    required this.child,
  });

  final String providerId;
  final Widget child;

  @override
  State<DriverRequestsBadge> createState() => _DriverRequestsBadgeState();
}

class _DriverRequestsBadgeState extends State<DriverRequestsBadge> {
  StreamSubscription<ProviderDriversSnapshot>? _sub;
  int _pending = 0;

  @override
  void initState() {
    super.initState();
    _listen();
  }

  @override
  void didUpdateWidget(covariant DriverRequestsBadge old) {
    super.didUpdateWidget(old);
    if (old.providerId != widget.providerId) _listen();
  }

  void _listen() {
    _sub?.cancel();
    if (widget.providerId.isEmpty) return;
    _sub = getIt<ProviderDriversRepository>()
        .watchDrivers(widget.providerId)
        .listen(
          (snap) {
            if (mounted && snap.pendingRequests.length != _pending) {
              setState(() => _pending = snap.pendingRequests.length);
            }
          },
          onError: (Object _) {},
        );
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_pending == 0) return widget.child;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          constraints: const BoxConstraints(minWidth: 22),
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: AppColors.error,
            borderRadius: BorderRadius.circular(11),
          ),
          child: Text(
            '$_pending',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(width: 6),
        widget.child,
      ],
    );
  }
}
