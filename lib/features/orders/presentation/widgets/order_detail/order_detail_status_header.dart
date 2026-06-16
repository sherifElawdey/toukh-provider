import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:toukh_provider/features/home/presentation/widgets/home_dashboard_section_helpers.dart';
import 'package:toukh_provider/features/orders/presentation/widgets/provider_order_status_label.dart';
import 'package:toukh_provider/features/orders/presentation/widgets/provider_order_status_ui.dart';
import 'package:toukh_provider/l10n/app_strings.dart';
import 'package:toukh_ui/toukh_ui.dart';

class OrderDetailStatusHeader extends StatelessWidget {
  const OrderDetailStatusHeader({super.key, required this.row});

  final ProviderMasterOrderRow row;

  String _shortRef() {
    final id = row.id;
    if (id.length <= 8) return id.toUpperCase();
    return id.substring(id.length - 8).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final slice = row.slice;
    final t = Theme.of(context).textTheme;
    final statusColor = providerOrderStatusColorForRow(row);
    final statusIcon = providerOrderStatusIconForRow(row);
    final locale = Localizations.localeOf(context).languageCode;

    String? placedAt;
    if (slice.createdAt != null) {
      final formatted =
          DateFormat.yMMMd(locale).add_jm().format(slice.createdAt!);
      placedAt = AppStrings.Orders.detailPlacedAt.trParams({'date': formatted});
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSizes.spaceLg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            statusColor.withValues(alpha: 0.18),
            Theme.of(context).colorScheme.surface,
          ],
        ),
        borderRadius: BorderRadius.circular(AppSizes.radiusXl),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomText(
            '${AppStrings.Orders.detailOrderIdLabel.tr} · #${_shortRef()}',
            style: t.labelLarge?.copyWith(
              color: AppColors.onSurface.withValues(alpha: 0.55),
              fontWeight: FontWeight.w600,
            ),
          ),
          if (placedAt != null) ...[
            const SizedBox(height: AppSizes.spaceXs),
            CustomText(
              placedAt,
              style: t.bodySmall?.copyWith(
                color: AppColors.onSurface.withValues(alpha: 0.5),
              ),
            ),
          ],
          const SizedBox(height: AppSizes.spaceMd),
          Row(
            children: [
              Icon(statusIcon, color: statusColor, size: 32),
              const SizedBox(width: AppSizes.spaceMd),
              Expanded(
                child: CustomText(
                  providerOrderStatusLabel(row),
                  style: t.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.spaceMd),
          CustomText(
            formatDashboardEgp(context, slice.totalEgp),
            style: t.titleLarge?.copyWith(
              fontWeight: FontWeight.w900,
              color: AppColors.appColor,
            ),
          ),
        ],
      ),
    );
  }
}
