import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:toukh_provider/domain/entities/provider_review_summary.dart';
import 'package:toukh_provider/features/home/presentation/widgets/home_dashboard_empty_placeholder.dart';
import 'package:toukh_provider/features/reviews/presentation/widgets/provider_review_tile.dart';
import 'package:toukh_provider/l10n/app_strings.dart';
import 'package:toukh_ui/toukh_ui.dart';

class HomeDashboardReviewsSection extends StatelessWidget {
  const HomeDashboardReviewsSection({super.key, required this.reviews});

  final List<ProviderReviewSummary> reviews;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CustomText(
          AppStrings.Home.dashboardReviewsTitle.tr,
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: AppSizes.fontTitle,
            color: scheme.onSurface,
          ),
        ),
        const SizedBox(height: AppSizes.spaceMd),
        if (reviews.isEmpty)
          HomeDashboardEmptyPlaceholder(
            message: AppStrings.Home.dashboardReviewsEmpty,
          )
        else
          ...reviews.map(
            (r) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: ProviderReviewTile(review: r),
            ),
          ),
      ],
    );
  }
}
