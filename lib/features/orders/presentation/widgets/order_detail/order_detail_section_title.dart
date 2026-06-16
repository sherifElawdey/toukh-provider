import 'package:flutter/material.dart';
import 'package:toukh_ui/toukh_ui.dart';

class OrderDetailSectionTitle extends StatelessWidget {
  const OrderDetailSectionTitle({
    super.key,
    required this.label,
    this.icon,
  });

  final String label;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (icon != null) ...[
          Icon(icon, size: 18, color: AppColors.secondColor),
          const SizedBox(width: AppSizes.spaceSm),
        ],
        Expanded(
          child: CustomText(
            label,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.secondColor,
                ),
          ),
        ),
      ],
    );
  }
}
