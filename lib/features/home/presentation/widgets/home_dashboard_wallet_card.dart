import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:toukh_provider/features/home/presentation/widgets/home_dashboard_section_helpers.dart';
import 'package:toukh_provider/l10n/app_strings.dart';
import 'package:toukh_ui/toukh_ui.dart';

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
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.5),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ]
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: accent.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.all(8),
            child: Icon(ToukhIcons.wallet, color: scheme.primary, size: 28),
          ),
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
