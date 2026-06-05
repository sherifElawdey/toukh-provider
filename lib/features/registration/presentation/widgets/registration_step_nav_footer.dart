import 'package:flutter/material.dart';
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
    final backIcon = rtl ? ToukhIcons.forward : ToukhIcons.back;
    final forwardIcon = rtl ? ToukhIcons.back : ToukhIcons.forward;

    final row = Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: AppOutlinedButton(
            text: AppStrings.Common.back,
            icon: backIcon,
            height: 52,
            padding: const EdgeInsets.symmetric(horizontal: AppSizes.spaceMd),
            borderColor: scheme.outline.withValues(alpha: 0.38),
            color: scheme.onSurface,
            onTap: onBack,
          ),
        ),
        SizedBox(width: AppSizes.spaceMd),
        Expanded(
          flex: 2,
          child: AppFilledButton(
            text: nextLabelKey ?? AppStrings.Common.next,
            trailingIcon: forwardIcon,
            height: 52,
            padding: const EdgeInsets.symmetric(horizontal: AppSizes.spaceMd),
            status: nextEnabled
                ? AppButtonStatus.enabled
                : AppButtonStatus.disabled,
            onTap: onNext,
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
