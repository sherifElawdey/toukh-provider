import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:toukh_provider/core/constants/app_constants.dart';
import 'package:toukh_provider/core/router/app_routes.dart';
import 'package:toukh_provider/core/widgets/toukh_service_logo.dart';
import 'package:toukh_provider/features/settings/presentation/widgets/settings_tile.dart';
import 'package:toukh_provider/l10n/app_strings.dart';
import 'package:toukh_ui/toukh_ui.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutAppScreen extends StatefulWidget {
  const AboutAppScreen({super.key});

  @override
  State<AboutAppScreen> createState() => _AboutAppScreenState();
}

class _AboutAppScreenState extends State<AboutAppScreen> {
  String? _version;
  String? _buildNumber;

  @override
  void initState() {
    super.initState();
    _loadPackageInfo();
  }

  Future<void> _loadPackageInfo() async {
    try {
      final info = await PackageInfo.fromPlatform();
      if (!mounted) return;
      setState(() {
        _version = info.version;
        _buildNumber = info.buildNumber;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _version = '—';
        _buildNumber = '—';
      });
    }
  }

  Future<void> _openSupportEmail(BuildContext context) async {
    final uri = Uri(
      scheme: 'mailto',
      path: AppConstants.supportEmail,
      queryParameters: {'subject': 'Toukh Service support'},
    );
    final ok = await launchUrl(uri);
    if (!context.mounted) return;
    if (!ok) {
      AppSnack.show(
        context,
        message: AppStrings.Settings.legalLaunchFailed,
        state: AppSnackState.error,
        icon: ToukhIcons.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final versionLine = _version == null
        ? '…'
        : '${_version!} (${_buildNumber ?? '—'})';

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(ToukhIcons.back),
          onPressed: () => context.pop(),
        ),
        title: CustomText(AppStrings.Settings.aboutApp),
      ),
      body: ListView(
        padding: AppSizes.screenPadding.copyWith(
          top: AppSizes.spaceXl,
          bottom: AppSizes.space2xl,
        ),
        children: [
          Center(
            child: ToukhServiceLogo(
              size: 96,
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          SizedBox(height: AppSizes.spaceLg),
          Center(
            child: CustomText(
              AppStrings.App.title,
              style: TextStyle(
                fontSize: AppSizes.fontHeadline,
                fontWeight: FontWeight.w800,
                color: scheme.onSurface,
              ),
            ),
          ),
          SizedBox(height: AppSizes.spaceSm),
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSizes.spaceXl),
              child: CustomText(
                AppStrings.Settings.aboutTagline,
                style: TextStyle(
                  fontSize: AppSizes.fontBody,
                  height: 1.45,
                  color: scheme.onSurface.withValues(alpha: 0.65),
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          SizedBox(height: AppSizes.spaceXl),
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSizes.radiusLg),
              side: BorderSide(color: AppColors.borderSubtle),
            ),
            child: Padding(
              padding: const EdgeInsets.all(AppSizes.spaceLg),
              child: Row(
                children: [
                  Icon(
                    ToukhIcons.info,
                    color: AppColors.appColor,
                    size: 28,
                  ),
                  SizedBox(width: AppSizes.spaceMd),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CustomText(
                          AppStrings.Settings.appVersion,
                          style: TextStyle(
                            fontSize: AppSizes.fontLabel,
                            fontWeight: FontWeight.w600,
                            color: scheme.onSurface.withValues(alpha: 0.62),
                          ),
                        ),
                        SizedBox(height: AppSizes.spaceXs),
                        Text(
                          versionLine,
                          style: TextStyle(
                            fontFamily: AppFonts.family,
                            fontSize: AppSizes.fontTitle,
                            fontWeight: FontWeight.w700,
                            color: scheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: AppSizes.spaceXl),
          SettingsTile(
            icon: ToukhIcons.document,
            titleKey: AppStrings.Settings.termsAndConditions,
            trailing: Icon(
              ToukhIcons.chevronRight,
              color: scheme.onSurface.withValues(alpha: 0.45),
            ),
            onTap: () => context.push(AppRoutes.legalTerms),
          ),
          SettingsTile(
            icon: ToukhIcons.privacy,
            titleKey: AppStrings.Settings.privacyPolicy,
            trailing: Icon(
              ToukhIcons.chevronRight,
              color: scheme.onSurface.withValues(alpha: 0.45),
            ),
            onTap: () => context.push(AppRoutes.legalPrivacy),
          ),
          SettingsTile(
            icon: ToukhIcons.article,
            titleKey: AppStrings.Settings.declaration,
            trailing: Icon(
              ToukhIcons.chevronRight,
              color: scheme.onSurface.withValues(alpha: 0.45),
            ),
            onTap: () => context.push(AppRoutes.legalDeclaration),
          ),
          SettingsTile(
            icon: ToukhIcons.email,
            titleKey: AppStrings.Settings.support,
            trailing: CustomText(
              AppConstants.supportEmail,
              style: TextStyle(
                fontSize: AppSizes.fontLabel,
                color: scheme.onSurface.withValues(alpha: 0.55),
              ),
            ),
            onTap: () => _openSupportEmail(context),
          ),
          SizedBox(height: AppSizes.space2xl),
          Center(
            child: CustomText(
              AppStrings.Settings.copyright,
              style: TextStyle(
                fontSize: AppSizes.fontCaption,
                color: scheme.onSurface.withValues(alpha: 0.45),
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}
