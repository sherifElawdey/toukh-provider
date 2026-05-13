import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:toukh_provider/features/home/cubit/home_dashboard_state.dart';
import 'package:toukh_provider/features/home/presentation/widgets/dashboard_shell.dart';
import 'package:toukh_provider/features/home/presentation/widgets/home_dashboard_chart.dart';
import 'package:toukh_provider/l10n/app_strings.dart';
import 'package:toukh_ui/toukh_ui.dart';

class HomeDashboardChartSection extends StatelessWidget {
  const HomeDashboardChartSection({
    super.key,
    required this.period,
    required this.buckets,
    required this.onPeriodChanged,
  });

  final DashboardChartPeriod period;
  final List<OrderRateBucket> buckets;
  final ValueChanged<DashboardChartPeriod> onPeriodChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      decoration: dashboardSoftDecoration(context),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: CustomText(
                  AppStrings.Home.dashboardChartTitle.tr,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: AppSizes.fontTitle,
                    color: scheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SegmentedButton<DashboardChartPeriod>(
            segments: [
              ButtonSegment(
                value: DashboardChartPeriod.week,
                label: CustomText(AppStrings.Home.dashboardPeriodWeek.tr),
              ),
              ButtonSegment(
                value: DashboardChartPeriod.month,
                label: CustomText(AppStrings.Home.dashboardPeriodMonth.tr),
              ),
            ],
            selected: {period},
            onSelectionChanged: (s) {
              if (s.isNotEmpty) onPeriodChanged(s.first);
            },
            style: ButtonStyle(
              visualDensity: VisualDensity.compact,
              padding: WidgetStateProperty.all(
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
            ),
          ),
          HomeDashboardOrderChart(buckets: buckets, period: period),
        ],
      ),
    );
  }
}
