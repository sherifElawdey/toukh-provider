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
  });

  final int pendingCount;

  @override
  Widget build(BuildContext context) {
    if (pendingCount <= 0) return const SizedBox.shrink();

    final scheme = Theme.of(context).colorScheme;

    return Material(
      color: AppColors.appColor,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.go(AppRoutes.orders),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: CustomText(
                  '$pendingCount',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 20,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomText(
                      AppStrings.Home.dashboardPendingOrdersTitle.tr,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: AppSizes.fontTitle,
                      ),
                    ),
                    const SizedBox(height: 2),
                    CustomText(
                      AppStrings.Home.dashboardPendingOrdersSubtitle.tr,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.88),
                        fontSize: AppSizes.fontBody,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                ToukhIcons.chevronRight,
                color: scheme.onPrimary.withValues(alpha: 0.92),
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
