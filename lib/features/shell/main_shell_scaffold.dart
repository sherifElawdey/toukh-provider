import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:toukh_provider/core/constants/app_assets.dart';
import 'package:toukh_provider/core/router/app_routes.dart';
import 'package:toukh_provider/domain/entities/provider_kind.dart';
import 'package:toukh_provider/features/auth/cubit/auth_cubit.dart';
import 'package:toukh_provider/features/shell/provider_shell_nav.dart';
import 'package:toukh_provider/features/shell/widgets/shell_nav_destination.dart';
import 'package:toukh_provider/features/shell/provider_notification_badge_cubit.dart';
import 'package:toukh_provider/l10n/app_strings.dart';
import 'package:toukh_ui/toukh_ui.dart';

class MainShellScaffold extends StatelessWidget {
  const MainShellScaffold({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthCubit>().state;
    final isRestaurant =
        authState is Authenticated && authState.profile.isRestaurantShop;
    final isHomeService = authState is Authenticated &&
        authState.profile.serviceType == ServiceType.homeService;
    final navItems = ProviderShellNav.navItems(
      isRestaurant: isRestaurant,
      isHomeService: isHomeService,
    );
    final selectedNavIndex = ProviderShellNav.navIndexForBranch(
      branchIndex: navigationShell.currentIndex,
      isHomeService: isHomeService,
    );
    final scheme = Theme.of(context).colorScheme;
    final unselectedIconColor = scheme.onSurface.withValues(alpha: 0.45);

    return AppSnackInsets(
      bottomInset: 100,
      child: Scaffold(
        appBar: AppBar(
          title: navigationShell.currentIndex == 0
              ? Image.asset(
                  AppAssets.brandingAppText,
                  height: 26,
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.high,
                  errorBuilder: (_, _, _) => CustomText(
                    AppStrings.App.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 20,
                      color: AppColors.secondColor,
                    ),
                  ),
                )
              : CustomText(
                  navItems[selectedNavIndex.clamp(0, navItems.length - 1)]
                      .label,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 20,
                    color: scheme.onSurface,
                  ),
                ),
          actions: [
            BlocBuilder<ProviderNotificationBadgeCubit,
                ProviderNotificationBadgeState>(
              builder: (context, badge) {
                return IconButton(
                  tooltip: AppStrings.Notifications.title.tr,
                  onPressed: () => context.push(AppRoutes.notifications),
                  icon: Badge(
                    isLabelVisible: badge.notificationCount > 0,
                    label: CustomText('${badge.notificationCount}'),
                    child: Icon(
                      ToukhIcons.notifications,
                      size: 26,
                      color: AppColors.secondColor,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(width: 4),
          ],
        ),
        body: navigationShell,
        bottomNavigationBar: SizedBox(
          height: 100,
          child: Material(
            elevation: 8,
            shadowColor: Colors.black.withValues(alpha: 0.12),
            surfaceTintColor: Colors.transparent,
            clipBehavior: Clip.antiAlias,
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 10, 8, 8),
                child: Row(
                  children: [
                    for (var i = 0; i < navItems.length; i++)
                      Expanded(
                        flex: selectedNavIndex == i ? 3 : 2,
                        child: ShellNavDestination(
                          item: navItems[i],
                          selected: selectedNavIndex == i,
                          unselectedIconColor: unselectedIconColor,
                          onTap: () => navigationShell.goBranch(
                            ProviderShellNav.branchIndexForNavTap(
                              navIndex: i,
                              isHomeService: isHomeService,
                            ),
                            initialLocation:
                                selectedNavIndex == i,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
