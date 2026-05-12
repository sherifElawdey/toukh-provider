import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:toukh_ui/toukh_ui.dart';
import 'package:toukh_provider/l10n/app_strings.dart';

/// Loads and displays `package_info_plus` version + build.
class SettingsAppVersionFooter extends StatefulWidget {
  const SettingsAppVersionFooter({super.key});

  @override
  State<SettingsAppVersionFooter> createState() =>
      _SettingsAppVersionFooterState();
}

class _SettingsAppVersionFooterState extends State<SettingsAppVersionFooter> {
  String? _versionLine;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final info = await PackageInfo.fromPlatform();
      if (!mounted) return;
      setState(() {
        _versionLine = '${info.version} (${info.buildNumber})';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _versionLine = '—');
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final line = _versionLine;
    return Padding(
      padding: const EdgeInsets.only(top: AppSizes.spaceXl),
      child: Column(
        children: [
          CustomText(
            AppStrings.Settings.appVersion,
            style: TextStyle(
              fontSize: AppSizes.fontCaption,
              fontWeight: FontWeight.w600,
              color: scheme.onSurface.withValues(alpha: 0.45),
            ),
          ),
          SizedBox(height: AppSizes.spaceXs),
          Text(
            line ?? '…',
            style: TextStyle(
              fontFamily: AppFonts.family,
              fontSize: AppSizes.fontLabel,
              fontWeight: FontWeight.w500,
              color: scheme.onSurface.withValues(alpha: 0.55),
            ),
          ),
        ],
      ),
    );
  }
}
