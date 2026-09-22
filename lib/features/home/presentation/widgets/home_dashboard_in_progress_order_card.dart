import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:toukh_provider/core/router/app_routes.dart';
import 'package:toukh_provider/domain/entities/provider_dashboard_order.dart';
import 'package:toukh_provider/features/home/presentation/widgets/dashboard_shell.dart';
import 'package:toukh_provider/features/home/presentation/widgets/home_dashboard_section_helpers.dart';
import 'package:toukh_provider/features/orders/presentation/widgets/incoming_order_wait_counter.dart';
import 'package:toukh_provider/l10n/app_strings.dart';
import 'package:toukh_ui/toukh_ui.dart';

class HomeDashboardInProgressOrderCard extends StatelessWidget {
  const HomeDashboardInProgressOrderCard({super.key, required this.order});

  final ProviderOrderDashboard order;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final subtle = scheme.onSurface.withValues(alpha: 0.62);
    final timerAnchor = order.acceptedAt ?? order.createdAt;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: () => context.go(AppRoutes.orders),
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          width: 172,
          decoration: dashboardSoftDecoration(context),
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.appColor.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: CustomText(
                  dashboardOrderStatusLabel(order),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.appColor,
                  ),
                ),
              ),
              CustomText(
                order.hideCustomerContact
                    ? AppStrings.Orders.pharmacyRequestCustomerLabel.tr
                    : order.customerName ??
                        '${AppStrings.Home.dashboardOrderShort.tr} #${order.id.length > 6 ? order.id.substring(0, 6) : order.id}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  color: scheme.onSurface,
                ),
              ),
              CustomText(
                formatDashboardEgp(context, order.totalEgp),
                style: TextStyle(
                  fontSize: 13,
                  color: subtle,
                  fontWeight: FontWeight.w600,
                ),
              ),
              _HomeOrderElapsedTimer(anchor: timerAnchor),
            ],
          ),
        ),
      ),
    );
  }
}

/// Live mm:ss (or h:mm:ss) since [anchor]; shows `--:--` when missing.
class _HomeOrderElapsedTimer extends StatefulWidget {
  const _HomeOrderElapsedTimer({required this.anchor});

  final DateTime? anchor;

  @override
  State<_HomeOrderElapsedTimer> createState() => _HomeOrderElapsedTimerState();
}

class _HomeOrderElapsedTimerState extends State<_HomeOrderElapsedTimer> {
  Timer? _timer;
  Duration _elapsed = Duration.zero;

  @override
  void initState() {
    super.initState();
    _tick();
    if (widget.anchor != null) {
      _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
    }
  }

  @override
  void didUpdateWidget(covariant _HomeOrderElapsedTimer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.anchor != widget.anchor) {
      _timer?.cancel();
      _tick();
      if (widget.anchor != null) {
        _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
      }
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _tick() {
    final anchor = widget.anchor;
    if (anchor == null) {
      if (_elapsed != Duration.zero) {
        setState(() => _elapsed = Duration.zero);
      }
      return;
    }
    final next = DateTime.now().difference(anchor);
    if (next != _elapsed) {
      setState(() => _elapsed = next.isNegative ? Duration.zero : next);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final label = widget.anchor == null
        ? '--:--'
        : IncomingOrderWaitCounter.formatElapsed(_elapsed);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(ToukhIcons.clock, size: 13, color: AppColors.secondColor),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: scheme.onSurface.withValues(alpha: 0.75),
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}
