import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:toukh_provider/core/router/app_routes.dart';
import 'package:toukh_provider/domain/entities/delivery_company.dart';
import 'package:toukh_provider/features/delivery_company/cubit/company_fleet_cubit.dart';
import 'package:toukh_provider/features/delivery_company/presentation/widgets/company_widgets.dart';
import 'package:toukh_provider/l10n/app_strings.dart';
import 'package:toukh_ui/toukh_ui.dart';

/// Home tab of a delivery company: ID, today's fleet numbers, live jobs and
/// who is doing the most work today.
class CompanyHomeScreen extends StatelessWidget {
  const CompanyHomeScreen({super.key, required this.company});

  final DeliveryCompany company;

  static const _previewJobs = 5;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CompanyFleetCubit, CompanyFleetState>(
      builder: (context, state) {
        if (state.loading) return const Center(child: AppLoadingMark());
        final members = state.members;
        final online = members.where((c) => c.isAvailable).length;
        final busy = members.where((c) => c.isBusy).length;
        final totals = state.overview.totals;
        final statsValue = state.overviewFailed && totals.orders == 0
            ? (String _) => '—'
            : (String v) => v;
        final jobs = state.overview.activeJobs;
        final ranked = [...members]
          ..sort((a, b) {
            final ta = state.overview.todayByCourier[a.uid]?.orders ?? 0;
            final tb = state.overview.todayByCourier[b.uid]?.orders ?? 0;
            return tb.compareTo(ta);
          });

        return ToukhRefresh(
          onRefresh: () => context.read<CompanyFleetCubit>().refresh(),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: AppSizes.screenPadding.copyWith(
              top: AppSizes.spaceLg,
              bottom: AppSizes.space3xl,
            ),
            children: [
              CustomText(
                company.companyName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: AppSizes.fontTitle,
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (company.serviceAreaName != null)
                CustomText(
                  company.serviceAreaName!,
                  style: TextStyle(
                    fontSize: AppSizes.fontCaption,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.65),
                  ),
                ),
              const SizedBox(height: AppSizes.spaceMd),
              if (state.requests.isNotEmpty) ...[
                _RequestsBanner(count: state.requests.length),
                const SizedBox(height: AppSizes.spaceMd),
              ],
              CompanyStatGrid(
                children: [
                  CompanyStatTile(
                    icon: ToukhIcons.group,
                    label: AppStrings.Company.statCouriers.tr,
                    value: '${members.length}',
                  ),
                  CompanyStatTile(
                    icon: ToukhIcons.onlineFilled,
                    color: AppColors.success,
                    label: AppStrings.Company.statOnline.tr,
                    value: '$online',
                  ),
                  CompanyStatTile(
                    icon: ToukhIcons.delivery,
                    label: AppStrings.Company.statBusy.tr,
                    value: '$busy',
                  ),
                  CompanyStatTile(
                    icon: ToukhIcons.orders,
                    label: AppStrings.Company.statOrdersToday.tr,
                    value: statsValue('${totals.orders}'),
                  ),
                  CompanyStatTile(
                    icon: ToukhIcons.wallet,
                    color: AppColors.success,
                    label: AppStrings.Company.statEarningsToday.tr,
                    value: statsValue(companyEgp(totals.earningsEgp)),
                  ),
                  CompanyStatTile(
                    icon: ToukhIcons.navigation,
                    label: AppStrings.Company.statDistanceToday.tr,
                    value: statsValue(companyKm(totals.distanceMeters)),
                  ),
                ],
              ),
              if (state.overviewFailed) ...[
                const SizedBox(height: AppSizes.spaceSm),
                CustomText(
                  AppStrings.Company.statsUnavailable,
                  style: TextStyle(
                    fontSize: AppSizes.fontCaption,
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
              ],
              const SizedBox(height: AppSizes.spaceXl),
              CompanySectionTitle(
                AppStrings.Company.activeOrders,
                trailing: state.overviewLoading
                    ? const SizedBox.square(
                        dimension: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : AppTextButton(
                        text: AppStrings.Company.seeAll,
                        onTap: () => context.go(AppRoutes.orders),
                      ),
              ),
              const SizedBox(height: AppSizes.spaceSm),
              if (jobs.isEmpty)
                CompanyEmptyNote(
                  AppStrings.Company.noActiveOrders,
                  icon: ToukhIcons.delivery,
                )
              else
                for (final job in jobs.take(_previewJobs))
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSizes.spaceSm),
                    child: CourierActiveJobTile(
                      job: job,
                      onTap: job.courierId == null
                          ? null
                          : () => context.push(
                              AppRoutes.companyCourierPath(job.courierId!),
                            ),
                    ),
                  ),
              const SizedBox(height: AppSizes.spaceXl),
              CompanySectionTitle(
                AppStrings.Company.todayByCourier,
                trailing: AppTextButton(
                  text: AppStrings.Company.seeAll,
                  onTap: () => context.go(AppRoutes.menu),
                ),
              ),
              const SizedBox(height: AppSizes.spaceSm),
              if (members.isEmpty)
                CompanyEmptyNote(
                  AppStrings.Company.noCouriers,
                  icon: ToukhIcons.group,
                )
              else
                for (final c in ranked.take(_previewJobs))
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSizes.spaceSm),
                    child: CompanyCourierTile(
                      courier: c,
                      ordersToday: state.overview.todayByCourier[c.uid]?.orders,
                    ),
                  ),
              const SizedBox(height: AppSizes.spaceXl),
              CompanyIdCard(company: company),
            ],
          ),
        );
      },
    );
  }
}

class _RequestsBanner extends StatelessWidget {
  const _RequestsBanner({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.warning.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(AppSizes.radiusLg),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        onTap: () => context.go(AppRoutes.companyCouriersRequests),
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.spaceMd),
          child: Row(
            children: [
              Icon(ToukhIcons.group, color: AppColors.warning),
              const SizedBox(width: AppSizes.spaceSm),
              Expanded(
                child: CustomText(
                  AppStrings.Company.pendingRequestsBanner.trParams({
                    'count': '$count',
                  }),
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              CustomText(
                AppStrings.Company.review,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppColors.warning,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
