import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:toukh_provider/core/router/app_routes.dart';
import 'package:toukh_provider/domain/entities/provider_dashboard_order.dart';
import 'package:toukh_provider/features/home/presentation/widgets/home_dashboard_in_progress_order_card.dart';
import 'package:toukh_provider/l10n/app_strings.dart';
import 'package:toukh_ui/toukh_ui.dart';

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
                    return HomeDashboardInProgressOrderCard(order: o);
                  },
                ),
        ),
      ],
    );
  }
}
