import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:toukh_provider/features/home/presentation/widgets/home_dashboard_section_helpers.dart';
import 'package:toukh_provider/features/revenues/cubit/revenues_cubit.dart';
import 'package:toukh_provider/l10n/app_strings.dart';
import 'package:toukh_ui/toukh_ui.dart';

class RevenuesScreen extends StatelessWidget {
  const RevenuesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: CustomText(AppStrings.Revenues.title.tr),
        leading: IconButton(
          icon: Icon(ToukhIcons.back),
          onPressed: () => context.pop(),
        ),
      ),
      body: BlocBuilder<RevenuesCubit, RevenuesState>(
        builder: (context, state) {
          if (state.loading) {
            return const Center(child: CircularProgressIndicator());
          }
          return ToukhRefresh(
            onRefresh: context.read<RevenuesCubit>().reload,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: AppSizes.screenPadding,
              children: [
                CustomText(
                  AppStrings.Revenues.monthFilter.tr,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: AppSizes.spaceSm),
                SizedBox(
                  height: 40,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: state.availableMonths.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(width: AppSizes.spaceSm),
                    itemBuilder: (context, i) {
                      final m = state.availableMonths[i];
                      final selected = m == state.selectedMonth;
                      return ChoiceChip(
                        label: Text(m.label),
                        selected: selected,
                        onSelected: (_) =>
                            context.read<RevenuesCubit>().selectMonth(m),
                      );
                    },
                  ),
                ),
                const SizedBox(height: AppSizes.spaceXl),
                _SummaryGrid(state: state),
                const SizedBox(height: AppSizes.spaceXl),
                CustomText(
                  AppStrings.Revenues.revenueTrend.tr,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: AppSizes.spaceMd),
                _RevenueTrendChart(state: state),
                const SizedBox(height: AppSizes.spaceXl),
                CustomText(
                  AppStrings.Revenues.statusBreakdown.tr,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: AppSizes.spaceMd),
                _StatusPie(
                  accepted: state.acceptedCount,
                  rejected: state.rejectedCount,
                ),
                const SizedBox(height: AppSizes.spaceXl),
                CustomText(
                  AppStrings.Revenues.feesBreakdown.tr,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: AppSizes.spaceMd),
                _MoneyPie(
                  revenue: state.revenueEgp,
                  appFees: state.appFeesEgp,
                  customerServiceFees: state.customerServiceFeesEgp,
                ),
                const SizedBox(height: AppSizes.space4xl),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SummaryGrid extends StatelessWidget {
  const _SummaryGrid({required this.state});

  final RevenuesState state;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _MetricCard(
                label: AppStrings.Revenues.revenue.tr,
                value: formatDashboardEgp(context, state.revenueEgp),
                color: AppColors.secondColor,
                icon: PhosphorIconsRegular.currencyDollar,
              ),
            ),
            const SizedBox(width: AppSizes.spaceMd),
            Expanded(
              child: _MetricCard(
                label: AppStrings.Revenues.appFees.tr,
                value: formatDashboardEgp(context, state.appFeesEgp),
                color: AppColors.error,
                icon: PhosphorIconsRegular.receipt,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSizes.spaceMd),
        Row(
          children: [
            Expanded(
              child: _MetricCard(
                label: AppStrings.Revenues.customerServiceFees.tr,
                value: formatDashboardEgp(
                  context,
                  state.customerServiceFeesEgp,
                ),
                color: AppColors.error,
                icon: PhosphorIconsRegular.handshake,
              ),
            ),
            const SizedBox(width: AppSizes.spaceMd),
            Expanded(
              child: _MetricCard(
                label: AppStrings.Revenues.netAfterFees.tr,
                value: formatDashboardEgp(
                  context,
                  (state.revenueEgp - state.totalFeesEgp)
                      .clamp(0, double.infinity)
                      .toDouble(),
                ),
                color: AppColors.secondColor,
                icon: PhosphorIconsRegular.chartLineUp,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSizes.spaceMd),
        Row(
          children: [
            Expanded(
              child: _MetricCard(
                label: AppStrings.Revenues.accepted.tr,
                value: '${state.acceptedCount}',
                color: AppColors.success,
                icon: ToukhIcons.success,
              ),
            ),
            const SizedBox(width: AppSizes.spaceMd),
            Expanded(
              child: _MetricCard(
                label: AppStrings.Revenues.rejected.tr,
                value: '${state.rejectedCount}',
                color: AppColors.error,
                icon: PhosphorIconsRegular.xCircle,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  final String label;
  final String value;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.spaceLg),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: AppSizes.spaceSm),
          CustomText(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: AppColors.onSurface.withValues(alpha: 0.6),
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 4),
          CustomText(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
        ],
      ),
    );
  }
}

class _RevenueTrendChart extends StatelessWidget {
  const _RevenueTrendChart({required this.state});

  final RevenuesState state;

  @override
  Widget build(BuildContext context) {
    final points = state.dailyRevenue;
    if (points.isEmpty || points.every((p) => p.y <= 0)) {
      return _EmptyChart(message: AppStrings.Revenues.noData.tr);
    }

    return SizedBox(
      height: 220,
      child: LineChart(
        LineChartData(
          minY: 0,
          maxY: state.dailyMaxY * 1.15,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: state.dailyMaxY / 4,
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                getTitlesWidget: (v, _) => Text(
                  v.toInt().toString(),
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: (points.length / 6).clamp(1, 5).toDouble(),
                getTitlesWidget: (v, _) {
                  final i = v.toInt();
                  if (i < 0 || i >= points.length) return const SizedBox.shrink();
                  return Text(
                    points[i].label,
                    style: Theme.of(context).textTheme.labelSmall,
                  );
                },
              ),
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: [
                for (final p in points) FlSpot(p.x, p.y),
              ],
              isCurved: true,
              color: AppColors.appColor,
              barWidth: 3,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                color: AppColors.appColor.withValues(alpha: 0.12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusPie extends StatelessWidget {
  const _StatusPie({required this.accepted, required this.rejected});

  final int accepted;
  final int rejected;

  @override
  Widget build(BuildContext context) {
    final total = accepted + rejected;
    if (total <= 0) {
      return _EmptyChart(message: AppStrings.Revenues.noData.tr);
    }
    return _PieWithLegend(
      sections: [
        PieChartSectionData(
          value: accepted.toDouble(),
          color: AppColors.success,
          title: total == 0 ? '' : '${((accepted / total) * 100).round()}%',
          radius: 54,
          titleStyle: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 12,
          ),
        ),
        PieChartSectionData(
          value: rejected.toDouble(),
          color: AppColors.error,
          title: total == 0 ? '' : '${((rejected / total) * 100).round()}%',
          radius: 54,
          titleStyle: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 12,
          ),
        ),
      ],
      legends: [
        (AppStrings.Revenues.accepted.tr, AppColors.success, '$accepted'),
        (AppStrings.Revenues.rejected.tr, AppColors.error, '$rejected'),
      ],
    );
  }
}

class _MoneyPie extends StatelessWidget {
  const _MoneyPie({
    required this.revenue,
    required this.appFees,
    required this.customerServiceFees,
  });

  final double revenue;
  final double appFees;
  final double customerServiceFees;

  @override
  Widget build(BuildContext context) {
    final totalFees = appFees + customerServiceFees;
    final net = (revenue - totalFees).clamp(0, double.infinity).toDouble();
    final total = net + totalFees;
    if (total <= 0) {
      return _EmptyChart(message: AppStrings.Revenues.noData.tr);
    }

    final sections = <PieChartSectionData>[
      PieChartSectionData(
        value: net,
        color: AppColors.secondColor,
        title: '${((net / total) * 100).round()}%',
        radius: 54,
        titleStyle: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    ];
    final legends = <(String, Color, String)>[
      (
        AppStrings.Revenues.netAfterFees.tr,
        AppColors.secondColor,
        formatDashboardEgp(context, net),
      ),
    ];

    if (appFees > 0) {
      sections.add(
        PieChartSectionData(
          value: appFees,
          color: AppColors.error,
          title: '${((appFees / total) * 100).round()}%',
          radius: 54,
          titleStyle: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 12,
          ),
        ),
      );
      legends.add((
        AppStrings.Revenues.appFees.tr,
        AppColors.error,
        formatDashboardEgp(context, appFees),
      ));
    }

    if (customerServiceFees > 0) {
      const csfColor = Color(0xFFC45C26);
      sections.add(
        PieChartSectionData(
          value: customerServiceFees,
          color: csfColor,
          title: '${((customerServiceFees / total) * 100).round()}%',
          radius: 54,
          titleStyle: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 12,
          ),
        ),
      );
      legends.add((
        AppStrings.Revenues.customerServiceFees.tr,
        csfColor,
        formatDashboardEgp(context, customerServiceFees),
      ));
    }

    // Fallback: show combined fees if both were zero but totalFees somehow > 0
    // (should not happen) — keep pie readable with at least net.
    if (sections.length == 1 && totalFees > 0) {
      sections.add(
        PieChartSectionData(
          value: totalFees,
          color: AppColors.error,
          title: '${((totalFees / total) * 100).round()}%',
          radius: 54,
          titleStyle: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 12,
          ),
        ),
      );
      legends.add((
        AppStrings.Revenues.appFees.tr,
        AppColors.error,
        formatDashboardEgp(context, totalFees),
      ));
    }

    return _PieWithLegend(sections: sections, legends: legends);
  }
}

class _PieWithLegend extends StatelessWidget {
  const _PieWithLegend({
    required this.sections,
    required this.legends,
  });

  final List<PieChartSectionData> sections;
  final List<(String, Color, String)> legends;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.spaceLg),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 140,
            height: 140,
            child: PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 28,
                sections: sections,
              ),
            ),
          ),
          const SizedBox(width: AppSizes.spaceLg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final item in legends) ...[
                  Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: item.$2,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: CustomText(
                          item.$1,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                      CustomText(
                        item.$3,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyChart extends StatelessWidget {
  const _EmptyChart({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 140,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: CustomText(
        message,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.onSurface.withValues(alpha: 0.55),
            ),
      ),
    );
  }
}
