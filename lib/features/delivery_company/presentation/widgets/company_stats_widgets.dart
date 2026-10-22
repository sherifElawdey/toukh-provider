import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:toukh_provider/domain/entities/company_courier_stats.dart';
import 'package:toukh_provider/features/delivery_company/presentation/widgets/company_widgets.dart';
import 'package:toukh_provider/l10n/app_strings.dart';
import 'package:toukh_ui/toukh_ui.dart';

enum _Period { today, week, month }

/// Today / week / month toggle over a [CompanySummaryGrid].

class CompanyPeriodStats extends StatefulWidget {
  const CompanyPeriodStats({
    super.key,
    required this.today,
    required this.week,
    required this.month,
  });

  final CourierPeriodSummary today;
  final CourierPeriodSummary week;
  final CourierPeriodSummary month;

  @override
  State<CompanyPeriodStats> createState() => _CompanyPeriodStatsState();
}

class _CompanyPeriodStatsState extends State<CompanyPeriodStats> {
  _Period _period = _Period.today;

  @override
  Widget build(BuildContext context) {
    final s = switch (_period) {
      _Period.today => widget.today,
      _Period.week => widget.week,
      _Period.month => widget.month,
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SegmentedButton<_Period>(
          showSelectedIcon: false,
          segments: [
            ButtonSegment(
              value: _Period.today,
              label: Text(AppStrings.Company.today.tr),
            ),
            ButtonSegment(
              value: _Period.week,
              label: Text(AppStrings.Company.thisWeek.tr),
            ),
            ButtonSegment(
              value: _Period.month,
              label: Text(AppStrings.Company.thisMonth.tr),
            ),
          ],
          selected: {_period},
          onSelectionChanged: (v) => setState(() => _period = v.first),
        ),
        const SizedBox(height: AppSizes.spaceMd),
        CompanySummaryGrid(summary: s),
      ],
    );
  }
}

/// Orders, earnings, distance and cancellations for one period.
class CompanySummaryGrid extends StatelessWidget {
  const CompanySummaryGrid({super.key, required this.summary});

  final CourierPeriodSummary summary;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => GridView.count(
        crossAxisCount: constraints.maxWidth >= 560 ? 4 : 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: AppSizes.spaceSm,
        crossAxisSpacing: AppSizes.spaceSm,
        childAspectRatio: 1.45,
        children: [
          CompanyStatTile(
            icon: ToukhIcons.orders,
            label: AppStrings.Company.orders.tr,
            value: '${summary.orders}',
          ),
          CompanyStatTile(
            icon: ToukhIcons.wallet,
            color: AppColors.success,
            label: AppStrings.Company.earnings.tr,
            value: companyEgp(summary.earningsEgp),
          ),
          CompanyStatTile(
            icon: ToukhIcons.navigation,
            label: AppStrings.Company.distance.tr,
            value: companyKm(summary.distanceMeters),
          ),
          CompanyStatTile(
            icon: ToukhIcons.close,
            color: Theme.of(context).colorScheme.error,
            label: AppStrings.Company.cancelled.tr,
            value: '${summary.cancelled}',
          ),
        ],
      ),
    );
  }
}

/// Bars per day or week; [byEarnings] plots EGP instead of trip counts.
class CompanyOrdersBarChart extends StatelessWidget {
  const CompanyOrdersBarChart({
    super.key,
    required this.points,
    required this.label,
    this.byEarnings = false,
  });

  final List<CourierStatsPoint> points;
  final String Function(DateTime date, String locale) label;
  final bool byEarnings;

  double _value(CourierStatsPoint p) =>
      byEarnings ? p.summary.earningsEgp : p.summary.orders.toDouble();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final total = points.fold<int>(0, (n, p) => n + p.summary.orders);
    if (points.isEmpty || total == 0) {
      return CompanyEmptyNote(AppStrings.Company.noTrips);
    }
    final locale = Localizations.localeOf(context).toLanguageTag();
    final maxValue = points.map(_value).reduce((a, b) => a > b ? a : b);
    return Container(
      height: 200,
      padding: const EdgeInsets.fromLTRB(8, 16, 8, 4),
      decoration: ToukhCard.decoration(context),
      child: BarChart(
        BarChartData(
          maxY: (maxValue * 1.25).ceilToDouble().clamp(1, double.infinity),
          alignment: BarChartAlignment.spaceAround,
          borderData: FlBorderData(show: false),
          gridData: FlGridData(
            drawVerticalLine: false,
            getDrawingHorizontalLine: (_) => FlLine(
              color: scheme.outline.withValues(alpha: 0.12),
              strokeWidth: 1,
            ),
          ),
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipItem: (group, _, rod, _) {
                final p = points[group.x];
                return BarTooltipItem(
                  '${p.summary.orders} · ${companyEgp(p.summary.earningsEgp)}\n'
                  '${companyKm(p.summary.distanceMeters)}',
                  const TextStyle(color: Colors.white, fontSize: 12),
                );
              },
            ),
          ),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: byEarnings ? 40 : 28,
                getTitlesWidget: (v, meta) => v % 1 == 0
                    ? Text(
                        v.toInt().toString(),
                        style: TextStyle(
                          fontSize: 10,
                          color: scheme.onSurfaceVariant,
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 24,
                getTitlesWidget: (v, meta) {
                  final i = v.toInt();
                  if (i < 0 || i >= points.length)
                    return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      label(points[i].date, locale),
                      style: TextStyle(
                        fontSize: 10,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          barGroups: [
            for (var i = 0; i < points.length; i++)
              BarChartGroupData(
                x: i,
                barRods: [
                  BarChartRodData(
                    toY: _value(points[i]),
                    width: 16,
                    color: byEarnings
                        ? AppColors.success
                        : AppColors.secondColor,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(4),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
