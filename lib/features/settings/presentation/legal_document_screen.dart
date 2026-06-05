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
          icon: Icon(ToukhIcons.back),
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
            AppFilledButton(
              text: AppStrings.Settings.legalOpenInBrowser,
              icon: PhosphorIconsRegular.arrowSquareOut,
              color: AppColors.secondColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                vertical: AppSizes.spaceMd,
                horizontal: AppSizes.spaceBase,
              ),
              onTap: () async {
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
                    icon: ToukhIcons.error,
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
