import 'package:flutter/material.dart';
import 'package:toukh_provider/features/registration/presentation/widgets/registration_step_layout.dart';
import 'package:toukh_ui/toukh_ui.dart';

class RegisterKindCard extends StatelessWidget {
  const RegisterKindCard({
    super.key,
    required this.selected,
    required this.title,
    required this.icon,
    required this.onTap,
  });

  final bool selected;
  final String title;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: selected
          ? AppColors.tint(context, AppColors.secondColor)
          : scheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        side: BorderSide(
          color: selected ? AppColors.secondColor : AppColors.borderSubtle,
          width: selected ? 2.5 : 1.2,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.spaceSm,
                vertical: AppSizes.spaceMd,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  RegistrationIllustration(icon: icon, size: 68),
                  SizedBox(height: AppSizes.spaceSm),
                  CustomText(
                    title,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: AppSizes.fontBody,
                      fontWeight: FontWeight.w800,
                      height: 1.25,
                      color: selected
                          ? AppColors.secondColor
                          : scheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),
            if (selected)
              PositionedDirectional(
                top: 8,
                end: 8,
                child: Icon(
                  PhosphorIconsFill.checkCircle,
                  color: AppColors.success,
                  size: 24,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
