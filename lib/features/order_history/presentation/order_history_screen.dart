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

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
  }

  void _onScroll() {
    if (!_scroll.hasClients) return;
    final max = _scroll.position.maxScrollExtent;
    if (max <= 0) return;
    if (_scroll.offset >= max - 200) {
      context.read<OrderHistoryCubit>().loadMore();
    }
  }

  @override
  void dispose() {
    _scroll.removeListener(_onScroll);
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

          if (state.error != null && state.items.isEmpty) {
            return Center(
              child: Padding(
                padding: AppSizes.screenPadding,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CustomText(
                      AppStrings.OrderHistory.loadError.tr,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSizes.spaceMd),
                    AppFilledButton(
                      text: AppStrings.Common.retry.tr,
                      onTap: () =>
                          context.read<OrderHistoryCubit>().loadInitial(),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.builder(
            controller: _scroll,
            padding: AppSizes.screenPadding.copyWith(
              top: AppSizes.spaceMd,
              bottom: AppSizes.space2xl,
            ),
            itemCount: state.items.isEmpty
                ? 3
                : state.items.length + 2 + (state.loadingMore ? 1 : 0),
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

              if (state.items.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.only(top: AppSizes.spaceXl),
                  child: Center(
                    child: CustomText(
                      AppStrings.OrderHistory.empty.tr,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: AppColors.onSurface.withValues(alpha: 0.55),
                          ),
                    ),
                  ),
                );
              }

              final listIndex = index - 2;
              if (listIndex >= state.items.length) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: AppSizes.spaceLg),
                  child: Center(
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                );
              }

              return OrderHistoryListTile(row: state.items[listIndex]);
            },
          );
        },
      ),
    );
  }
}
