import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:toukh_provider/core/widgets/toukh_service_logo.dart';
import 'package:toukh_provider/core/router/app_routes.dart';
import 'package:toukh_provider/core/settings/settings_cubit.dart';
import 'package:toukh_provider/l10n/app_strings.dart';
import 'package:toukh_ui/toukh_ui.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  static const _flagUk = '🇬🇧';
  static const _flagEg = '🇪🇬';

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final settings = context.watch<SettingsCubit>().state;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.thirdColor.withValues(alpha: isDark ? 0.35 : 0.5),
              scheme.surface,
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: AppSizes.screenPadding.copyWith(
              top: AppSizes.spaceXl,
              bottom: AppSizes.space2xl,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 112,
                    height: 112,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.secondColor.withValues(alpha: 0.22),
                          blurRadius: 24,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: ToukhServiceLogo(
                      size: 112,
                      fit: BoxFit.cover,
                      borderRadius: BorderRadius.circular(28),
                    ),
                  ),
                ),
                SizedBox(height: AppSizes.spaceXl),
                CustomText(
                  AppStrings.Welcome.title.tr,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: AppSizes.fontHeadline,
                    fontWeight: FontWeight.w800,
                    color: AppColors.secondColor,
                    height: 1.15,
                    letterSpacing: -0.3,
                  ),
                ),
                SizedBox(height: AppSizes.spaceSm),
                CustomText(
                  AppStrings.Welcome.subtitle.tr,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: AppSizes.fontBody,
                    height: 1.5,
                    color: scheme.onSurface.withValues(alpha: 0.7),
                    fontWeight: FontWeight.w400,
                  ),
                ),
                SizedBox(height: AppSizes.space2xl),
                _SectionLabel(
                  label: AppStrings.Welcome.chooseLanguage.tr,
                  scheme: scheme,
                ),
                SizedBox(height: AppSizes.spaceMd),
                Row(
                  children: [
                    Expanded(
                      child: _LocaleChoiceCard(
                        selected: settings.locale.languageCode == 'en',
                        flagText: _flagUk,
                        regionLabel: AppStrings.Welcome.regionUk.tr,
                        languageLabel: AppStrings.Common.english.tr,
                        onTap: () =>
                            context.read<SettingsCubit>().setLocale(
                                  const Locale('en'),
                                ),
                      ),
                    ),
                    SizedBox(width: AppSizes.spaceMd),
                    Expanded(
                      child: _LocaleChoiceCard(
                        selected: settings.locale.languageCode == 'ar',
                        flagText: _flagEg,
                        regionLabel: AppStrings.Welcome.regionEgypt.tr,
                        languageLabel: AppStrings.Common.arabic.tr,
                        onTap: () =>
                            context.read<SettingsCubit>().setLocale(
                                  const Locale('ar'),
                                ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: AppSizes.spaceXl),
                _SectionLabel(
                  label: AppStrings.Welcome.chooseTheme.tr,
                  scheme: scheme,
                ),
                SizedBox(height: AppSizes.spaceMd),
                Row(
                  children: [
                    Expanded(
                      child: _ThemeChoiceCard(
                        selected: settings.themeMode == ThemeMode.light,
                        icon: Icons.wb_sunny_rounded,
                        label: AppStrings.Common.light.tr,
                        onTap: () => context
                            .read<SettingsCubit>()
                            .setThemeMode(ThemeMode.light),
                      ),
                    ),
                    SizedBox(width: AppSizes.spaceMd),
                    Expanded(
                      child: _ThemeChoiceCard(
                        selected: settings.themeMode == ThemeMode.dark,
                        icon: Icons.dark_mode_rounded,
                        label: AppStrings.Common.dark.tr,
                        onTap: () => context
                            .read<SettingsCubit>()
                            .setThemeMode(ThemeMode.dark),
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                FilledButton(
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(AppSizes.radiusLg),
                    ),
                  ),
                  onPressed: () async {
                    final ok = await context
                        .read<SettingsCubit>()
                        .persistWelcomeSelectionsAndComplete();
                    if (!context.mounted) return;
                    if (!ok) {
                      AppSnack.show(
                        context,
                        message: AppStrings.Common.unknownError.tr,
                        state: AppSnackState.error,
                        icon: Icons.error_outline_rounded,
                      );
                      return;
                    }
                    context.go(AppRoutes.splash);
                  },
                  child: CustomText(AppStrings.Common.continueLabel),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({
    required this.label,
    required this.scheme,
  });

  final String label;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.1,
          color: scheme.onSurface.withValues(alpha: 0.45),
        ),
      ),
    );
  }
}

class _LocaleChoiceCard extends StatelessWidget {
  const _LocaleChoiceCard({
    required this.selected,
    required this.flagText,
    required this.regionLabel,
    required this.languageLabel,
    required this.onTap,
  });

  final bool selected;
  final String flagText;
  final String regionLabel;
  final String languageLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final borderColor = selected
        ? AppColors.secondColor
        : scheme.outline.withValues(alpha: 0.12);
    final fill = selected
        ? AppColors.secondColor.withValues(alpha: 0.08)
        : scheme.surfaceContainerHighest.withValues(alpha: 0.45);

    return Material(
      color: fill,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        side: BorderSide(
          color: borderColor,
          width: selected ? 2 : 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.spaceMd,
            vertical: AppSizes.spaceBase,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    flagText,
                    style: const TextStyle(fontSize: 26, height: 1),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      regionLabel,
                      style: TextStyle(
                        fontSize: AppSizes.fontTitle,
                        fontWeight: FontWeight.w700,
                        color: scheme.onSurface,
                      ),
                    ),
                  ),
                  if (selected)
                    Icon(
                      Icons.check_circle_rounded,
                      size: 22,
                      color: AppColors.secondColor,
                    ),
                ],
              ),
              SizedBox(height: AppSizes.spaceXs),
              Text(
                languageLabel,
                style: TextStyle(
                  fontSize: AppSizes.fontLabel,
                  fontWeight: FontWeight.w500,
                  color: scheme.onSurface.withValues(alpha: 0.62),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ThemeChoiceCard extends StatelessWidget {
  const _ThemeChoiceCard({
    required this.selected,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final bool selected;
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final borderColor = selected
        ? AppColors.secondColor
        : scheme.outline.withValues(alpha: 0.12);
    final fill = selected
        ? AppColors.secondColor.withValues(alpha: 0.08)
        : scheme.surfaceContainerHighest.withValues(alpha: 0.45);

    return Material(
      color: fill,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        side: BorderSide(
          color: borderColor,
          width: selected ? 2 : 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            vertical: AppSizes.spaceBase,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 32,
                color: selected
                    ? AppColors.secondColor
                    : scheme.onSurface.withValues(alpha: 0.55),
              ),
              SizedBox(height: AppSizes.spaceSm),
              CustomText(
                label,
                style: TextStyle(
                  fontSize: AppSizes.fontBody,
                  fontWeight: FontWeight.w700,
                  color: scheme.onSurface,
                ),
              ),
              if (selected) ...[
                SizedBox(height: 4),
                Icon(
                  Icons.check_circle_rounded,
                  size: 18,
                  color: AppColors.secondColor,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
