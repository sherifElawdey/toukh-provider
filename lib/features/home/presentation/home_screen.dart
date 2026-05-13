import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:toukh_provider/features/home/cubit/home_dashboard_cubit.dart';
import 'package:toukh_provider/features/home/cubit/home_dashboard_state.dart';
import 'package:toukh_provider/features/home/presentation/widgets/home_dashboard_sections.dart';
import 'package:toukh_provider/l10n/app_strings.dart';
import 'package:toukh_ui/toukh_ui.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

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
                FilledButton(
                  onPressed: () => context.read<HomeDashboardCubit>().retry(),
                  child: CustomText(AppStrings.Common.retry.tr),
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
                          color: scheme.onSurface.withValues(alpha: 0.62),
                          height: 1.35,
                        ),
                      ),
                      // if (kDebugMode) ...[
                      //   const SizedBox(height: AppSizes.spaceMd),
                      //   Align(
                      //     alignment: Alignment.centerLeft,
                      //     child: FilledButton.icon(
                      //       icon: const Icon(Icons.cloud_upload_outlined, size: 22),
                      //       label: CustomText(AppStrings.Home.seedDemoProvidersButton.tr),
                      //       onPressed: () => _onSeedDemoProviders(context),
                      //     ),
                      //   ),
                      // ],
                      // if (state.usedMockFallback) ...[
                      //   const SizedBox(height: AppSizes.spaceMd),
                      //   Container(
                      //     padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      //     decoration: BoxDecoration(
                      //       color: scheme.tertiaryContainer.withValues(alpha: 0.45),
                      //       borderRadius: BorderRadius.circular(16),
                      //     ),
                      //     child: Row(
                      //       children: [
                      //         Icon(Icons.info_outline_rounded, color: scheme.tertiary, size: 22),
                      //         const SizedBox(width: 10),
                      //         Expanded(
                      //           child: CustomText(
                      //             AppStrings.Home.dashboardMockPreview.tr,
                      //             style: TextStyle(
                      //               fontSize: 13,
                      //               color: scheme.onSurface.withValues(alpha: 0.78),
                      //               height: 1.3,
                      //             ),
                      //           ),
                      //         ),
                      //       ],
                      //     ),
                      //   ),
                      // ],
                      const SizedBox(height: AppSizes.spaceXl),
                      HomeDashboardInProgressStrip(orders: state.inProgressOrders),
                      const SizedBox(height: AppSizes.spaceXl),
                      HomeDashboardWalletCard(
                        balanceEgp: state.walletBalanceEgp,
                        pendingEgp: state.walletPendingEgp,
                      ),
                      const SizedBox(height: AppSizes.spaceXl),
                      HomeDashboardStatsRow(
                        metrics: state.metricsForSelectedPeriod,
                        period: state.chartPeriod,
                      ),
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
