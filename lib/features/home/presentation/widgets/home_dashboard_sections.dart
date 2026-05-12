import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:toukh_ui/toukh_ui.dart';
import 'package:toukh_provider/core/router/app_routes.dart';
import 'package:toukh_provider/domain/entities/provider_dashboard_order.dart';
import 'package:toukh_provider/domain/entities/provider_review_summary.dart';
import 'package:toukh_provider/features/home/cubit/home_dashboard_state.dart';
import 'package:toukh_provider/features/home/presentation/widgets/dashboard_shell.dart';
import 'package:toukh_provider/features/home/presentation/widgets/home_dashboard_chart.dart';
import 'package:toukh_provider/l10n/app_strings.dart';

String formatDashboardEgp(BuildContext context, double value) {
  final locale = Localizations.localeOf(context).toLanguageTag();
  final fmt = NumberFormat.decimalPattern(locale);
  return '${fmt.format(value.round())} EGP';
}

String dashboardOrderStatusLabel(ProviderOrderDashboard o) {
  final w = o.statusWire.toLowerCase();
  if (w == 'preparing' || w == 'ready' || w == 'ready_for_pickup') {
    return AppStrings.Home.dashboardStatusPreparing.tr;
  }
  if (w == 'picked_up') {
    return AppStrings.Home.dashboardStatusPickup.tr;
  }
  return switch (o.status) {
    OrderStatus.placed => AppStrings.Home.dashboardStatusNew.tr,
    OrderStatus.accepted => AppStrings.Home.dashboardStatusPreparing.tr,
    OrderStatus.pickedUp => AppStrings.Home.dashboardStatusPickup.tr,
    OrderStatus.delivered || OrderStatus.cancelled =>
      o.statusWire.isNotEmpty ? o.statusWire : '—',
  };
}

class HomeDashboardInProgressStrip extends StatelessWidget {
  const HomeDashboardInProgressStrip({
    super.key,
    required this.orders,
  });

  final List<ProviderOrderDashboard> orders;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: CustomText(
                AppStrings.Home.dashboardInProgressTitle.tr,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: AppSizes.fontTitle,
                  color: scheme.onSurface,
                ),
              ),
            ),
            TextButton(
              onPressed: () => context.go(AppRoutes.orders),
              child: CustomText(AppStrings.Home.dashboardViewOrders.tr),
            ),
          ],
        ),
        const SizedBox(height: AppSizes.spaceSm),
        SizedBox(
          height: 112,
          child: orders.isEmpty
              ? Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: AppSizes.spaceMd),
                    child: CustomText(
                      AppStrings.Home.dashboardInProgressEmpty.tr,
                      style: TextStyle(
                        color: scheme.onSurface.withValues(alpha: 0.55),
                        fontSize: AppSizes.fontBody,
                      ),
                    ),
                  ),
                )
              : ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: orders.length,
                  separatorBuilder: (context, _) => const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    final o = orders[index];
                    return _InProgressOrderCard(order: o);
                  },
                ),
        ),
      ],
    );
  }
}

class _InProgressOrderCard extends StatelessWidget {
  const _InProgressOrderCard({required this.order});

