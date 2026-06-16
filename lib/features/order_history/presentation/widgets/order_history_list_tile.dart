import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:toukh_provider/core/router/app_routes.dart';
import 'package:toukh_provider/features/home/presentation/widgets/home_dashboard_section_helpers.dart';
import 'package:toukh_provider/features/orders/presentation/widgets/provider_order_status_label.dart';
import 'package:toukh_provider/l10n/app_strings.dart';
import 'package:toukh_ui/toukh_ui.dart';

class OrderHistoryListTile extends StatelessWidget {
  const OrderHistoryListTile({super.key, required this.row});

  final ProviderMasterOrderRow row;

  DateTime? _displayDate() {
    final slice = row.slice;
    return slice.deliveredAt ??
        slice.cancelledAt ??
        slice.dispatchedAt ??
        slice.acceptedAt ??
        slice.createdAt;
  }

  String _shortOrderId() {
    final id = row.id;
    if (id.length <= 8) return id;
    return '#${id.substring(id.length - 8)}';
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final slice = row.slice;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final date = _displayDate();
    final dateLabel = date != null
        ? DateFormat.yMMMd(locale).add_Hm().format(date)
        : '—';

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0,
      color: scheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        side: BorderSide(color: AppColors.borderSubtle),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        onTap: () => context.push(AppRoutes.orderDetailPath(row.id)),
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.spaceMd),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: CustomText(
                      providerDisplayCustomerName(
                        row.master,
                        slice,
                        genericLabel:
                            AppStrings.Orders.pharmacyRequestCustomerLabel.tr,
                      ),
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: AppSizes.fontTitle,
                        color: scheme.onSurface,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.appColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: CustomText(
                      providerOrderStatusLabel(row),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.appColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: CustomText(
                      _shortOrderId(),
                      style: TextStyle(
                        fontSize: AppSizes.fontLabel,
                        color: scheme.onSurface.withValues(alpha: 0.55),
                      ),
                    ),
                  ),
                  CustomText(
                    dateLabel,
                    style: TextStyle(
                      fontSize: AppSizes.fontLabel,
                      color: scheme.onSurface.withValues(alpha: 0.55),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              CustomText(
                formatDashboardEgp(context, slice.totalEgp),
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: AppSizes.fontBody,
                  color: scheme.onSurface.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
