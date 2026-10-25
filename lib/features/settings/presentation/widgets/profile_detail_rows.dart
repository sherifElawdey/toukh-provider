import 'package:flutter/material.dart';
import 'package:toukh_provider/features/settings/presentation/widgets/settings_section_title.dart';
import 'package:toukh_ui/toukh_ui.dart';

/// Titled group of [ProfileDetailRow]s with hairline dividers between them.
class ProfileDetailSection extends StatelessWidget {
  const ProfileDetailSection({
    super.key,
    required this.titleKey,
    required this.rows,
  });

  final String titleKey;
  final List<ProfileDetailRow> rows;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SettingsSectionTitle(labelKey: titleKey),
        SizedBox(height: AppSizes.spaceSm),
        for (var i = 0; i < rows.length; i++) ...[
          rows[i],
          if (i < rows.length - 1)
            const Divider(
              height: 1,
              thickness: 0.5,
              indent: ProfileDetailRow.iconSize + AppSizes.spaceMd,
            ),
        ],
      ],
    );
  }
}

/// Icon, label and value row; shows a chevron (or lock) when tappable.
class ProfileDetailRow extends StatelessWidget {
  const ProfileDetailRow({
    super.key,
    required this.icon,
    required this.labelKey,
    required this.value,
    this.onTap,
    this.locked = false,
  });

  final IconData icon;
  final String labelKey;
  final String value;
  final VoidCallback? onTap;
  final bool locked;

  static const double iconSize = 40;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final content = Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSizes.spaceMd),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          ToukhIconWell(icon: icon, size: ProfileDetailRow.iconSize),
          SizedBox(width: AppSizes.spaceMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomText(
                  labelKey,
                  style: TextStyle(
                    fontSize: AppSizes.fontLabel,
                    fontWeight: FontWeight.w600,
                    color: scheme.onSurface.withValues(alpha: 0.55),
                  ),
                ),
                SizedBox(height: AppSizes.spaceXs),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: AppSizes.fontBody,
                    height: 1.35,
                    fontWeight: FontWeight.w500,
                    color: scheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
          if (onTap != null) ...[
            SizedBox(width: AppSizes.spaceSm),
            Icon(
              locked ? ToukhIcons.lock : ToukhIcons.chevronRight,
              size: locked ? 18 : 20,
              color: scheme.onSurface.withValues(alpha: locked ? 0.35 : 0.45),
            ),
          ],
        ],
      ),
    );

    if (onTap == null) return content;

    return Material(
      color: Colors.transparent,
      child: InkWell(onTap: onTap, child: content),
    );
  }
}
