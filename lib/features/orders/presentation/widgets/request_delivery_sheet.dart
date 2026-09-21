import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:toukh_provider/shared/shared.dart';
import 'package:toukh_provider/l10n/app_strings.dart';

Future<void> showDriverAssignedSheet(
  BuildContext context, {
  required ProviderMasterOrderRow row,
}) {
  return showModalBottomSheet<void>(
    context: context,
    useSafeArea: true,
    builder: (ctx) {
      final scheme = Theme.of(ctx).colorScheme;
      return Padding(
        padding: AppSizes.screenPadding.copyWith(
          top: AppSizes.spaceLg,
          bottom: AppSizes.space2xl,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            CustomText(
              AppStrings.Orders.driverAssignedTitle.tr,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: AppSizes.fontHeadline,
                color: scheme.onSurface,
              ),
            ),
            const SizedBox(height: AppSizes.spaceSm),
            CustomText(
              AppStrings.Orders.driverAssignedBody.tr,
              style: TextStyle(
                color: scheme.onSurface.withValues(alpha: 0.72),
                height: 1.35,
              ),
            ),
            const SizedBox(height: AppSizes.spaceLg),
            AppFilledButton(
              text: AppStrings.Orders.driverAssignedDone.tr,
              onTap: () => Navigator.of(ctx).pop(),
            ),
          ],
        ),
      );
    },
  );
}
