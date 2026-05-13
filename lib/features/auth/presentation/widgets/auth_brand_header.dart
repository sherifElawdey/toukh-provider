import 'package:flutter/material.dart';
import 'package:toukh_provider/core/widgets/toukh_service_logo.dart';
import 'package:toukh_ui/toukh_ui.dart';

class AuthBrandHeader extends StatelessWidget {
  const AuthBrandHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.logoSize,
  });

  final String title;
  final String subtitle;
  final double? logoSize;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final effectiveLogo = logoSize ?? AppSizes.logoAuth;
    return Column(
      children: [
        ToukhServiceLogo(
          size: effectiveLogo,
        ),
        SizedBox(
          height: effectiveLogo < AppSizes.logoAuth
              ? AppSizes.spaceMd
              : AppSizes.spaceXl,
        ),
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
