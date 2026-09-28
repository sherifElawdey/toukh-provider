import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:toukh_provider/core/router/app_routes.dart';
import 'package:toukh_provider/core/utils/wallet_format.dart';
import 'package:toukh_provider/l10n/app_strings.dart';
import 'package:toukh_ui/toukh_ui.dart';

class HomeDashboardRevenueCard extends StatelessWidget {
  const HomeDashboardRevenueCard({
    super.key,
    required this.revenueEgp,
    required this.weekRevenueEgp,
    required this.weekRate,
  });

  final double revenueEgp;
  final double weekRevenueEgp;

  /// Completion share for the last 7 days, from 0 to 1.
  final double weekRate;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: AppColors.secondColor.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  PhosphorIconsRegular.currencyDollar,
                  color: AppColors.secondColor,
                  size: 28,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: CustomText(
                    AppStrings.Home.dashboardStatRevenue.tr,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: scheme.onSurface.withValues(alpha: 0.72),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            CustomText(
              'EGP ${formatWalletMoney(revenueEgp)}',
              style: TextStyle(
                fontSize: 34,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.8,
                color: scheme.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            CustomText(
              AppStrings.Home.dashboardStatRevenueSub.tr,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: scheme.onSurface.withValues(alpha: 0.55),
              ),
            ),
            const SizedBox(height: 14),
            _WeekRevenueLine(
              weekRevenueEgp: weekRevenueEgp,
              weekRate: weekRate,
            ),
          ],
        ),
      ),
    );
  }
}

class _WeekRevenueLine extends StatelessWidget {
  const _WeekRevenueLine({
    required this.weekRevenueEgp,
    required this.weekRate,
  });

  final double weekRevenueEgp;
  final double weekRate;

  @override
  Widget build(BuildContext context) {
    final percent = (weekRate * 100).round().clamp(0, 100);
    final rateColor = percent >= 70
        ? AppColors.success
        : percent >= 40
            ? AppColors.secondColor
            : AppColors.error;
    return Row(
      children: [
        Icon(
          PhosphorIconsRegular.calendarBlank,
          size: 14,
          color: AppColors.secondColor,
        ),
        const SizedBox(width: 4),
        Flexible(
          child: CustomText(
            '${AppStrings.Home.dashboardPeriodWeek.tr} · EGP ${formatWalletMoney(weekRevenueEgp)}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.secondColor,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Icon(
          PhosphorIconsRegular.trendUp,
          size: 14,
          color: rateColor,
        ),
        const SizedBox(width: 4),
        CustomText(
          '$percent%',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: rateColor,
          ),
        ),
      ],
    );
  }
}

class HomeDashboardWalletCard extends StatelessWidget {
  const HomeDashboardWalletCard({
    super.key,
    required this.balanceEgp,
    this.pendingEgp,
    this.needsRecharge = false,
  });

  final double balanceEgp;
  final double? pendingEgp;
  final bool needsRecharge;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final accent = needsRecharge ? AppColors.error : scheme.primary;
    final fill = needsRecharge
        ? AppColors.error.withValues(alpha: 0.12)
        : Theme.of(context).cardColor;
    return Material(
      color: fill,
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push(AppRoutes.wallet),
        child: Container(
          decoration: BoxDecoration(
            border: needsRecharge
                ? Border.all(color: AppColors.error.withValues(alpha: 0.7))
                : null,
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.all(8),
                child: Icon(ToukhIcons.wallet, color: accent, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomText(
                      AppStrings.Home.dashboardWalletTitle.tr,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: needsRecharge
                            ? AppColors.error
                            : scheme.onSurface.withValues(alpha: 0.65),
                      ),
                    ),
                    const SizedBox(height: 2),
                    CustomText(
                      'EGP ${formatWalletMoney(balanceEgp)}',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                        color: needsRecharge ? AppColors.error : scheme.onSurface,
                      ),
                    ),
                    if (needsRecharge) ...[
                      const SizedBox(height: 4),
                      CustomText(
                        AppStrings.Home.dashboardWalletRecharge.tr,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.error,
                        ),
                      ),
                    ] else if (pendingEgp != null && pendingEgp! > 0) ...[
                      const SizedBox(height: 4),
                      CustomText(
                        '${AppStrings.Home.dashboardWalletPending.tr}: EGP ${formatWalletMoney(pendingEgp!)}',
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
        ),
      ),
    );
  }
}
