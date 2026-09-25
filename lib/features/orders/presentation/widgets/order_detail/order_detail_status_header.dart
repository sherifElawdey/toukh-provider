import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
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
      padding: const EdgeInsets.all(AppSizes.spaceBase),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            statusColor.withValues(alpha: 0.16),
            AppColors.surface,
          ],
        ),
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        border: Border.all(color: statusColor.withValues(alpha: 0.22)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(statusIcon, color: statusColor, size: 26),
          ),
          const SizedBox(width: AppSizes.spaceMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomText(
                  providerOrderStatusLabel(row),
                  style: t.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: statusColor,
                  ),
                ),
                const SizedBox(height: 2),
                CustomText(
                  '${AppStrings.Orders.detailOrderIdLabel.tr} · #${_shortRef()}',
                  style: t.labelMedium?.copyWith(
                    color: AppColors.onSurface.withValues(alpha: 0.55),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (placedAt != null) ...[
                  const SizedBox(height: 2),
                  CustomText(
                    placedAt,
                    style: t.labelSmall?.copyWith(
                      color: AppColors.onSurface.withValues(alpha: 0.45),
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
