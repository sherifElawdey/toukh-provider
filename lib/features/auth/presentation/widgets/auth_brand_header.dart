import 'package:flutter/material.dart';
import 'package:toukh_provider/core/widgets/toukh_service_logo.dart';
import 'package:toukh_ui/toukh_ui.dart';

class AuthBrandHeader extends StatelessWidget {
  const AuthBrandHeader({
    super.key,
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        ToukhServiceLogo(
          size: AppSizes.logoAuth,
        ),
        SizedBox(height: AppSizes.spaceXl),
        CustomText(
          title,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: AppSizes.fontHeadline,
            fontWeight: FontWeight.w700,
            color: AppColors.secondColor,
            height: 1.2,
          ),
        ),
        SizedBox(height: AppSizes.spaceSm),
        CustomText(
          subtitle,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: AppSizes.fontBody,
            height: 1.45,
            color: scheme.onSurface.withValues(alpha: 0.72),
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }
}
