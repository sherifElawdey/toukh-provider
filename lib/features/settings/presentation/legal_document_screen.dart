import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:toukh_ui/toukh_ui.dart';
import 'package:toukh_provider/l10n/app_strings.dart';
import 'package:url_launcher/url_launcher.dart';

class LegalDocumentScreen extends StatelessWidget {
  const LegalDocumentScreen({
    super.key,
    required this.titleKey,
    required this.url,
  });

  final String titleKey;
  final String url;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        title: CustomText(
          titleKey,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: AppSizes.fontTitle,
          ),
        ),
      ),
      body: Padding(
        padding: AppSizes.screenPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            CustomText(
              AppStrings.Settings.legalOpenInBrowserHint,
              style: TextStyle(
                fontSize: AppSizes.fontBody,
                height: 1.45,
                color: scheme.onSurface.withValues(alpha: 0.85),
              ),
            ),
            SizedBox(height: AppSizes.spaceLg),
            FilledButton.icon(
              onPressed: () async {
                final uri = Uri.parse(url);
                final ok = await launchUrl(
                  uri,
                  mode: LaunchMode.externalApplication,
                );
                if (!context.mounted) return;
                if (!ok) {
                  AppSnack.show(
                    context,
                    message: AppStrings.Settings.legalLaunchFailed,
                    state: AppSnackState.error,
                    icon: Icons.error_outline_rounded,
                  );
                }
              },
              icon: const Icon(Icons.open_in_new_rounded),
              label: CustomText(AppStrings.Settings.legalOpenInBrowser),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.secondColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  vertical: AppSizes.spaceMd,
                  horizontal: AppSizes.spaceBase,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
