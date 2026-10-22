import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:toukh_provider/core/router/app_routes.dart';
import 'package:toukh_provider/domain/entities/company_courier_stats.dart';
import 'package:toukh_provider/features/delivery_company/cubit/company_orders_cubit.dart';
import 'package:toukh_provider/features/delivery_company/presentation/widgets/company_widgets.dart';
import 'package:toukh_provider/l10n/app_strings.dart';
import 'package:toukh_ui/toukh_ui.dart';

/// Orders tab of a delivery company: every job of its couriers with status.
class CompanyOrdersScreen extends StatelessWidget {
  const CompanyOrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CompanyOrdersCubit, CompanyOrdersState>(
      builder: (context, state) {
        final cubit = context.read<CompanyOrdersCubit>();
        final orders = state.visible;
        return ToukhRefresh(
          onRefresh: cubit.load,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverPadding(
                padding: AppSizes.screenPadding.copyWith(
                  top: AppSizes.spaceLg,
                  bottom: AppSizes.spaceSm,
                ),
                sliver: SliverList.list(
                  children: [
                    SegmentedButton<int>(
                      showSelectedIcon: false,
                      segments: [
                        ButtonSegment(
                          value: 1,
                          label: Text(AppStrings.Company.today.tr),
                        ),
                        ButtonSegment(
                          value: 7,
                          label: Text(AppStrings.Company.last7Days.tr),
                        ),
                        ButtonSegment(
                          value: 30,
                          label: Text(AppStrings.Company.last30Days.tr),
                        ),
                      ],
                      selected: {state.days},
                      onSelectionChanged: (v) => cubit.setDays(v.first),
                    ),
                    const SizedBox(height: AppSizes.spaceMd),
                    TextField(
                      onChanged: cubit.setQuery,
                      decoration: InputDecoration(
                        hintText: AppStrings.Company.ordersSearchHint.tr,
                        prefixIcon: Icon(ToukhIcons.search),
                        isDense: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            AppSizes.radiusMd,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSizes.spaceMd),
                    SizedBox(
                      height: 40,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          for (final f in CompanyOrdersFilter.values)
                            Padding(
                              padding: const EdgeInsetsDirectional.only(
                                end: AppSizes.spaceSm,
                              ),
                              child: ChoiceChip(
                                label: Text(
                                  '${_filterLabel(f)} (${state.count(f)})',
                                ),
                                selected: state.filter == f,
                                onSelected: (_) => cubit.setFilter(f),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (state.loading && state.orders.isEmpty)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(child: AppLoadingMark()),
                )
              else if (state.failed && state.orders.isEmpty)
                SliverPadding(
                  padding: AppSizes.screenPadding,
                  sliver: SliverToBoxAdapter(
                    child: CompanyEmptyNote(
                      AppStrings.Company.ordersLoadFailed,
                      icon: ToukhIcons.warning,
                    ),
                  ),
                )
              else if (orders.isEmpty)
                SliverPadding(
                  padding: AppSizes.screenPadding,
                  sliver: SliverToBoxAdapter(
                    child: CompanyEmptyNote(
                      AppStrings.Company.noOrders,
                      icon: ToukhIcons.orders,
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: AppSizes.screenPadding.copyWith(
                    bottom: AppSizes.space3xl,
                  ),
                  sliver: SliverList.separated(
                    itemCount: orders.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: AppSizes.spaceSm),
                    itemBuilder: (context, i) =>
                        CompanyOrderTile(order: orders[i]),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  static String _filterLabel(CompanyOrdersFilter f) => switch (f) {
    CompanyOrdersFilter.all => AppStrings.Company.filterAll.tr,
    CompanyOrdersFilter.active => AppStrings.Company.filterLive.tr,
    CompanyOrdersFilter.delivered => AppStrings.Company.filterDelivered.tr,
    CompanyOrdersFilter.cancelled => AppStrings.Company.filterCancelled.tr,
  };
}

class CompanyOrderTile extends StatelessWidget {
  const CompanyOrderTile({super.key, required this.order});

  final CompanyOrder order;

  Color _statusColor(BuildContext context) {
    if (order.active) return AppColors.secondColor;
    if (order.cancelled) return Theme.of(context).colorScheme.error;
    return AppColors.success;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final muted = scheme.onSurface.withValues(alpha: 0.65);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final at = order.at;
    final now = DateTime.now();
    final time = at == null
        ? null
        : (at.year == now.year && at.month == now.month && at.day == now.day
                  ? DateFormat.jm(locale)
                  : DateFormat.MMMd(locale).add_jm())
              .format(at);
    final color = _statusColor(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        onTap: order.courierId == null
            ? null
            : () =>
                  context.push(AppRoutes.companyCourierPath(order.courierId!)),
        child: Container(
          padding: const EdgeInsets.all(AppSizes.spaceMd),
          decoration: ToukhCard.decoration(context),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ToukhIconWell(
                icon: order.isRide
                    ? PhosphorIconsRegular.car
                    : ToukhIcons.delivery,
                color: color,
                size: 36,
                iconSize: 18,
              ),
              const SizedBox(width: AppSizes.spaceMd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: CustomText(
                            order.courierName ??
                                (order.isRide
                                    ? AppStrings.Company.jobRide.tr
                                    : AppStrings.Company.jobDelivery.tr),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                        CompanyChip(
                          label: companyJobStatusLabel(order.status),
                          color: color,
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSizes.spaceXs),
                    CompanyJobLine(
                      icon: ToukhIcons.store,
                      text: order.pickupLabel ?? '—',
                      color: muted,
                    ),
                    CompanyJobLine(
                      icon: ToukhIcons.location,
                      text: order.dropoffLabel ?? '—',
                      color: muted,
                    ),
                    const SizedBox(height: AppSizes.spaceXs),
                    CustomText(
                      [
                        order.isRide
                            ? AppStrings.Company.jobRide.tr
                            : AppStrings.Company.jobDelivery.tr,
                        if (order.feeEgp > 0) companyEgp(order.feeEgp),
                        if (order.distanceMeters > 0)
                          companyKm(order.distanceMeters),
                        ?time,
                      ].join(' · '),
                      style: TextStyle(fontSize: 12, color: muted),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
