import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:toukh_provider/features/home/presentation/widgets/home_dashboard_empty_placeholder.dart';
import 'package:toukh_provider/features/reviews/cubit/provider_reviews_cubit.dart';
import 'package:toukh_provider/features/reviews/presentation/widgets/provider_review_tile.dart';
import 'package:toukh_provider/l10n/app_strings.dart';
import 'package:toukh_ui/toukh_ui.dart';

class ProviderReviewsScreen extends StatelessWidget {
  const ProviderReviewsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: CustomText(AppStrings.Settings.reviews.tr),
        leading: IconButton(
          icon: Icon(ToukhIcons.back),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: BlocBuilder<ProviderReviewsCubit, ProviderReviewsState>(
        builder: (context, state) {
          if (state.loading && state.reviews.isEmpty) {
            return const Center(child: AppLoadingMark());
          }
          if (state.error != null && state.reviews.isEmpty) {
            return Center(
              child: Padding(
                padding: AppSizes.screenPadding,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CustomText(state.error!),
                    const SizedBox(height: AppSizes.spaceMd),
                    AppFilledButton(
                      text: AppStrings.Common.retry.tr,
                      onTap: () =>
                          context.read<ProviderReviewsCubit>().retry(),
                    ),
                  ],
                ),
              ),
            );
          }
          if (state.reviews.isEmpty) {
            return ListView(
              padding: AppSizes.screenPadding,
              children: [
                HomeDashboardEmptyPlaceholder(
                  message: AppStrings.Home.dashboardReviewsEmpty,
                ),
              ],
            );
          }

          return ListView.separated(
            padding: AppSizes.screenPadding,
            itemCount: state.reviews.length + 1,
            separatorBuilder: (_, i) => SizedBox(
              height: i == 0 ? AppSizes.spaceMd : 10,
            ),
            itemBuilder: (context, i) {
              if (i == 0) {
                return _ReviewsSummaryHeader(
                  averageRating: state.averageRating,
                  reviewCount: state.reviewCount,
                );
              }
              final review = state.reviews[i - 1];
              return ProviderReviewTile(review: review);
            },
          );
        },
      ),
    );
  }
}

class _ReviewsSummaryHeader extends StatelessWidget {
  const _ReviewsSummaryHeader({
    required this.averageRating,
    required this.reviewCount,
  });

  final double averageRating;
  final int reviewCount;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final rounded = averageRating.toStringAsFixed(1);

    return Container(
      padding: const EdgeInsets.all(AppSizes.spaceLg),
      decoration: BoxDecoration(
        color: AppColors.thirdColor.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomText(
                AppStrings.Settings.reviewsAverage.tr,
                style: TextStyle(
                  fontSize: 13,
                  color: scheme.onSurface.withValues(alpha: 0.6),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  CustomText(
                    rounded,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: scheme.onSurface,
                    ),
                  ),
                  const SizedBox(width: AppSizes.spaceSm),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(
                      5,
                      (i) => Icon(
                        i < averageRating.round()
                            ? ToukhIcons.starFilled
                            : ToukhIcons.star,
                        size: 18,
                        color: AppColors.appColor.withValues(
                          alpha: i < averageRating.round() ? 1 : 0.28,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const Spacer(),
          CustomText(
            AppStrings.Settings.reviewsCount.trParams({'count': '$reviewCount'}),
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: scheme.onSurface.withValues(alpha: 0.65),
            ),
          ),
        ],
      ),
    );
  }
}
