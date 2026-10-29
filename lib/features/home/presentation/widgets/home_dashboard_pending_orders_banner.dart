import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:toukh_provider/core/router/app_routes.dart';
import 'package:toukh_provider/l10n/app_strings.dart';
import 'package:toukh_ui/toukh_ui.dart';

class HomeDashboardPendingOrdersBanner extends StatelessWidget {
  const HomeDashboardPendingOrdersBanner({
    super.key,
    required this.pendingCount,
    this.titleKey,
    this.subtitleKey,
    this.onTap,
  });

  final int pendingCount;
  final String? titleKey;
  final String? subtitleKey;

  /// Defaults to the orders tab.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    if (pendingCount <= 0) return const SizedBox.shrink();

    final scheme = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSizes.spaceMd),
      child: Material(
        color: dark ? const Color(0xFF3A2A12) : AppColors.warningSoft,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusLg),
          side: BorderSide(color: AppColors.warning.withValues(alpha: 0.35)),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap ?? () => context.go(AppRoutes.orders),
          child: Padding(
            padding: const EdgeInsets.all(AppSizes.spaceBase),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.warning,
                    borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                  ),
                  alignment: Alignment.center,
                  child: CustomText(
                    '$pendingCount',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 20,
                      height: 1.2,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CustomText(
                        (titleKey ??
                                AppStrings.Home.dashboardPendingOrdersTitle)
                            .tr,
                        style: TextStyle(
                          color: scheme.onSurface,
                          fontWeight: FontWeight.w800,
                          fontSize: AppSizes.fontBody,
                        ),
                      ),
                      const SizedBox(height: 2),
                      CustomText(
                        (subtitleKey ??
                                AppStrings.Home.dashboardPendingOrdersSubtitle)
                            .tr,
                        style: TextStyle(
                          color: scheme.onSurfaceVariant,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Directionality.of(context) == TextDirection.rtl
                      ? PhosphorIconsBold.caretLeft
                      : PhosphorIconsBold.caretRight,
                  color: AppColors.warning,
                  size: 18,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
