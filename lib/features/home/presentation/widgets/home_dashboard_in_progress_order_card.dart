import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:toukh_provider/core/router/app_routes.dart';
import 'package:toukh_provider/domain/entities/provider_dashboard_order.dart';
import 'package:toukh_provider/features/home/presentation/widgets/dashboard_shell.dart';
import 'package:toukh_provider/features/home/presentation/widgets/home_dashboard_section_helpers.dart';
import 'package:toukh_provider/l10n/app_strings.dart';
import 'package:toukh_ui/toukh_ui.dart';

class HomeDashboardInProgressOrderCard extends StatelessWidget {
  const HomeDashboardInProgressOrderCard({super.key, required this.order});

  final ProviderOrderDashboard order;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final subtle = scheme.onSurface.withValues(alpha: 0.62);
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
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
                  order.hideCustomerContact
                      ? AppStrings.Orders.pharmacyRequestCustomerLabel.tr
                      : order.customerName ??
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
    );
  }
}
