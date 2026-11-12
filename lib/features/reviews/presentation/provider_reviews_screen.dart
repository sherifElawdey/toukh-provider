import 'package:flutter/material.dart';
import 'package:toukh_provider/domain/entities/provider_review_summary.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:toukh_provider/features/home/presentation/widgets/home_dashboard_empty_placeholder.dart';
import 'package:toukh_provider/features/reviews/cubit/provider_reviews_cubit.dart';
import 'package:toukh_provider/features/reviews/presentation/widgets/provider_review_tile.dart';
import 'package:toukh_provider/l10n/app_strings.dart';
import 'package:toukh_ui/toukh_ui.dart';

class ProviderReviewsScreen extends StatelessWidget {
  const ProviderReviewsScreen({super.key});

  Future<void> _refresh(BuildContext context) async {
    context.read<ProviderReviewsCubit>().retry();
    await Future<void>.delayed(const Duration(milliseconds: 450));
  }

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
            return ToukhRefresh(
              onRefresh: () => _refresh(context),
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Padding(
                      padding: AppSizes.screenPadding,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
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
                  ),
                ],
              ),
            );
          }
          if (state.reviews.isEmpty) {
            return ToukhRefresh(
              onRefresh: () => _refresh(context),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: AppSizes.screenPadding,
                children: [
                  HomeDashboardEmptyPlaceholder(
                    message: AppStrings.Home.dashboardReviewsEmpty,
                  ),
                ],
              ),
            );
          }

          return _ReviewsList(
            state: state,
            onRefresh: () => _refresh(context),
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
                      fontWeight: FontWeight.w800,
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

/// Reviews with numbered pages (web) / load-more at the last row (mobile)
/// over the cubit's live window.
class _ReviewsList extends StatefulWidget {
  const _ReviewsList({required this.state, required this.onRefresh});

  final ProviderReviewsState state;
  final Future<void> Function() onRefresh;

  @override
  State<_ReviewsList> createState() => _ReviewsListState();
}

class _ReviewsListState extends State<_ReviewsList> {
  late final _pager = ToukhWindowPager<ProviderReviewSummary>(
    onLoadMore: () => context.read<ProviderReviewsCubit>().loadMore(),
  )..addListener(_onPager);

  void _onPager() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _pager.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    _pager.sync(
      state.reviews,
      hasMore: state.hasMore,
      loading: state.loading,
      loadingMore: state.loadingMore,
      notify: false,
    );
    final rows = _pager.items;
    return ToukhRefresh(
      onRefresh: widget.onRefresh,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: AppSizes.screenPadding,
        itemCount: rows.length + 2,
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
          if (i > rows.length) return ToukhPagedFooter(paging: _pager);
          _pager.onItemBuilt(i - 1);
          return ProviderReviewTile(review: rows[i - 1]);
        },
      ),
    );
  }
}
