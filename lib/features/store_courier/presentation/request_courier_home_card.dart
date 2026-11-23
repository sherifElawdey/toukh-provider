import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:toukh_provider/core/router/app_routes.dart';
import 'package:toukh_provider/l10n/app_strings.dart';
import 'package:toukh_ui/toukh_ui.dart';

/// Home entry: "Request a courier to deliver your order".
class RequestCourierHomeCard extends StatelessWidget {
  const RequestCourierHomeCard({super.key});

  @override
  Widget build(BuildContext context) {
    final accent = AppColors.secondColor;
    final radius = BorderRadius.circular(AppSizes.radiusLg);
    return Material(
      color: AppColors.tint(context, accent),
      borderRadius: radius,
      child: InkWell(
        borderRadius: radius,
        onTap: () => context.push(AppRoutes.requestCourier),
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.spaceMd),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: accent,
                  borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                ),
                child: Icon(
                  PhosphorIconsDuotone.moped,
                  color: Colors.white,
                  size: 26,
                ),
              ),
              const SizedBox(width: AppSizes.spaceMd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomText(
                      AppStrings.StoreCourier.homeTitle,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: AppSizes.spaceXs),
                    CustomText(
                      AppStrings.StoreCourier.homeSubtitle,
                      style: TextStyle(
                        fontSize: AppSizes.fontCaption,
                        height: 1.4,
                        color: AppColors.muted(context),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(ToukhIcons.chevronRight, color: accent),
            ],
          ),
        ),
      ),
    );
  }
}
