import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:toukh_ui/toukh_ui.dart';

/// Placeholder order cards shown while Orders subscribe / refresh.
class OrdersListShimmer extends StatelessWidget {
  const OrdersListShimmer({super.key, this.itemCount = 5});

  final int itemCount;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final base = scheme.onSurface.withValues(alpha: 0.08);
    final highlight = scheme.onSurface.withValues(alpha: 0.03);

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: AppSizes.screenPadding,
      itemCount: itemCount,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Shimmer.fromColors(
            baseColor: base,
            highlightColor: highlight,
            child: const _OrderCardSkeleton(),
          ),
        );
      },
    );
  }
}

class _OrderCardSkeleton extends StatelessWidget {
  const _OrderCardSkeleton();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: scheme.onSurface.withValues(alpha: 0.06),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Expanded(
                child: _Bone(height: 18),
              ),
              const SizedBox(width: 12),
              const _Bone(height: 24, width: 72, radius: 12),
            ],
          ),
          const SizedBox(height: 12),
          const _Bone(height: 14, width: 140),
          const SizedBox(height: 8),
          const _Bone(height: 12, width: 100),
          const SizedBox(height: 16),
          const Row(
            children: [
              Expanded(child: _Bone(height: 45, radius: 12)),
              SizedBox(width: 10),
              Expanded(child: _Bone(height: 45, radius: 12)),
            ],
          ),
        ],
      ),
    );
  }
}

class _Bone extends StatelessWidget {
  const _Bone({
    required this.height,
    this.width,
    this.radius = 8,
  });

  final double height;
  final double? width;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}
