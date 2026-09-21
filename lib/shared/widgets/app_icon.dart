import 'package:flutter/widgets.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:toukh_provider/shared/theme/app_sizes.dart';

/// Phosphor icon with Toukh default sizing.
class AppIcon extends StatelessWidget {
  const AppIcon(
    this.icon, {
    super.key,
    this.color,
    this.size,
    this.semanticLabel,
  });

  final IconData icon;
  final Color? color;
  final double? size;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    return PhosphorIcon(
      icon,
      color: color,
      size: size ?? AppSizes.iconMd,
      semanticLabel: semanticLabel,
    );
  }
}
