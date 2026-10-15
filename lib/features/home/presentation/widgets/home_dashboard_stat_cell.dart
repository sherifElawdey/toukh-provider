import 'package:flutter/material.dart';
import 'package:toukh_provider/features/home/presentation/widgets/dashboard_shell.dart';
import 'package:toukh_ui/toukh_ui.dart';

class HomeDashboardStatCell extends StatelessWidget {
  const HomeDashboardStatCell({
    super.key,
    required this.label,
    required this.color,
    required this.value,
    required this.icon,
    required this.caption,
  });

  final String label;
  final Color color;
  final IconData icon;
  final String value;
  final String caption;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(AppSizes.spaceMd),
      decoration: dashboardSoftDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ToukhIconWell(icon: icon, color: color, size: 34, iconSize: 18),
          const SizedBox(height: AppSizes.spaceMd),
          CustomText(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              height: 1.15,
              color: scheme.onSurface,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(height: 2),
          CustomText(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