  final ProviderOrderDashboard order;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final subtle = scheme.onSurface.withValues(alpha: 0.62);
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      // shape: Border.all(color: AppColors.borderFocus),
      child: Container(
        child: InkWell(
          onTap: () => context.go(AppRoutes.orders),
          borderRadius: BorderRadius.circular(20),
          child: Ink(
            width: 172,
            decoration: dashboardSoftDecoration(context),
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
                const Spacer(),
                CustomText(
                  order.customerName ??
                      '${AppStrings.Home.dashboardOrderShort.tr} #${order.id.length > 6 ? order.id.substring(0, 6) : order.id}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: scheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                CustomText(
                  formatDashboardEgp(context, order.totalEgp),
                  style: TextStyle(fontSize: 13, color: subtle, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class HomeDashboardWalletCard extends StatelessWidget {
  const HomeDashboardWalletCard({
    super.key,
    required this.balanceEgp,
    this.pendingEgp,
  });

  final double balanceEgp;
  final double? pendingEgp;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final accent = scheme.primaryContainer.withValues(alpha: 0.35);
    return Container(
      decoration: BoxDecoration(
        color: accent,
        borderRadius: BorderRadius.circular(22),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      child: Row(
        children: [
          Icon(Icons.account_balance_wallet_rounded, color: scheme.primary, size: 28),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomText(
                  AppStrings.Home.dashboardWalletTitle.tr,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: scheme.onSurface.withValues(alpha: 0.65),
                  ),
                ),
                const SizedBox(height: 4),
                CustomText(
                  formatDashboardEgp(context, balanceEgp),
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                    color: scheme.onSurface,
                  ),
                ),
                if (pendingEgp != null && pendingEgp! > 0) ...[
                  const SizedBox(height: 6),
                  CustomText(
                    '${AppStrings.Home.dashboardWalletPending.tr}: ${formatDashboardEgp(context, pendingEgp!)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: scheme.onSurface.withValues(alpha: 0.55),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

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
          child: _StatCell(
            label: AppStrings.Home.dashboardStatOrders.tr,
            value: '${metrics.ordersPlaced}',
            caption: periodLabel,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatCell(
            label: AppStrings.Home.dashboardStatCompletion.tr,
            value: pct,
            caption: AppStrings.Home.dashboardStatCompletionSub.tr,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatCell(
            label: AppStrings.Home.dashboardStatRevenue.tr,
            value: formatDashboardEgp(context, metrics.revenueEgp),
            caption: AppStrings.Home.dashboardStatRevenueSub.tr,
          ),
        ),
      ],
    );
  }
}

class _StatCell extends StatelessWidget {
  const _StatCell({
    required this.label,
    required this.value,
    required this.caption,
  });

  final String label;
  final String value;
  final String caption;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      decoration: dashboardSoftDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomText(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: scheme.onSurface.withValues(alpha: 0.58),
            ),
          ),
          const SizedBox(height: 8),
          CustomText(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w900,
              color: scheme.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          CustomText(
            caption,
            style: TextStyle(
              fontSize: 11,
              color: scheme.onSurface.withValues(alpha: 0.48),
            ),
          ),
        ],
      ),
    );
  }
}

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

class HomeDashboardBestsellersSection extends StatelessWidget {
  const HomeDashboardBestsellersSection({super.key, required this.rows});

  final List<BestsellerRow> rows;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CustomText(
          AppStrings.Home.dashboardBestsellersTitle.tr,
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: AppSizes.fontTitle,
            color: scheme.onSurface,
          ),
        ),
        const SizedBox(height: AppSizes.spaceMd),
        if (rows.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSizes.spaceSm),
            child: CustomText(
              AppStrings.Home.dashboardBestsellersEmpty.tr,
              style: TextStyle(color: scheme.onSurface.withValues(alpha: 0.55)),
            ),
          )
        else
          ...rows.asMap().entries.map((e) {
            final rank = e.key + 1;
            final row = e.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Container(
                decoration: dashboardSoftDecoration(context),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    SizedBox(
                      width: 28,
                      child: CustomText(
                        '$rank',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          color: scheme.onSurface.withValues(alpha: 0.35),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CustomText(
                            row.label,
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                          ),
                          const SizedBox(height: 4),
                          CustomText(
                            '${row.unitsSold} ${AppStrings.Home.dashboardBestsellersUnits.tr} · ${formatDashboardEgp(context, row.revenueEgp)}',
                            style: TextStyle(
                              fontSize: 12,
                              color: scheme.onSurface.withValues(alpha: 0.55),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
      ],
    );
  }
}

class HomeDashboardReviewsSection extends StatelessWidget {
  const HomeDashboardReviewsSection({super.key, required this.reviews});

  final List<ProviderReviewSummary> reviews;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final dateFmt = DateFormat.yMMMd(locale);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CustomText(
          AppStrings.Home.dashboardReviewsTitle.tr,
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: AppSizes.fontTitle,
            color: scheme.onSurface,
          ),
        ),
        const SizedBox(height: AppSizes.spaceMd),
        if (reviews.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSizes.spaceSm),
            child: CustomText(
              AppStrings.Home.dashboardReviewsEmpty.tr,
              style: TextStyle(color: scheme.onSurface.withValues(alpha: 0.55)),
            ),
          )
        else
          ...reviews.map((r) {
            final initial =
                (r.authorName?.trim().isNotEmpty ?? false) ? r.authorName!.trim()[0].toUpperCase() : '?';
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Container(
                decoration: dashboardSoftDecoration(context),
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      backgroundColor: scheme.primary.withValues(alpha: 0.18),
                      foregroundColor: scheme.primary,
                      child: CustomText(initial, style: const TextStyle(fontWeight: FontWeight.w800)),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: CustomText(
                                  r.authorName ?? '—',
                                  style: const TextStyle(fontWeight: FontWeight.w800),
                                ),
                              ),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: List.generate(
                                  5,
                                  (i) => Icon(
                                    i < r.rating ? Icons.star_rounded : Icons.star_outline_rounded,
                                    size: 16,
                                    color: AppColors.appColor.withValues(alpha: i < r.rating ? 1 : 0.28),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (r.createdAt != null) ...[
                            const SizedBox(height: 4),
                            CustomText(
                              dateFmt.format(r.createdAt!),
                              style: TextStyle(
                                fontSize: 12,
                                color: scheme.onSurface.withValues(alpha: 0.48),
                              ),
                            ),
                          ],
                          if ((r.comment ?? '').trim().isNotEmpty) ...[
                            const SizedBox(height: 8),
                            CustomText(
                              r.comment!.trim(),
                              style: TextStyle(
                                height: 1.35,
                                color: scheme.onSurface.withValues(alpha: 0.78),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
      ],
    );
  }
}
