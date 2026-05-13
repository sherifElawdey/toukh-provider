import 'package:flutter/material.dart';
import 'package:toukh_ui/toukh_ui.dart';

class SettingsSectionTitle extends StatelessWidget {
  const SettingsSectionTitle({super.key, required this.labelKey});

  final String labelKey;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: AppSizes.spaceSm),
      child: CustomText(
        labelKey,
        style: TextStyle(
          fontSize: AppSizes.fontLabel,
          fontWeight: FontWeight.w700,
          color: Theme.of(context)
              .colorScheme
              .onSurface
              .withValues(alpha: 0.55),
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}
