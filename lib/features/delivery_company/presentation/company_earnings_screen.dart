import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:toukh_provider/core/router/app_routes.dart';
import 'package:toukh_provider/domain/entities/company_courier_stats.dart';
import 'package:toukh_provider/features/delivery_company/cubit/company_earnings_cubit.dart';
import 'package:toukh_provider/features/delivery_company/presentation/widgets/company_stats_widgets.dart';
import 'package:toukh_provider/features/delivery_company/presentation/widgets/company_widgets.dart';
import 'package:toukh_provider/l10n/app_strings.dart';
import 'package:toukh_ui/toukh_ui.dart';

/// The company's "wallet": fleet earnings for reporting. Payouts are held in
/// each courier's own wallet, so there is no balance or top-up here.
class CompanyEarningsScreen extends StatelessWidget {
  const CompanyEarningsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(
      context,
    ).colorScheme.onSurface.withValues(alpha: 0.7);
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(ToukhIcons.back),
          onPressed: () => context.pop(),
        ),
        title: CustomText(AppStrings.Company.fleetEarnings),
      ),
      body: BlocBuilder<CompanyEarningsCubit, CompanyEarningsState>(
        builder: (context, state) {
          final e = state.earnings;
          return ToukhRefresh(
            onRefresh: context.read<CompanyEarningsCubit>().load,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: AppSizes.screenPadding.copyWith(
                top: AppSizes.spaceLg,
                bottom: AppSizes.space3xl,
              ),
              children: [
                CustomText(
                  AppStrings.Company.fleetEarningsHint,
                  style: TextStyle(
                    fontSize: AppSizes.fontCaption,
                    color: muted,
                  ),
                ),
                const SizedBox(height: AppSizes.spaceLg),
                if (e == null)
                  state.failed
                      ? CompanyEmptyNote(
                          AppStrings.Company.statsUnavailable,
                          icon: ToukhIcons.warning,
                        )
                      : const Padding(
                          padding: EdgeInsets.all(AppSizes.spaceXl),
                          child: Center(child: AppLoadingMark()),
                        )
                else ...[
                  _BalanceCard(month: e.month, today: e.today),
                  const SizedBox(height: AppSizes.spaceLg),
                  CompanyPeriodStats(
                    today: e.today,
                    week: e.week,
                    month: e.month,
                  ),
                  const SizedBox(height: AppSizes.spaceXl),
                  CompanySectionTitle(AppStrings.Company.dailyEarnings),
                  const SizedBox(height: AppSizes.spaceSm),
                  CompanyOrdersBarChart(
                    points: e.daily,
                    byEarnings: true,
                    label: (d, locale) => DateFormat.E(locale).format(d),
                  ),
                  const SizedBox(height: AppSizes.spaceXl),
                  CompanySectionTitle(AppStrings.Company.earningsByCourier),
                  const SizedBox(height: AppSizes.spaceSm),
                  if (e.couriers.isEmpty)
                    CompanyEmptyNote(
                      AppStrings.Company.noCouriers,
                      icon: ToukhIcons.group,
                    )
                  else
                    for (final c in e.couriers)
                      Padding(
                        padding: const EdgeInsets.only(
                          bottom: AppSizes.spaceSm,
                        ),
                        child: _CourierEarningsTile(item: c),
                      ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _BalanceCard extends StatelessWidget {
  const _BalanceCard({required this.month, required this.today});

  final CourierPeriodSummary month;
  final CourierPeriodSummary today;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.spaceLg),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomText(
            AppStrings.Company.thisMonth,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: AppSizes.spaceXs),
          CustomText(
            companyEgp(month.earningsEgp),
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: AppColors.success,
            ),
          ),
          const SizedBox(height: AppSizes.spaceXs),
          CustomText(
            '${AppStrings.Company.today.tr}: ${companyEgp(today.earningsEgp)}'
            ' · ${AppStrings.Company.orders.tr}: ${month.orders}',
            style: const TextStyle(fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class _CourierEarningsTile extends StatelessWidget {
  const _CourierEarningsTile({required this.item});

  final CompanyCourierEarnings item;

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(
      context,
    ).colorScheme.onSurface.withValues(alpha: 0.65);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        onTap: item.courierId.isEmpty
            ? null
            : () => context.push(AppRoutes.companyCourierPath(item.courierId)),
        child: Container(
          padding: const EdgeInsets.all(AppSizes.spaceMd),
          decoration: ToukhCard.decoration(context),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomText(
                      item.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    CustomText(
                      '${AppStrings.Company.orders.tr}: ${item.month.orders}'
                      ' · ${companyKm(item.month.distanceMeters)}'
                      ' · ${AppStrings.Company.today.tr}: '
                      '${companyEgp(item.today.earningsEgp)}',
                      style: TextStyle(fontSize: 12, color: muted),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSizes.spaceSm),
              CustomText(
                companyEgp(item.month.earningsEgp),
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  color: AppColors.success,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
