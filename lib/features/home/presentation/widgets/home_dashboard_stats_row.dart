import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:toukh_provider/features/home/cubit/home_dashboard_state.dart';
import 'package:toukh_provider/features/home/presentation/widgets/home_dashboard_section_helpers.dart';
import 'package:toukh_provider/features/home/presentation/widgets/home_dashboard_stat_cell.dart';
import 'package:toukh_provider/l10n/app_strings.dart';

class HomeDashboardStatsRow extends StatelessWidget {
  const HomeDashboardStatsRow({
    super.key,
    required this.metrics,
    required this.period,
  });

  final DashboardPeriodMetrics metrics;
  final DashboardChartPeriod period;

  @override
  Widget build(BuildContext context) {
    final pct = metrics.denominatorForCompletion == 0
        ? '—'
        : '${(metrics.completionRatio * 100).round()}%';

    final periodLabel = period == DashboardChartPeriod.week
        ? AppStrings.Home.dashboardPeriodWeek.tr
        : AppStrings.Home.dashboardPeriodMonth.tr;

    return Row(
      children: [
        Expanded(
          child: HomeDashboardStatCell(
            label: AppStrings.Home.dashboardStatOrders.tr,
            value: '${metrics.ordersPlaced}',
            caption: periodLabel,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: HomeDashboardStatCell(
            label: AppStrings.Home.dashboardStatCompletion.tr,
            value: pct,
            caption: AppStrings.Home.dashboardStatCompletionSub.tr,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: HomeDashboardStatCell(
            label: AppStrings.Home.dashboardStatRevenue.tr,
            value: formatDashboardEgp(context, metrics.revenueEgp),
            caption: AppStrings.Home.dashboardStatRevenueSub.tr,
          ),
        ),
      ],
    );
  }
}
