import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:toukh_provider/domain/entities/provider_dashboard_order.dart';
import 'package:toukh_provider/domain/entities/provider_master_order_extensions.dart';
import 'package:toukh_provider/features/auth/cubit/auth_cubit.dart';
import 'package:toukh_provider/domain/entities/provider_kind.dart';
import 'package:toukh_provider/features/home_service_requests/cubit/provider_home_service_requests_cubit.dart';
import 'package:toukh_provider/features/home/cubit/home_dashboard_cubit.dart';
import 'package:toukh_provider/features/home/cubit/home_dashboard_state.dart';
import 'package:toukh_provider/features/home/presentation/widgets/home_dashboard_sections.dart';
import 'package:toukh_provider/features/orders/cubit/provider_orders_cubit.dart';
import 'package:toukh_provider/l10n/app_strings.dart';
import 'package:toukh_ui/toukh_ui.dart';

class HomeDashboardOverviewTab extends StatelessWidget {
  const HomeDashboardOverviewTab({
    super.key,
    required this.state,
    required this.greeting,
  });

  final HomeDashboardState state;
  final String greeting;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return RefreshIndicator(
      color: AppColors.appColor,
      onRefresh: () async {
        context.read<HomeDashboardCubit>().retry();
        await Future<void>.delayed(const Duration(milliseconds: 450));
      },
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: AppSizes.screenPadding.copyWith(
              top: AppSizes.spaceLg,
              bottom: AppSizes.space2xl,
            ),
            sliver: SliverList(
              delegate: SliverChildListDelegate(
                [
                  CustomText(
                    '$greeting, ${state.providerDisplayName}',
                    style: TextStyle(
                      fontSize: AppSizes.fontHeadline,
                      fontWeight: FontWeight.w900,
                      color: scheme.onSurface,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 8),
                  CustomText(
                    AppStrings.Home.dashboardSubtitle.tr,
                    style: TextStyle(
                      fontSize: AppSizes.fontBody,
                      color: scheme.onSurface.withValues(alpha: 0.72),
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: AppSizes.spaceXl),
                  BlocBuilder<AuthCubit, AuthState>(
                    builder: (context, auth) {
                      if (auth is Authenticated &&
                          auth.profile.serviceType == ServiceType.homeService) {
                        return BlocBuilder<ProviderHomeServiceRequestsCubit,
                            ProviderHomeServiceRequestsState>(
                          builder: (context, hsState) {
                            return HomeDashboardPendingOrdersBanner(
                              pendingCount: hsState.pendingIncomingCount,
                              titleKey: AppStrings
                                  .HomeServiceRequests.dashboardPendingTitle,
                              subtitleKey: AppStrings
                                  .HomeServiceRequests.dashboardPendingSubtitle,
                            );
                          },
                        );
                      }
                      return BlocBuilder<ProviderOrdersCubit,
                          ProviderOrdersState>(
                        builder: (context, ordersState) {
                          final uid = ordersState.providerUid;
                          final pendingCount = uid == null
                              ? 0
                              : ordersState.orders
                                  .where(
                                    (m) =>
                                        m.hasProviderSlice(uid) &&
                                        (m.sliceFor(uid)?.isIncoming ?? false),
                                  )
                                  .length;
                          return HomeDashboardPendingOrdersBanner(
                            pendingCount: pendingCount,
                          );
                        },
                      );
                    },
                  ),
                  BlocBuilder<AuthCubit, AuthState>(
                    builder: (context, auth) {
                      if (auth is Authenticated &&
                          auth.profile.serviceType == ServiceType.homeService) {
                        return const SizedBox.shrink();
                      }
                      return BlocBuilder<ProviderOrdersCubit,
                          ProviderOrdersState>(
                        builder: (context, ordersState) {
                          final uid = ordersState.providerUid;
                          final inProgress = uid == null
                              ? <ProviderOrderDashboard>[]
                              : ProviderMasterOrderTabFilters.homeInProgress(
                                  ordersState.orders,
                                  uid,
                                )
                                  .map((r) => r.toDashboard())
                                  .toList();
                          return Column(
                            children: [
                              if (uid != null &&
                                  ordersState.orders.any(
                                    (m) =>
                                        m.hasProviderSlice(uid) &&
                                        (m.sliceFor(uid)?.isIncoming ?? false),
                                  ))
                                const SizedBox(height: AppSizes.spaceXl),
                              HomeDashboardInProgressStrip(orders: inProgress),
                            ],
                          );
                        },
                      );
                    },
                  ),
                  const SizedBox(height: AppSizes.spaceXl),
                  HomeDashboardWalletCard(
                    balanceEgp: state.walletBalanceEgp,
                    pendingEgp: state.walletPendingEgp,
                  ),
                  const SizedBox(height: AppSizes.spaceXl),
                  HomeDashboardStatsRow(metrics: state.todayMetrics),
                  const SizedBox(height: AppSizes.spaceXl),
                  HomeDashboardChartSection(
                    period: state.chartPeriod,
                    buckets: state.chartBuckets,
                    onPeriodChanged: (p) =>
                        context.read<HomeDashboardCubit>().setChartPeriod(p),
                  ),
                  if (state.showMenuInsights) ...[
                    const SizedBox(height: AppSizes.spaceXl),
                    HomeDashboardBestsellersSection(rows: state.bestsellers),
                  ],
                  const SizedBox(height: AppSizes.spaceXl),
                  HomeDashboardReviewsSection(reviews: state.visibleReviews),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
