import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:toukh_provider/shared/constants/ui_assets.dart';
import 'package:toukh_provider/shared/theme/app_sizes.dart';
import 'package:toukh_provider/shared/widgets/custom_text.dart';
import 'package:toukh_provider/shared/widgets/toukh_section_placeholder.dart';

/// Empty state with a section-appropriate illustration and message.
class ToukhSectionEmptyState extends StatelessWidget {
  const ToukhSectionEmptyState({
    super.key,
    required this.category,
    required this.message,
    this.subtitle,
    this.illustrationSize = 120,
    this.padding = const EdgeInsets.symmetric(vertical: AppSizes.spaceMd),
  });

  final ToukhServiceCategory category;
  final String message;
  final String? subtitle;
  final double illustrationSize;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final resolvedMessage = message.contains('.') ? message.tr : message;
    final resolvedSubtitle = subtitle == null
        ? null
        : (subtitle!.contains('.') ? subtitle!.tr : subtitle!);

    return Padding(
      padding: padding,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ToukhSectionPlaceholder(
              category: category,
              width: illustrationSize,
              height: illustrationSize,
            ),
            const SizedBox(height: AppSizes.spaceSm),
            CustomText(
              resolvedMessage,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: AppSizes.fontBody,
                fontWeight: FontWeight.w600,
                color: scheme.onSurface.withValues(alpha: 0.75),
                height: 1.35,
              ),
            ),
            if (resolvedSubtitle != null) ...[
              const SizedBox(height: AppSizes.spaceXs),
              CustomText(
                resolvedSubtitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: AppSizes.fontCaption,
                  color: scheme.onSurface.withValues(alpha: 0.55),
                  height: 1.35,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
