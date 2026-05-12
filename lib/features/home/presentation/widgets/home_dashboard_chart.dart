import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:toukh_provider/features/home/cubit/home_dashboard_state.dart';
import 'package:toukh_provider/l10n/app_strings.dart';
import 'package:toukh_ui/toukh_ui.dart';

class HomeDashboardOrderChart extends StatelessWidget {
  const HomeDashboardOrderChart({
    super.key,
    required this.buckets,
    required this.period,
  });

  final List<OrderRateBucket> buckets;
  final DashboardChartPeriod period;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    if (buckets.isEmpty) {
      return SizedBox(
        height: 180,
        child: Center(
          child: CustomText(
            AppStrings.Home.dashboardChartEmpty.tr,
            style: TextStyle(
              color: scheme.onSurface.withValues(alpha: 0.55),
              fontSize: AppSizes.fontBody,
            ),
          ),
        ),
      );
    }

    final totalCount = buckets.fold<int>(0, (a, b) => a + b.count);
    if (totalCount == 0) {
      return SizedBox(
        height: 180,
        child: Center(
          child: CustomText(
            AppStrings.Home.dashboardChartEmpty.tr,
            style: TextStyle(
              color: scheme.onSurface.withValues(alpha: 0.55),
              fontSize: AppSizes.fontBody,
            ),
          ),
        ),
      );
    }

    final spots =
        List.generate(buckets.length, (i) => FlSpot(i.toDouble(), buckets[i].count.toDouble()));

    final maxY = buckets.map((e) => e.count).reduce((a, b) => a > b ? a : b).toDouble();
    final paddedMax = maxY < 1 ? 1.0 : maxY * 1.2;

    final fmtDay = DateFormat.E(Localizations.localeOf(context).toLanguageTag());
    final fmtMd = DateFormat.Md(Localizations.localeOf(context).toLanguageTag());

    final interval =
        period == DashboardChartPeriod.month && buckets.length > 14 ? (buckets.length / 6).ceilToDouble() : 1.0;

    return SizedBox(
      height: 210,
      child: Padding(
        padding: const EdgeInsets.only(right: 8, top: 12, left: 4, bottom: 4),
        child: LineChart(
          LineChartData(
            minX: 0,
            maxX: (buckets.length - 1).toDouble(),
            minY: 0,
            maxY: paddedMax,
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              getDrawingHorizontalLine: (v) => FlLine(
                color: scheme.outline.withValues(alpha: 0.12),
                strokeWidth: 1,
              ),
            ),
            borderData: FlBorderData(show: false),
            titlesData: FlTitlesData(
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 32,
                  getTitlesWidget: (v, m) => CustomText(
                    v == v.roundToDouble() ? v.toInt().toString() : '',
                    style: TextStyle(
                      fontSize: 10,
                      color: scheme.onSurface.withValues(alpha: 0.45),
                    ),
                  ),
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  interval: interval,
                  getTitlesWidget: (v, m) {
                    final i = v.round();
                    if (i < 0 || i >= buckets.length) return const SizedBox.shrink();
                    final d = buckets[i].dayStart;
                    final label =
                        period == DashboardChartPeriod.week ? fmtDay.format(d) : fmtMd.format(d);
                    return Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: CustomText(
                        label,
                        style: TextStyle(
                          fontSize: 10,
                          color: scheme.onSurface.withValues(alpha: 0.52),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            lineBarsData: [
              LineChartBarData(
                spots: spots,
                isCurved: true,
                color: AppColors.appColor,
                barWidth: 2.8,
                dotData: FlDotData(
                  show: true,
                  getDotPainter: (a, b, c, d) => FlDotCirclePainter(
                    radius: 3,
                    color: AppColors.appColor,
                    strokeWidth: 1.5,
                    strokeColor: scheme.surface,
                  ),
                ),
                belowBarData: BarAreaData(
                  show: true,
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AppColors.appColor.withValues(alpha: 0.22),
                      AppColors.appColor.withValues(alpha: 0),
                    ],
                  ),
                ),
              ),
            ],
            lineTouchData: LineTouchData(
              enabled: true,
              touchTooltipData: LineTouchTooltipData(
                getTooltipItems: (touched) {
                  return touched.map((s) {
                    final i = s.x.round();
                    if (i < 0 || i >= buckets.length) return null;
                    final b = buckets[i];
                    final dateLabel = DateFormat.yMMMd(
                      Localizations.localeOf(context).toLanguageTag(),
                    ).format(b.dayStart);
                    return LineTooltipItem(
                      '$dateLabel\n${b.count} ${AppStrings.Home.dashboardStatOrders.tr}',
                      TextStyle(
                        color: scheme.onInverseSurface,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    );
                  }).whereType<LineTooltipItem>().toList();
                },
              ),
            ),
          ),
          duration: Duration.zero,
        ),
      ),
    );
  }
}
