import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:toukh_provider/domain/entities/order_history_stats.dart';
import 'package:toukh_provider/l10n/app_strings.dart';
import 'package:toukh_ui/toukh_ui.dart';

class OrderHistoryStatsHeader extends StatelessWidget {
  const OrderHistoryStatsHeader({
    super.key,
    required this.stats,
    this.loading = false,
  });

  final OrderHistoryStats stats;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(AppSizes.spaceLg),
      decoration: BoxDecoration(
        color: AppColors.thirdColor.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: loading
          ? const Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          : Row(
              children: [
                Expanded(
                  child: _StatCell(
                    label: AppStrings.OrderHistory.totalOrders.tr,
                    value: stats.totalOrders,
                    color: scheme.onSurface,
                  ),
                ),
                Container(
                  width: 1,
                  height: 48,
                  color: AppColors.borderSubtle,
                ),
                Expanded(
                  child: _StatCell(
                    label: AppStrings.OrderHistory.completedOrders.tr,
                    value: stats.completedOrders,
                    color: AppColors.success,
                  ),
                ),
                Container(
                  width: 1,
                  height: 48,
                  color: AppColors.borderSubtle,
                ),
                Expanded(
                  child: _StatCell(
                    label: AppStrings.OrderHistory.canceledOrders.tr,
                    value: stats.canceledOrders,
                    color: AppColors.error,
                  ),
                ),
              ],
            ),
    );
  }
}

class _StatCell extends StatelessWidget {
  const _StatCell({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        CustomText(
          '$value',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w900,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        CustomText(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: scheme.onSurface.withValues(alpha: 0.62),
          ),
        ),
      ],
    );
  }
}
