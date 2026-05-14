import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:toukh_provider/core/widgets/toukh_service_logo.dart';
import 'package:toukh_provider/core/router/app_routes.dart';
import 'package:toukh_provider/core/settings/settings_cubit.dart';
import 'package:toukh_provider/features/welcome/widgets/welcome_locale_choice_card.dart';
import 'package:toukh_provider/features/welcome/widgets/welcome_section_label.dart';
import 'package:toukh_provider/features/welcome/widgets/welcome_theme_choice_card.dart';
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
                WelcomeSectionLabel(
                  label: AppStrings.Welcome.chooseLanguage.tr,
                  scheme: scheme,
                ),
                SizedBox(height: AppSizes.spaceMd),
                Row(
                  children: [
                    Expanded(
                      child: WelcomeLocaleChoiceCard(
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
                      child: WelcomeLocaleChoiceCard(
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
                WelcomeSectionLabel(
                  label: AppStrings.Welcome.chooseTheme.tr,
                  scheme: scheme,
                ),
                SizedBox(height: AppSizes.spaceMd),
                Row(
                  children: [
                    Expanded(
                      child: WelcomeThemeChoiceCard(
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
                      child: WelcomeThemeChoiceCard(
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
                AppFilledButton(
                  text: AppStrings.Common.continueLabel,
                  height: 52,
                  onTap: () async {
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
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

