import 'package:flutter/material.dart';
import 'package:toukh_provider/l10n/app_strings.dart';
import 'package:toukh_ui/toukh_ui.dart';

class MenuEmptyCategoriesPlaceholder extends StatelessWidget {
  const MenuEmptyCategoriesPlaceholder({
    super.key,
    required this.onAddCategory,
  });

  final VoidCallback onAddCategory;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: AppSizes.screenPadding,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.restaurant_menu_rounded,
              size: 56,
              color: scheme.onSurface.withValues(alpha: 0.35),
            ),
            SizedBox(height: AppSizes.spaceMd),
            CustomText(
              AppStrings.Registration.noCategoriesYet,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            SizedBox(height: AppSizes.spaceSm),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: CustomText(
                AppStrings.Registration.addFirstCategoryHint,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurface.withValues(alpha: 0.62),
                    ),
              ),
            ),
            SizedBox(height: AppSizes.spaceLg),
            AppFilledButton(
              text: AppStrings.Registration.addCategory,
              icon: Icons.add_rounded,
              onTap: onAddCategory,
            ),
          ],
        ),
      ),
    );
  }
}
