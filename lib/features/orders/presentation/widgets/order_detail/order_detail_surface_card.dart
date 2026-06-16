import 'package:flutter/material.dart';
import 'package:toukh_ui/toukh_ui.dart';

/// Bordered surface container shared by order detail sections.
class OrderDetailSurfaceCard extends StatelessWidget {
  const OrderDetailSurfaceCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSizes.spaceBase),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: child,
    );
  }
}
