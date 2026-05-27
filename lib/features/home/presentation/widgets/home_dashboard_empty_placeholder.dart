import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:toukh_ui/toukh_ui.dart';

class HomeDashboardEmptyPlaceholder extends StatelessWidget {
  const HomeDashboardEmptyPlaceholder({
    super.key,
    required this.icon,
    required this.message,
  });

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSizes.spaceMd),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 40,
              color: scheme.onSurface.withValues(alpha: 0.35),
            ),
            const SizedBox(height: AppSizes.spaceSm),
            CustomText(
              message.tr,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: AppSizes.fontBody,
                color: scheme.onSurface.withValues(alpha: 0.55),
                height: 1.35,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
