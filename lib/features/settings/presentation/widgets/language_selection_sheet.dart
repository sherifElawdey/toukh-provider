import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:toukh_ui/toukh_ui.dart';
import 'package:toukh_provider/core/settings/settings_cubit.dart';
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
              _LanguageOption(
                flag: '🇬🇧',
                labelKey: AppStrings.Common.english,
                locale: const Locale('en'),
                selected: current == 'en',
                onSelected: (locale) {
                  settingsCubit.setLocale(locale);
                  Navigator.pop(sheetContext);
                },
              ),
              _LanguageOption(
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

class _LanguageOption extends StatelessWidget {
  const _LanguageOption({
    required this.flag,
    required this.labelKey,
    required this.locale,
    required this.selected,
    required this.onSelected,
  });

  final String flag;
  final String labelKey;
  final Locale locale;
  final bool selected;
  final ValueChanged<Locale> onSelected;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSizes.spaceSm),
      child: Material(
        color: selected
            ? AppColors.secondColor.withValues(alpha: 0.1)
            : scheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          onTap: () => onSelected(locale),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.spaceBase,
              vertical: AppSizes.spaceMd,
            ),
            child: Row(
              children: [
                Text(flag, style: const TextStyle(fontSize: 28)),
                SizedBox(width: AppSizes.spaceMd),
                Expanded(
                  child: CustomText(
                    labelKey,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: AppSizes.fontBody,
                      color: scheme.onSurface,
                    ),
                  ),
                ),
                if (selected)
                  Icon(
                    Icons.check_circle_rounded,
                    color: AppColors.secondColor,
                    size: 22,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
