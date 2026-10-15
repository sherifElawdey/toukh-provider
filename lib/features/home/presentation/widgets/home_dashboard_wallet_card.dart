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
    final percent = (weekRate * 100).round().clamp(0, 100);
    final faint = Colors.white.withValues(alpha: 0.8);
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: AlignmentDirectional.topStart,
          end: AlignmentDirectional.bottomEnd,
          colors: [
            AppColors.brandDeep,
            Color(0xFF1B4F8F),
            AppColors.secondColor,
          ],
        ),
        borderRadius: BorderRadius.circular(AppSizes.radiusXl),
        boxShadow: [
          BoxShadow(
            color: AppColors.brandDeep.withValues(alpha: 0.28),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      padding: const EdgeInsets.all(AppSizes.spaceLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: CustomText(
                  AppStrings.Home.dashboardStatRevenue.tr,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: faint,
                  ),
                ),
              ),
              _HeroChip(icon: PhosphorIconsBold.trendUp, label: '$percent%'),
            ],
          ),
          const SizedBox(height: AppSizes.spaceSm),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Flexible(
                child: CustomText(
                  formatWalletMoney(revenueEgp),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.w800,
                    height: 1.15,
                    color: Colors.white,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
              ),
              const SizedBox(width: 6),
              CustomText(
                'EGP',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: faint,
                ),
              ),
            ],
          ),
          CustomText(
            AppStrings.Home.dashboardStatRevenueSub.tr,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Colors.white.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: AppSizes.spaceBase),
          Container(height: 1, color: Colors.white.withValues(alpha: 0.14)),
          const SizedBox(height: AppSizes.spaceMd),
          Row(
            children: [
              Icon(PhosphorIconsRegular.calendarBlank, size: 16, color: faint),
              const SizedBox(width: 6),
              Expanded(
                child: CustomText(
                  AppStrings.Home.dashboardPeriodWeek.tr,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: faint,
                  ),
                ),
              ),
              CustomText(
                'EGP ${formatWalletMoney(weekRevenueEgp)}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroChip extends StatelessWidget {
  const _HeroChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(AppSizes.radiusFull),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white),
          const SizedBox(width: 4),
          CustomText(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              height: 1.2,
              color: Colors.white,
            ),
          ),
        ],
      ),
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
    final radius = BorderRadius.circular(AppSizes.radiusLg);
    return DecoratedBox(
      decoration: ToukhCard.decoration(
        context,
        color: needsRecharge ? scheme.errorContainer : null,
        borderColor: needsRecharge
            ? AppColors.error.withValues(alpha: 0.45)
            : null,
      ),
      child: Material(
        type: MaterialType.transparency,
        borderRadius: radius,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => context.push(AppRoutes.wallet),
          child: Padding(
            padding: const EdgeInsets.all(AppSizes.spaceBase),
            child: Row(
              children: [
                ToukhIconWell(icon: ToukhIcons.wallet, color: accent, size: 44),
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
                              : scheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 2),
                      CustomText(
                        'EGP ${formatWalletMoney(balanceEgp)}',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                          color: needsRecharge
                              ? AppColors.error
                              : scheme.onSurface,
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
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Icon(
                  Directionality.of(context) == TextDirection.rtl
                      ? PhosphorIconsRegular.caretLeft
                      : PhosphorIconsRegular.caretRight,
                  size: 18,
                  color: needsRecharge
                      ? AppColors.error
                      : scheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
