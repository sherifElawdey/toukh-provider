import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:toukh_provider/domain/entities/provider_order.dart';
import 'package:toukh_provider/features/orders/cubit/provider_orders_cubit.dart';
import 'package:toukh_provider/features/orders/presentation/widgets/orders_tab_view.dart';
import 'package:toukh_provider/l10n/app_strings.dart';
import 'package:toukh_ui/toukh_ui.dart';

class OrdersScreen extends StatelessWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return DefaultTabController(
      length: 4,
      child: BlocBuilder<ProviderOrdersCubit, ProviderOrdersState>(
        builder: (context, state) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: AppSizes.screenPadding.copyWith(
                  top: AppSizes.spaceLg,
                  bottom: AppSizes.spaceSm,
                ),
                child: CustomText(
                  AppStrings.Orders.title.tr,
                  style: TextStyle(
                    fontSize: AppSizes.fontHeadline,
                    fontWeight: FontWeight.w800,
                    color: scheme.onSurface,
                  ),
                ),
              ),
              if (state.errorMessage != null)
                Padding(
                  padding: AppSizes.screenHorizontal,
                  child: CustomText(
                    state.errorMessage!,
                    style: TextStyle(color: scheme.error, fontSize: 13),
                  ),
                ),
              const _OrdersStatusTabBar(),
              const _InProgressFilters(),
              Expanded(
                child: TabBarView(
                  children: [
                    OrdersTabView(
                      tab: ProviderOrdersTab.incoming,
                      emptyMessageKey: AppStrings.Orders.emptyIncoming,
                      emptyIcon: Icons.inbox_outlined,
                    ),
                    OrdersTabView(
                      tab: ProviderOrdersTab.inProgress,
                      emptyMessageKey: AppStrings.Orders.emptyInProgress,
                      emptyIcon: Icons.receipt_long_outlined,
                    ),
                    OrdersTabView(
                      tab: ProviderOrdersTab.outgoing,
                      emptyMessageKey: AppStrings.Orders.emptyOutgoing,
                      emptyIcon: Icons.local_shipping_outlined,
                    ),
                    OrdersTabView(
                      tab: ProviderOrdersTab.delivered,
                      emptyMessageKey: AppStrings.Orders.emptyDelivered,
                      emptyIcon: Icons.check_circle_outline,
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _OrdersStatusTabBar extends StatelessWidget {
  const _OrdersStatusTabBar();

  static final _labels = [
    AppStrings.Orders.tabIncoming,
    AppStrings.Orders.tabInProgress,
    AppStrings.Orders.tabOutgoing,
    AppStrings.Orders.tabDelivered,
  ];

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final controller = DefaultTabController.of(context);

    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final selected = controller.index;
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: AppSizes.screenHorizontal.copyWith(
            top: AppSizes.spaceXs,
            bottom: AppSizes.spaceSm,
          ),
          child: Row(
            children: [
              for (var i = 0; i < _labels.length; i++) ...[
                if (i > 0) const SizedBox(width: AppSizes.spaceSm),
                _OrdersStatusTabPill(
                  label: _labels[i].tr,
                  selected: selected == i,
                  onTap: () => controller.animateTo(i),
                  scheme: scheme,
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _OrdersStatusTabPill extends StatelessWidget {
  const _OrdersStatusTabPill({
    required this.label,
    required this.selected,
    required this.onTap,
    required this.scheme,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSizes.radiusFull),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.spaceLg,
            vertical: AppSizes.spaceSm + 2,
          ),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.appColor
                : scheme.surfaceContainerHighest.withValues(alpha: 0.45),
            borderRadius: BorderRadius.circular(AppSizes.radiusFull),
            border: Border.all(
              color: selected
                  ? AppColors.appColor
                  : scheme.outline.withValues(alpha: 0.28),
              width: selected ? 1.5 : 1,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: AppColors.appColor.withValues(alpha: 0.22),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : null,
          ),
          child: CustomText(
            label,
            style: TextStyle(
              fontSize: AppSizes.fontLabel,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
              color: selected
                  ? AppColors.surface
                  : scheme.onSurface.withValues(alpha: 0.72),
            ),
          ),
        ),
      ),
    );
  }
}

class _InProgressFilters extends StatelessWidget {
  const _InProgressFilters();

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: DefaultTabController.of(context),
      builder: (context, _) {
        final index = DefaultTabController.of(context).index;
        if (index != 1) return const SizedBox.shrink();

        return BlocBuilder<ProviderOrdersCubit, ProviderOrdersState>(
          buildWhen: (a, b) =>
              a.sort != b.sort ||
              a.withCourierOnly != b.withCourierOnly ||
              a.orders != b.orders,
          builder: (context, state) {
            final cubit = context.read<ProviderOrdersCubit>();
            final showCourier =
                state.showWithCourierFilter(ProviderOrdersTab.inProgress);

            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: AppSizes.screenHorizontal.copyWith(
                top: AppSizes.spaceSm,
                bottom: AppSizes.spaceSm,
              ),
              child: Row(
                children: [
                  _FilterChip(
                    label: AppStrings.Orders.filterNewest.tr,
                    selected: state.sort == ProviderOrdersSort.newest,
                    onTap: () => cubit.setSort(ProviderOrdersSort.newest),
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: AppStrings.Orders.filterOldest.tr,
                    selected: state.sort == ProviderOrdersSort.oldest,
                    onTap: () => cubit.setSort(ProviderOrdersSort.oldest),
                  ),
                  if (showCourier) ...[
                    const SizedBox(width: 8),
                    _FilterChip(
                      label: AppStrings.Orders.filterWithCourier.tr,
                      selected: state.withCourierOnly,
                      onTap: () =>
                          cubit.setWithCourierOnly(!state.withCourierOnly),
                    ),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return FilterChip(
      label: CustomText(label),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: AppColors.appColor.withValues(alpha: 0.18),
      checkmarkColor: AppColors.appColor,
      labelStyle: TextStyle(
        color: selected ? AppColors.appColor : scheme.onSurface,
        fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
      ),
    );
  }
}
