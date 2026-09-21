import 'package:flutter/material.dart';
import '../orders/master_order_provider.dart';
import '../settings/order_acceptance_sla.dart';
import '../theme/app_colors.dart';
import '../theme/app_sizes.dart';
import '../icons/toukh_icons.dart';

/// Badge shown to customers when a pending request exceeds the warning threshold.
class AcceptanceDelayBadge extends StatelessWidget {
  const AcceptanceDelayBadge({
    super.key,
    required this.createdAt,
    required this.sla,
    required this.serviceTypeKey,
    this.waitingLabel,
    this.delayedLabel,
  });

  final DateTime? createdAt;
  final OrderAcceptanceSla sla;
  final String serviceTypeKey;
  final String? waitingLabel;
  final String? delayedLabel;

  @override
  Widget build(BuildContext context) {
    if (createdAt == null) return const SizedBox.shrink();

    final elapsed = providerIncomingOrderElapsedSince(createdAt);
    final slaMinutes = sla.minutesFor(serviceTypeKey);
    final urgency = acceptanceUrgencyFromElapsed(
      elapsed,
      slaMinutes: slaMinutes,
    );

    if (urgency == IncomingOrderUrgency.normal) {
      return const SizedBox.shrink();
    }

    final scheme = Theme.of(context).colorScheme;
    final isDelayed = urgency == IncomingOrderUrgency.critical;
    final accent = isDelayed ? scheme.error : AppColors.warning;
    final minutes = elapsed.inMinutes;
    final label = isDelayed
        ? (delayedLabel ?? 'Delayed')
        : (waitingLabel ?? 'Waiting $minutes min');

    return Container(
      margin: const EdgeInsets.only(top: 6),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppSizes.radiusFull),
        border: Border.all(color: accent.withValues(alpha: 0.45)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(ToukhIcons.clock, size: 14, color: accent),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: accent,
            ),
          ),
        ],
      ),
    );
  }
}
