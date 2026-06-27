import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:toukh_provider/features/home/presentation/widgets/home_dashboard_empty_placeholder.dart';
import 'package:toukh_provider/features/home_service_requests/cubit/provider_home_service_requests_cubit.dart';
import 'package:toukh_provider/features/home_service_requests/presentation/widgets/provider_home_service_request_card.dart';
import 'package:toukh_provider/l10n/app_strings.dart';
import 'package:toukh_ui/toukh_ui.dart';

class HomeServiceRequestsScreen extends StatelessWidget {
  const HomeServiceRequestsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return DefaultTabController(
      length: 3,
      child: BlocBuilder<ProviderHomeServiceRequestsCubit,
          ProviderHomeServiceRequestsState>(
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
                  AppStrings.HomeServiceRequests.title.tr,
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
              _HomeServiceRequestsTabBar(),
              Expanded(
                child: TabBarView(
                  children: [
                    _HomeServiceRequestsTabView(
                      tab: ProviderHomeServiceRequestsTab.incoming,
                      emptyMessageKey:
                          AppStrings.HomeServiceRequests.emptyIncoming,
                    ),
                    _HomeServiceRequestsTabView(
                      tab: ProviderHomeServiceRequestsTab.inProgress,
                      emptyMessageKey:
                          AppStrings.HomeServiceRequests.emptyInProgress,
                    ),
                    _HomeServiceRequestsTabView(
                      tab: ProviderHomeServiceRequestsTab.history,
                      emptyMessageKey:
                          AppStrings.HomeServiceRequests.emptyHistory,
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

class _HomeServiceRequestsTabBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final controller = DefaultTabController.of(context);
    final labels = [
      AppStrings.HomeServiceRequests.tabIncoming,
      AppStrings.HomeServiceRequests.tabInProgress,
      AppStrings.HomeServiceRequests.tabHistory,
    ];

    return BlocBuilder<ProviderHomeServiceRequestsCubit,
        ProviderHomeServiceRequestsState>(
      builder: (context, state) {
        final incomingCount = state.pendingIncomingCount;
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
                  for (var i = 0; i < labels.length; i++) ...[
                    if (i > 0) const SizedBox(width: AppSizes.spaceSm),
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => controller.animateTo(i),
                        borderRadius:
                            BorderRadius.circular(AppSizes.radiusFull),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSizes.spaceLg,
                            vertical: AppSizes.spaceSm + 2,
                          ),
                          decoration: BoxDecoration(
                            color: selected == i
                                ? AppColors.appColor
                                : scheme.surfaceContainerHighest
                                    .withValues(alpha: 0.45),
                            borderRadius:
                                BorderRadius.circular(AppSizes.radiusFull),
                            border: Border.all(
                              color: selected == i
                                  ? AppColors.appColor
                                  : scheme.outline.withValues(alpha: 0.28),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CustomText(
                                labels[i].tr,
                                style: TextStyle(
                                  fontSize: AppSizes.fontLabel,
                                  fontWeight: selected == i
                                      ? FontWeight.w700
                                      : FontWeight.w600,
                                  color: selected == i
                                      ? AppColors.surface
                                      : scheme.onSurface
                                          .withValues(alpha: 0.72),
                                ),
                              ),
                              if (i == 0 && incomingCount > 0) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 7,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: selected == i
                                        ? Colors.white.withValues(alpha: 0.22)
                                        : AppColors.appColor
                                            .withValues(alpha: 0.14),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: CustomText(
                                    '$incomingCount',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                      color: selected == i
                                          ? AppColors.surface
                                          : AppColors.appColor,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
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

class _HomeServiceRequestsTabView extends StatelessWidget {
  const _HomeServiceRequestsTabView({
    required this.tab,
    required this.emptyMessageKey,
  });

  final ProviderHomeServiceRequestsTab tab;
  final String emptyMessageKey;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProviderHomeServiceRequestsCubit,
        ProviderHomeServiceRequestsState>(
      builder: (context, state) {
        if (state.loading && state.requests.isEmpty) {
          return const Center(child: AppLoadingMark());
        }

        final list = state.forTab(tab);
        if (list.isEmpty) {
          return Center(
            child: HomeDashboardEmptyPlaceholder(
              message: emptyMessageKey.tr,
              compact: true,
            ),
          );
        }

        return ListView.separated(
          padding: AppSizes.screenPadding.copyWith(
            top: AppSizes.spaceSm,
            bottom: AppSizes.space2xl,
          ),
          itemCount: list.length,
          separatorBuilder: (_, _) => const SizedBox(height: AppSizes.spaceMd),
          itemBuilder: (context, i) {
            return ProviderHomeServiceRequestCard(
              request: list[i],
              tab: tab,
            );
          },
        );
      },
    );
  }
}
