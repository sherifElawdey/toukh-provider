import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../theme/app_colors.dart';
import '../theme/app_sizes.dart';

/// Base shimmer wrapper with app-aligned highlight colors.
class ToukhShimmer extends StatelessWidget {
  const ToukhShimmer({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final base = AppColors.secondColor.withValues(alpha: 0.08);
    final highlight = AppColors.secondColor.withValues(alpha: 0.18);
    return Shimmer.fromColors(
      baseColor: base,
      highlightColor: highlight,
      child: child,
    );
  }
}

/// Rounded bone used inside [ToukhShimmer].
class ToukhShimmerBox extends StatelessWidget {
  const ToukhShimmerBox({
    super.key,
    this.width,
    this.height = 14,
    this.borderRadius,
  });

  final double? width;
  final double height;
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            borderRadius ?? BorderRadius.circular(AppSizes.radiusSm),
      ),
    );
  }
}

/// Vertical list of generic shimmer rows for fetch loading.
class ToukhShimmerList extends StatelessWidget {
  const ToukhShimmerList({
    super.key,
    this.itemCount = 6,
    this.itemHeight = 76,
    this.padding,
  });

  final int itemCount;
  final double itemHeight;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return ToukhShimmer(
      child: ListView.separated(
        padding: padding ?? AppSizes.screenPadding,
        itemCount: itemCount,
        separatorBuilder: (_, __) => SizedBox(height: AppSizes.spaceMd),
        itemBuilder: (_, __) => ToukhShimmerBox(
          height: itemHeight,
          borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        ),
      ),
    );
  }
}

/// Compact order/request row skeleton.
class ToukhShimmerOrderRow extends StatelessWidget {
  const ToukhShimmerOrderRow({super.key});

  @override
  Widget build(BuildContext context) {
    return ToukhShimmer(
      child: Row(
        children: [
          ToukhShimmerBox(
            width: 52,
            height: 52,
            borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          ),
          SizedBox(width: AppSizes.spaceMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ToukhShimmerBox(width: 140, height: 14),
                SizedBox(height: AppSizes.spaceSm),
                ToukhShimmerBox(width: 200, height: 12),
                SizedBox(height: AppSizes.spaceSm),
                ToukhShimmerBox(width: 80, height: 10),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Home category grid skeleton (3 columns).
class ToukhShimmerCategoryGrid extends StatelessWidget {
  const ToukhShimmerCategoryGrid({super.key, this.count = 9});

  final int count;

  @override
  Widget build(BuildContext context) {
    return ToukhShimmer(
      child: Wrap(
        spacing: AppSizes.spaceMd,
        runSpacing: AppSizes.spaceMd,
        children: List.generate(count, (_) {
          return SizedBox(
            width: (MediaQuery.sizeOf(context).width -
                    AppSizes.spaceLg * 2 -
                    AppSizes.spaceMd * 2) /
                3,
            height: 150,
            child: ToukhShimmerBox(
              height: 150,
              borderRadius: BorderRadius.circular(AppSizes.radiusLg),
            ),
          );
        }),
      ),
    );
  }
}
