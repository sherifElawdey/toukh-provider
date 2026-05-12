import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:toukh_ui/toukh_ui.dart';
import 'package:toukh_provider/l10n/app_strings.dart';

class OrdersScreen extends StatelessWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: AppSizes.screenPadding.copyWith(top: AppSizes.spaceLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CustomText(
            AppStrings.Orders.title.tr,
            style: TextStyle(
              fontSize: AppSizes.fontHeadline,
              fontWeight: FontWeight.w800,
              color: scheme.onSurface,
            ),
          ),
          SizedBox(height: AppSizes.spaceMd),
          CustomText(
            AppStrings.Orders.emptySubtitle.tr,
            style: TextStyle(
              fontSize: AppSizes.fontBody,
              color: scheme.onSurface.withValues(alpha: 0.72),
            ),
          ),
        ],
      ),
    );
  }
}
