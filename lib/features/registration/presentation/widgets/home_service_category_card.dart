import 'package:flutter/material.dart';
import 'package:toukh_provider/domain/entities/home_service_category.dart';
import 'package:toukh_ui/toukh_ui.dart';

class HomeServiceCategoryCard extends StatelessWidget {
  const HomeServiceCategoryCard({
    super.key,
    required this.category,
    required this.selected,
    required this.scheme,
    required this.onTap,
  });

  final HomeServiceCategory category;
  final bool selected;
  final ColorScheme scheme;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final desc = category.description;
    return Material(
      color: selected
          ? AppColors.thirdColor.withValues(alpha: 0.35)
          : scheme.surfaceContainerHighest.withValues(alpha: 0.45),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        side: BorderSide(
          color: selected ? AppColors.secondColor : Colors.transparent,
          width: 2,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius:
                        BorderRadius.circular(AppSizes.radiusMd),
                    child: ColoredBox(
                      color: scheme.surfaceContainerHigh
                          .withValues(alpha: 0.5),
                      child: category.imageUrl != null &&
                              category.imageUrl!.isNotEmpty
                          ? Image.network(
                              category.imageUrl!,
                              fit: BoxFit.cover,
                              filterQuality: FilterQuality.medium,
                              errorBuilder: (_, _, _) => Center(
                                child: Icon(
                                  PhosphorIconsRegular.wrench,
                                  size: 40,
                                  color: AppColors.secondColor,
                                ),
                              ),
                            )
                          : Center(
                              child: Icon(
                                PhosphorIconsRegular.wrench,
                                size: 40,
                                color: AppColors.secondColor,
                              ),
                            ),
                    ),
                  ),
                  if (selected)
                    Positioned(
                      top: AppSizes.spaceXs,
                      right: AppSizes.spaceXs,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: scheme.surface.withValues(alpha: 0.92),
                          shape: BoxShape.circle,
                        ),
                        child: const Padding(
                          padding: EdgeInsets.all(2),
                          child: Icon(
                            PhosphorIconsFill.checkCircle,
                            color: AppColors.success,
                            size: 22,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            // SizedBox(height: AppSizes.spaceXs),
            Padding(
              padding: const EdgeInsets.all(AppSizes.spaceSm),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomText(
                    category.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: AppSizes.fontBody,
                      fontWeight: FontWeight.w700,
                      height: 1.2,
                    ),
                  ),
                  if (desc.isNotEmpty) ...[
                    SizedBox(height: AppSizes.spaceXs),
                    CustomText(
                      desc,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: AppSizes.fontCaption,
                        height: 1.25,
                        color: scheme.onSurface.withValues(alpha: 0.65),
                      ),
                    ),
                  ],
                ],
              ),
            ),

          ],
        ),
      ),
    );
  }
}
