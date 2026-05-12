import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:toukh_provider/l10n/app_strings.dart';
import 'package:toukh_ui/toukh_ui.dart';

/// Bottom navigation for registration steps: outlined Back + filled primary action with arrows.
class RegistrationStepNavFooter extends StatelessWidget {
  const RegistrationStepNavFooter({
    super.key,
    required this.onBack,
    required this.onNext,
    this.nextLabelKey,
    this.nextEnabled = true,
    this.useSafeArea = true,
    this.padding,
  });

  final VoidCallback onBack;
  final VoidCallback onNext;
  /// Translation key; defaults to [AppStrings.Common.next].
  final String? nextLabelKey;
  final bool nextEnabled;
  final bool useSafeArea;
  /// When set, used instead of default screen horizontal padding (e.g. [EdgeInsets.zero] in a padded card).
  final EdgeInsets? padding;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final backIcon = rtl ? Icons.arrow_forward_rounded : Icons.arrow_back_rounded;
    final forwardIcon = rtl ? Icons.arrow_back_rounded : Icons.arrow_forward_rounded;
    final radius = BorderRadius.circular(AppSizes.radiusLg);

    final row = Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: onBack,
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
              padding: const EdgeInsets.symmetric(horizontal: AppSizes.spaceMd),
              shape: RoundedRectangleBorder(borderRadius: radius),
              side: BorderSide(color: scheme.outline.withValues(alpha: 0.38)),
              foregroundColor: scheme.onSurface,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(backIcon, size: 22),
                const SizedBox(width: AppSizes.spaceSm),
                Flexible(
                  child: CustomText(
                    AppStrings.Common.back.tr,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
        SizedBox(width: AppSizes.spaceMd),
        Expanded(
          flex: 2,
          child: FilledButton(
            onPressed: nextEnabled ? onNext : null,
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
              padding: const EdgeInsets.symmetric(horizontal: AppSizes.spaceMd),
              shape: RoundedRectangleBorder(borderRadius: radius),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: CustomText(
                    (nextLabelKey ?? AppStrings.Common.next).tr,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: AppSizes.spaceSm),
                Icon(forwardIcon, size: 22),
              ],
            ),
          ),
        ),
      ],
    );

    final outerPadding = padding ??
        AppSizes.screenPadding.copyWith(
          top: AppSizes.spaceSm,
          bottom: AppSizes.spaceBase,
        );

    if (!useSafeArea) {
      return Padding(padding: outerPadding, child: row);
    }

    return SafeArea(
      top: false,
      minimum: EdgeInsets.zero,
      child: Padding(padding: outerPadding, child: row),
    );
  }
}
