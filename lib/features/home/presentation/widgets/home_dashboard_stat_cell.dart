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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      decoration: dashboardSoftDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.all(6),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 8),
          CustomText(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: scheme.onSurface.withValues(alpha: 0.58),
            ),
          ),
          const SizedBox(height: 4),
          CustomText(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: scheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}
