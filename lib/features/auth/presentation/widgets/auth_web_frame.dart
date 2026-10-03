import 'package:flutter/material.dart';
import 'package:toukh_provider/core/constants/app_assets.dart';
import 'package:toukh_provider/core/widgets/toukh_service_logo.dart';
import 'package:toukh_provider/features/shell/provider_web_layout.dart';
import 'package:toukh_provider/l10n/app_strings.dart';
import 'package:toukh_ui/toukh_ui.dart';

/// Brand panel plus content for login and signup on a wide browser.
///
/// Phone, tablet, and a narrow browser keep [child] unchanged.
class AuthWebFrame extends StatelessWidget {
  const AuthWebFrame({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!ProviderWebLayout.isWide(context)) return child;

    return LayoutBuilder(
      builder: (context, constraints) {
        final panelWidth = (constraints.maxWidth * 0.38).clamp(340.0, 480.0);
        return ColoredBox(
          color: Theme.of(context).scaffoldBackgroundColor,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(width: panelWidth, child: const _AuthWebBrandPanel()),
              Expanded(child: child),
            ],
          ),
        );
      },
    );
  }
}

/// Keeps a form from stretching across a wide content pane.
class AuthWebCentered extends StatelessWidget {
  const AuthWebCentered({
    super.key,
    required this.maxWidth,
    required this.child,
  });

  final double maxWidth;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!ProviderWebLayout.isWide(context)) return child;
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}

class _AuthWebBrandPanel extends StatelessWidget {
  const _AuthWebBrandPanel();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.secondColor,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const ColoredBox(color: AppColors.secondColor),
          Image.asset(
            AppAssets.brandingProviderAppIcon,
            fit: BoxFit.contain,
            alignment: Alignment.center,
          ),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0x332D70BA),
                  Color(0x002D70BA),
                  Color(0xE62D70BA),
                ],
                stops: [0.0, 0.38, 1.0],
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.space3xl,
                vertical: AppSizes.space4xl,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: const ToukhServiceLogo(size: 72),
                  ),
                  const SizedBox(height: AppSizes.space3xl),
                  CustomText(
                    AppStrings.App.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      height: 1.15,
                    ),
                  ),
                  const SizedBox(height: AppSizes.spaceMd),
                  CustomText(
                    AppStrings.Auth.createAccountSubtitle,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.92),
                      fontSize: AppSizes.fontBody,
                      height: 1.45,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
