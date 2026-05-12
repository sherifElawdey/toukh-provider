import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:toukh_provider/core/constants/app_assets.dart';
import 'package:toukh_provider/core/router/app_routes.dart';
import 'package:toukh_ui/toukh_ui.dart';
import 'package:toukh_provider/l10n/app_strings.dart';

class RequestSubmittedScreen extends StatelessWidget {
  const RequestSubmittedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (!context.mounted) return;
        context.go(AppRoutes.login);
      },
      child: AppSuccessScreen(
        imagePath: AppAssets.brandingProviderAppIcon,
        imageAssetPackage: null,
        title: AppStrings.Auth.requestSubmittedTitle,
        description: AppStrings.Auth.requestSubmittedSubtitle,
        actionText: AppStrings.Auth.backToLogin,
        actionOnPressed: () => context.go(AppRoutes.login),
      ),
    );
  }
}
