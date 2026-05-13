import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:toukh_ui/toukh_ui.dart';
import 'package:toukh_provider/core/settings/settings_cubit.dart';
import 'package:toukh_provider/features/settings/presentation/widgets/language_selection_option.dart';
import 'package:toukh_provider/l10n/app_strings.dart';

void showLanguageSelectionSheet(
  BuildContext context, {
  required SettingsState settings,
}) {
  final settingsCubit = context.read<SettingsCubit>();
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: Theme.of(context).colorScheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(AppSizes.radiusXl),
      ),
    ),
    builder: (sheetContext) {
      final current = settings.locale.languageCode;
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSizes.spaceLg,
            AppSizes.spaceBase,
            AppSizes.spaceLg,
            AppSizes.spaceLg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .outline
                        .withValues(alpha: 0.45),
                    borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                  ),
                ),
              ),
              SizedBox(height: AppSizes.spaceLg),
              CustomText(
                AppStrings.Settings.selectLanguage,
                style: TextStyle(
                  fontSize: AppSizes.fontTitle,
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              SizedBox(height: AppSizes.spaceBase),
              LanguageSelectionOption(
                flag: '🇬🇧',
                labelKey: AppStrings.Common.english,
                locale: const Locale('en'),
                selected: current == 'en',
                onSelected: (locale) {
                  settingsCubit.setLocale(locale);
                  Navigator.pop(sheetContext);
                },
              ),
              LanguageSelectionOption(
                flag: '🇪🇬',
                labelKey: AppStrings.Common.arabic,
                locale: const Locale('ar'),
                selected: current == 'ar',
                onSelected: (locale) {
                  settingsCubit.setLocale(locale);
                  Navigator.pop(sheetContext);
                },
              ),
            ],
          ),
        ),
      );
    },
  );
}
