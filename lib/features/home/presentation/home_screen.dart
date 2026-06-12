import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:toukh_provider/core/updates/app_version_gate_service.dart';
import 'package:toukh_provider/di/service_locator.dart';
import 'package:toukh_provider/domain/entities/provider_dashboard_order.dart';
import 'package:toukh_provider/domain/entities/provider_master_order_extensions.dart';
import 'package:toukh_provider/features/auth/cubit/auth_cubit.dart';
import 'package:toukh_provider/features/home/cubit/home_dashboard_cubit.dart';
import 'package:toukh_provider/features/home/cubit/home_dashboard_state.dart';
import 'package:toukh_provider/features/home/presentation/widgets/home_dashboard_sections.dart';
import 'package:toukh_provider/features/orders/cubit/provider_orders_cubit.dart';
import 'package:toukh_provider/l10n/app_strings.dart';
import 'package:toukh_ui/toukh_ui.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final AppVersionGateService _versionGate;
  bool _updateDialogVisible = false;

  @override
  void initState() {
    super.initState();
    _versionGate = getIt<AppVersionGateService>();
    _versionGate.addListener(_onVersionGateChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_syncFcmToken());
      unawaited(_presentMandatoryUpdateIfNeeded());
    });
  }

  @override
  void dispose() {
    _versionGate.removeListener(_onVersionGateChanged);
    super.dispose();
  }

  void _onVersionGateChanged() {
    unawaited(_presentMandatoryUpdateIfNeeded());
  }

  Future<void> _presentMandatoryUpdateIfNeeded() async {
    if (!mounted || _updateDialogVisible) return;
    final result = await _versionGate.ensureChecked();
    if (!mounted || !result.needsUpdate || _updateDialogVisible) return;
    final storeUri = _versionGate.storeUri;
    if (storeUri == null) return;

    _updateDialogVisible = true;
    await showAppMandatoryUpdateDialog(
      context,
      title: AppStrings.AppUpdate.title.tr,
      description: AppStrings.AppUpdate.description.tr,
      storeUri: storeUri,
      updateButtonLabel: AppStrings.AppUpdate.openStore.tr,
      imageAsset: 'assets/branding/app_icon_provider.png',
      imagePackage: null,
    );
    if (mounted) {
      _updateDialogVisible = false;
      unawaited(_presentMandatoryUpdateIfNeeded());
    }
  }

  Future<void> _syncFcmToken() async {
    final auth = getIt<AuthCubit>().state;
    if (auth is! Authenticated) return;
    await ToukhFcmTokenSync.syncIfNeeded(
      uid: auth.user.uid,
      existingFcmTokens: auth.profile.fcmTokens,
      firestore: FirebaseFirestore.instance,
      recipient: ToukhNotificationRecipient.provider,
    );
  }

  String _greetingTr() {
    final h = DateTime.now().hour;
    if (h < 12) return AppStrings.Home.greetingMorning.tr;
    if (h < 17) return AppStrings.Home.greetingAfternoon.tr;
    return AppStrings.Home.greetingEvening.tr;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return BlocBuilder<HomeDashboardCubit, HomeDashboardState>(
      builder: (context, state) {
        if (!state.authenticated) {
          return const SizedBox.shrink();
        }

        if (state.errorMessage != null &&
            !state.loading &&
            state.orders.isEmpty &&
            state.reviews.isEmpty) {
          return Padding(
            padding: AppSizes.screenPadding.copyWith(top: AppSizes.spaceXl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                CustomText(
                  AppStrings.Common.error.tr,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: AppSizes.fontHeadline,
                    color: scheme.onSurface,
                  ),
                ),
                const SizedBox(height: AppSizes.spaceSm),
                CustomText(
                  state.errorMessage!,
                  style: TextStyle(color: scheme.onSurface.withValues(alpha: 0.72)),
                ),
                const SizedBox(height: AppSizes.spaceLg),
                AppFilledButton(
                  text: AppStrings.Common.retry.tr,
                  onTap: () => context.read<HomeDashboardCubit>().retry(),
                ),
              ],
            ),
          );
        }

        if (state.loading &&
            state.orders.isEmpty &&
            state.reviews.isEmpty &&
            state.errorMessage == null) {
          return const Center(child: CircularProgressIndicator());
        }

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
                        '${_greetingTr()}, ${state.providerDisplayName}',
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
                      BlocBuilder<ProviderOrdersCubit, ProviderOrdersState>(
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
                      ),
                      BlocBuilder<ProviderOrdersCubit, ProviderOrdersState>(
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
      },
    );
  }
}
