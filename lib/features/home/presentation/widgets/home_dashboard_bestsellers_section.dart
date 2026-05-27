import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:toukh_provider/features/home/cubit/home_dashboard_state.dart';
import 'package:toukh_provider/features/home/presentation/widgets/dashboard_shell.dart';
import 'package:toukh_provider/features/home/presentation/widgets/home_dashboard_empty_placeholder.dart';
import 'package:toukh_provider/features/home/presentation/widgets/home_dashboard_section_helpers.dart';
import 'package:toukh_provider/l10n/app_strings.dart';
import 'package:toukh_ui/toukh_ui.dart';

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
          HomeDashboardEmptyPlaceholder(
            icon: Icons.local_fire_department_outlined,
            message: AppStrings.Home.dashboardBestsellersEmpty,
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
