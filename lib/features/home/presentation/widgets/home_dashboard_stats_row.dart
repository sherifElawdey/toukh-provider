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
  });

  final DashboardPeriodMetrics metrics;

  @override
  Widget build(BuildContext context) {
    final todayLabel = AppStrings.Home.dashboardStatTodayCaption.tr;

    return Row(
      children: [
        Expanded(
          child: Column(
            children: [
              HomeDashboardStatCell(
                label: AppStrings.Home.dashboardStatOrders.tr,
                value: '${metrics.ordersPlaced}',
                caption: todayLabel,
                color: AppColors.appColor,
                icon: PhosphorIconsRegular.shoppingBag,
              ),
              HomeDashboardStatCell(
                label: AppStrings.Home.dashboardStatCompletion.tr,
                value: '${metrics.completedCount}',
                caption: todayLabel,
                color: AppColors.success,
                icon: ToukhIcons.success,
              ),
            ],
          ),
        ),
        Expanded(
          child: Column(
            children: [
              HomeDashboardStatCell(
                label: AppStrings.Home.dashboardStatRevenue.tr,
                value: formatDashboardEgp(context, metrics.revenueEgp),
                caption: AppStrings.Home.dashboardStatRevenueSub.tr,
                color: AppColors.secondColor,
                icon: PhosphorIconsRegular.currencyDollar,
              ),
              HomeDashboardStatCell(
                label: AppStrings.Home.dashboardCanceld.tr,
                value: '${metrics.ordersCanceled}',
                caption: todayLabel,
                color: AppColors.error,
                icon: PhosphorIconsRegular.xCircle,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
