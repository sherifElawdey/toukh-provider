import 'package:flutter/material.dart';
import 'package:toukh_ui/toukh_ui.dart';

/// Placeholder order cards shown while Orders subscribe / refresh.
class OrdersListShimmer extends StatelessWidget {
  const OrdersListShimmer({super.key, this.itemCount = 5});

  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return ToukhShimmer(
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: AppSizes.screenPadding,
        itemCount: itemCount,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.secondColor.withValues(alpha: 0.06),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: ToukhShimmerBox(height: 18),
                      ),
                      const SizedBox(width: 12),
                      ToukhShimmerBox(
                        height: 24,
                        width: 72,
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const ToukhShimmerBox(height: 14, width: 140),
                  const SizedBox(height: 8),
                  const ToukhShimmerBox(height: 12, width: 100),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ToukhShimmerBox(
                          height: 45,
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ToukhShimmerBox(
                          height: 45,
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
