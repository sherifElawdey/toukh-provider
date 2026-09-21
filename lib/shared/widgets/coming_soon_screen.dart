import 'package:flutter/material.dart';
import 'package:toukh_provider/shared/widgets/custom_text.dart';
import 'package:toukh_provider/shared/theme/app_sizes.dart';

/// Placeholder route screen used for unfinished surfaces.
class ComingSoonScreen extends StatelessWidget {
  const ComingSoonScreen({
    super.key,
    this.appBarTitle,
    this.title,
    this.message,
    this.showBack = true,
  });

  final String? appBarTitle;
  final String? title;
  final String? message;
  final bool showBack;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: showBack,
        title: CustomText(
          appBarTitle ?? 'Coming soon',
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: AppSizes.fontTitle,
          ),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.spaceLg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.hourglass_empty, size: 48, color: scheme.primary),
              const SizedBox(height: AppSizes.spaceMd),
              CustomText(
                title ?? 'Coming soon',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: AppSizes.fontTitle,
                  color: scheme.onSurface,
                ),
                textAlign: TextAlign.center,
              ),
              if (message != null) ...[
                const SizedBox(height: AppSizes.spaceSm),
                CustomText(
                  message!,
                  style: TextStyle(color: scheme.onSurfaceVariant),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
