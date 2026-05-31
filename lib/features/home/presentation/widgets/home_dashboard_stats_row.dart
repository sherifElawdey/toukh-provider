import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:toukh_provider/features/home/cubit/home_dashboard_state.dart';
import 'package:toukh_provider/features/home/presentation/widgets/home_dashboard_section_helpers.dart';
import 'package:toukh_provider/features/home/presentation/widgets/home_dashboard_stat_cell.dart';
import 'package:toukh_provider/l10n/app_strings.dart';
import 'package:toukh_ui/toukh_ui.dart';

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
        ? '0'
        : '${(metrics.completionRatio * 100).round()}%';

    final periodLabel = period == DashboardChartPeriod.week
        ? AppStrings.Home.dashboardPeriodWeek.tr
        : AppStrings.Home.dashboardPeriodMonth.tr;

    return Row(
      children: [
        Expanded(
          child: Column(
            children: [
              HomeDashboardStatCell(
                label: AppStrings.Home.dashboardStatOrders.tr,
                value: '${metrics.ordersPlaced}',
                caption: periodLabel,
                color: AppColors.appColor,
                icon: Icons.shopping_bag_outlined,
              ),
              HomeDashboardStatCell(
                label: AppStrings.Home.dashboardStatCompletion.tr,
                value: pct,
                caption: AppStrings.Home.dashboardStatCompletionSub.tr,
                color: AppColors.success,
                icon: Icons.check_circle_outline,
              ),
            ],
          ),
        ),

        // const SizedBox(width: 10),
        Expanded(
          child: Column(
            children: [
              HomeDashboardStatCell(
                  label: AppStrings.Home.dashboardStatRevenue.tr,
                  value: formatDashboardEgp(context, metrics.revenueEgp),
                  caption: AppStrings.Home.dashboardStatRevenueSub.tr,
                  color: AppColors.secondColor,
                  icon: Icons.attach_money_outlined
              ),
              HomeDashboardStatCell(
                label: AppStrings.Home.dashboardCanceld.tr,
                value: '${metrics.ordersCanceled}',
                caption: periodLabel,
                color: AppColors.error,
                icon: Icons.cancel_outlined,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
