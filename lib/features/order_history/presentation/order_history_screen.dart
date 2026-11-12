import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:toukh_provider/features/order_history/cubit/order_history_cubit.dart';
import 'package:toukh_provider/features/order_history/presentation/widgets/order_history_date_filter_bar.dart';
import 'package:toukh_provider/features/order_history/presentation/widgets/order_history_list_tile.dart';
import 'package:toukh_provider/features/order_history/presentation/widgets/order_history_stats_header.dart';
import 'package:toukh_provider/l10n/app_strings.dart';
import 'package:toukh_ui/toukh_ui.dart';

class OrderHistoryScreen extends StatefulWidget {
  const OrderHistoryScreen({super.key});

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
  final _scroll = ScrollController();

  /// Numbered pages on web, load-more at the last row on mobile; rows come
  /// from the cubit's Firestore cursor either way.
  late final _pager = ToukhWindowPager<ProviderMasterOrderRow>(
    onLoadMore: () => context.read<OrderHistoryCubit>().loadMore(),
  )..addListener(_onPager);
  int _page = 0;

  void _onPager() {
    if (!mounted) return;
    if (_pager.page != _page) {
      _page = _pager.page;
      if (_scroll.hasClients) _scroll.jumpTo(0);
    }
    setState(() {});
  }

  @override
  void dispose() {
    _pager.dispose();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: CustomText(AppStrings.OrderHistory.title.tr),
        leading: IconButton(
          icon: Icon(ToukhIcons.back),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: BlocBuilder<OrderHistoryCubit, OrderHistoryState>(
        builder: (context, state) {
          if (state.loading && state.items.isEmpty) {
            return const Center(child: AppLoadingMark());
          }

          final onRefresh = context.read<OrderHistoryCubit>().loadInitial;

          if (state.error != null && state.items.isEmpty) {
            return ToukhRefresh(
              onRefresh: onRefresh,
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
                          CustomText(
                            AppStrings.OrderHistory.loadError.tr,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: AppSizes.spaceMd),
                          AppFilledButton(
                            text: AppStrings.Common.retry.tr,
                            onTap: onRefresh,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          _pager.sync(
            state.items,
            hasMore: state.hasMore,
            loading: state.loading,
            loadingMore: state.loadingMore,
            notify: false,
          );
          final rows = _pager.items;
          final content = ListView.builder(
            controller: _scroll,
            physics: const AlwaysScrollableScrollPhysics(),
            padding: AppSizes.screenPadding.copyWith(
              top: AppSizes.spaceMd,
              bottom: AppSizes.space2xl,
            ),
            itemCount: rows.isEmpty ? 3 : rows.length + 3,
            itemBuilder: (context, index) {
              if (index == 0) {
                return OrderHistoryStatsHeader(
                  stats: state.stats,
                  loading: state.statsLoading,
                );
              }
              if (index == 1) {
                return const Padding(
                  padding: EdgeInsets.only(
                    top: AppSizes.spaceLg,
                    bottom: AppSizes.spaceMd,
                  ),
                  child: OrderHistoryDateFilterBar(),
                );
              }

              if (rows.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.only(top: AppSizes.spaceXl),
                  child: Center(
                    child: CustomText(
                      AppStrings.OrderHistory.empty.tr,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.55),
                          ),
                    ),
                  ),
                );
              }

              final listIndex = index - 2;
              if (listIndex >= rows.length) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSizes.spaceLg),
                  child: ToukhPagedFooter(paging: _pager, padding: EdgeInsets.zero),
                );
              }

              _pager.onItemBuilt(listIndex);
              return OrderHistoryListTile(row: rows[listIndex]);
            },
          );
          return ToukhRefresh(onRefresh: onRefresh, child: content);
        },
      ),
    );
  }
}
