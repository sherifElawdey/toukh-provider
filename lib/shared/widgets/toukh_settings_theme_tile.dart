import 'package:flutter/material.dart';

import '../icons/toukh_icons.dart';
import '../theme/app_colors.dart';
import '../theme/app_sizes.dart';
import 'toukh_theme_mode_icon_toggle.dart';

/// Settings row for theme mode — matches card-style settings tiles with a
/// trailing sun/moon icon toggle.
class ToukhSettingsThemeTile extends StatelessWidget {
  const ToukhSettingsThemeTile({
    super.key,
    required this.title,
    required this.value,
    required this.onChanged,
    this.leadingIcon,
  });

  final Widget title;
  final ThemeMode value;
  final ValueChanged<ThemeMode> onChanged;
  final IconData? leadingIcon;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSizes.spaceSm),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.spaceBase,
          vertical: AppSizes.spaceMd,
        ),
        child: Row(
          children: [
            Icon(
              leadingIcon ?? ToukhIcons.lightMode,
              color: AppColors.appColor,
              size: 24,
            ),
            SizedBox(width: AppSizes.spaceMd),
            Expanded(child: title),
            ToukhThemeModeIconToggle(
              value: value,
              onChanged: onChanged,
            ),
          ],
        ),
      ),
    );
  }
}
