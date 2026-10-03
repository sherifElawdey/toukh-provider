import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:toukh_provider/domain/entities/provider_dashboard_order.dart';
import 'package:toukh_provider/features/shell/provider_web_layout.dart';
import 'package:toukh_provider/domain/entities/provider_master_order_extensions.dart';
import 'package:toukh_provider/features/auth/cubit/auth_cubit.dart';
import 'package:toukh_provider/domain/entities/provider_kind.dart';
import 'package:toukh_provider/features/home_service_requests/cubit/provider_home_service_requests_cubit.dart';
import 'package:toukh_provider/features/home/cubit/home_dashboard_cubit.dart';
import 'package:toukh_provider/features/home/cubit/home_dashboard_state.dart';
import 'package:toukh_provider/features/home/presentation/widgets/home_dashboard_sections.dart';
import 'package:toukh_provider/features/home/presentation/widgets/home_permissions_banner.dart';
import 'package:toukh_provider/di/service_locator.dart';
import 'package:toukh_provider/domain/repositories/app_settings_repository.dart';
import 'package:toukh_provider/domain/repositories/provider_wallet_repository.dart';
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
    return LayoutBuilder(
      builder: (context, constraints) {
        final useColumns =
            ProviderWebLayout.isWide(context) &&
            constraints.maxWidth >= ProviderWebLayout.dashboardColumnsMinWidth;
        return ToukhRefresh(
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
                    useColumns
                        ? _wideChildren(context)
                        : _stackedChildren(context),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  List<Widget> _stackedChildren(BuildContext context) {
    return [
      _greeting(context),
      const SizedBox(height: AppSizes.spaceLg),
      const HomePermissionsBanner(),
      const SizedBox(height: AppSizes.spaceMd),
      _pendingBanner(),
      _inProgressStrip(),
      const SizedBox(height: AppSizes.spaceXl),
      _revenueCard(),
      const SizedBox(height: AppSizes.spaceMd),
      _walletCard(),
      const SizedBox(height: AppSizes.spaceXl),
      HomeDashboardStatsRow(metrics: state.todayMetrics),
      const SizedBox(height: AppSizes.spaceXl),
      _chartSection(context),
      if (state.showMenuInsights) ...[
        const SizedBox(height: AppSizes.spaceXl),
        HomeDashboardBestsellersSection(rows: state.bestsellers),
      ],
      const SizedBox(height: AppSizes.spaceXl),
      HomeDashboardReviewsSection(reviews: state.visibleReviews),
    ];
  }

  List<Widget> _wideChildren(BuildContext context) {
    return [
      _greeting(context),
      const SizedBox(height: AppSizes.spaceLg),
      const HomePermissionsBanner(),
      const SizedBox(height: AppSizes.spaceXl),
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [_pendingBanner(), _inProgressStrip()],
            ),
          ),
          const SizedBox(width: AppSizes.spaceXl),
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _revenueCard(),
                const SizedBox(height: AppSizes.spaceMd),
                _walletCard(),
              ],
            ),
          ),
        ],
      ),
      const SizedBox(height: AppSizes.spaceXl),
      HomeDashboardStatsRow(metrics: state.todayMetrics),
      const SizedBox(height: AppSizes.spaceXl),
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: _chartSection(context)),
          if (state.showMenuInsights) ...[
            const SizedBox(width: AppSizes.spaceXl),
            Expanded(
              child: HomeDashboardBestsellersSection(rows: state.bestsellers),
            ),
          ],
          const SizedBox(width: AppSizes.spaceXl),
          Expanded(
            child: HomeDashboardReviewsSection(reviews: state.visibleReviews),
          ),
        ],
      ),
    ];
  }

  Widget _greeting(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
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
      ],
    );
  }

  Widget _pendingBanner() {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, auth) {
        if (auth is Authenticated &&
            auth.profile.serviceType == ServiceType.homeService) {
          return BlocBuilder<
            ProviderHomeServiceRequestsCubit,
            ProviderHomeServiceRequestsState
          >(
            builder: (context, hsState) {
              return HomeDashboardPendingOrdersBanner(
                pendingCount: hsState.pendingIncomingCount,
                titleKey: AppStrings.HomeServiceRequests.dashboardPendingTitle,
                subtitleKey:
                    AppStrings.HomeServiceRequests.dashboardPendingSubtitle,
              );
            },
          );
        }
        return BlocBuilder<ProviderOrdersCubit, ProviderOrdersState>(
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
            return HomeDashboardPendingOrdersBanner(pendingCount: pendingCount);
          },
        );
      },
    );
  }

  Widget _inProgressStrip() {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, auth) {
        if (auth is Authenticated &&
            auth.profile.serviceType == ServiceType.homeService) {
          return const SizedBox.shrink();
        }
        return BlocBuilder<ProviderOrdersCubit, ProviderOrdersState>(
          builder: (context, ordersState) {
            final uid = ordersState.providerUid;
            final inProgress = uid == null
                ? <ProviderOrderDashboard>[]
                : ProviderMasterOrderTabFilters.homeInProgress(
                    ordersState.orders,
                    uid,
                  ).map((r) => r.toDashboard()).toList();
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
    );
  }

  Widget _revenueCard() {
    return HomeDashboardRevenueCard(
      revenueEgp: state.todayMetrics.revenueEgp,
      weekRevenueEgp: state.weekMetrics.revenueEgp,
      weekRate: state.weekMetrics.completionRatio,
    );
  }

  Widget _walletCard() {
    return _HomeWalletCard(fallbackBalance: state.walletBalanceEgp);
  }

  Widget _chartSection(BuildContext context) {
    return HomeDashboardChartSection(
      period: state.chartPeriod,
      buckets: state.chartBuckets,
      onPeriodChanged: (p) =>
          context.read<HomeDashboardCubit>().setChartPeriod(p),
    );
  }
}

class _HomeWalletCard extends StatelessWidget {
  const _HomeWalletCard({required this.fallbackBalance});

  final double fallbackBalance;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthCubit>().state;
    if (auth is! Authenticated) {
      return HomeDashboardWalletCard(balanceEgp: fallbackBalance);
    }
    final uid = auth.user.uid;
    final serviceWire = auth.profile.serviceType.wireValue;
    return StreamBuilder(
      stream: getIt<ProviderWalletRepository>().watchWalletSummary(uid),
      builder: (context, walletSnap) {
        final summary = walletSnap.data;
        final balance = summary?.balanceEgp ?? fallbackBalance;
        return StreamBuilder<WalletBalanceLimits>(
          stream: getIt<AppSettingsRepository>().watchWalletBalanceLimits(),
          builder: (context, limitsSnap) {
            final limits = limitsSnap.data ?? WalletBalanceLimits.defaults;
            final limit = limits.forProviderService(serviceWire);
            return HomeDashboardWalletCard(
              balanceEgp: balance,
              pendingEgp: summary?.pendingEgp,
              needsRecharge: limits.needsRecharge(
                balanceEgp: balance,
                limitEgp: limit,
              ),
            );
          },
        );
      },
    );
  }
}
