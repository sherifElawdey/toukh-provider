import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:toukh_provider/core/router/app_routes.dart';
import 'package:toukh_provider/domain/entities/provider_kind.dart';
import 'package:toukh_provider/features/auth/cubit/auth_cubit.dart';
import 'package:toukh_provider/features/onboarding/cubit/onboarding_cubit.dart';
import 'package:toukh_provider/features/onboarding/presentation/widgets/permission_required_sheet.dart';
import 'package:toukh_provider/features/shell/provider_shell_nav.dart';
import 'package:toukh_provider/features/shell/provider_web_layout.dart';
import 'package:toukh_provider/features/shell/widgets/provider_shell_sidebar.dart';
import 'package:toukh_provider/features/shell/widgets/shell_nav_destination.dart';
import 'package:toukh_provider/features/shell/provider_notification_badge_cubit.dart';
import 'package:toukh_provider/l10n/app_strings.dart';
import 'package:toukh_ui/toukh_ui.dart';

class MainShellScaffold extends StatelessWidget {
  const MainShellScaffold({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  Future<void> _openNotifications(BuildContext context) async {
    final cubit = context.read<OnboardingCubit>();
    final granted = await cubit.isNotificationGranted();
    if (!context.mounted) return;
    if (granted) {
      context.push(AppRoutes.notifications);
      return;
    }

    final permanentlyDenied = await Permission.notification.isPermanentlyDenied;
    if (!context.mounted) return;
    final enable = await PermissionRequiredSheet.showForNotifications(
      context,
      permanentlyDenied: permanentlyDenied,
    );
    if (!enable || !context.mounted) return;

    if (permanentlyDenied) {
      await cubit.openSystemSettings();
      return;
    }

    await cubit.requestNotificationPermission();
    if (!context.mounted) return;
    final nowGranted = await cubit.isNotificationGranted();
    if (!context.mounted) return;
    if (nowGranted) {
      context.push(AppRoutes.notifications);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthCubit>().state;
    final isRestaurant =
        authState is Authenticated && authState.profile.isRestaurantShop;
    final isHomeService =
        authState is Authenticated &&
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
    final unselectedIconColor = scheme.onSurfaceVariant;
    final pageTitle = CustomText(
      navItems[selectedNavIndex.clamp(0, navItems.length - 1)].label,
      style: TextStyle(
        fontWeight: FontWeight.w800,
        fontSize: AppSizes.fontTitle,
        color: scheme.onSurface,
      ),
    );

    final wide = ProviderWebLayout.isWide(context);

    return AppSnackInsets(
      bottomInset: wide ? AppSizes.spaceBase : 76,
      child: Scaffold(
        appBar: wide
            ? null
            : AppBar(
                title: navigationShell.currentIndex == 0
                    ? const HavitAppBarLogo(height: 32)
                    : pageTitle,
                actions: [
                  BlocBuilder<
                    ProviderNotificationBadgeCubit,
                    ProviderNotificationBadgeState
                  >(
                    builder: (context, badge) {
                      return IconButton(
                        tooltip: AppStrings.Notifications.title.tr,
                        onPressed: () => _openNotifications(context),
                        icon: Badge(
                          isLabelVisible: badge.notificationCount > 0,
                          label: CustomText('${badge.notificationCount}'),
                          child: Icon(ToukhIcons.notifications, size: 24),
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 4),
                ],
              ),
        body: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              width: wide ? ProviderWebLayout.sidebarWidth : 0,
              child: wide
                  ? ProviderShellSidebar(
                      navItems: navItems,
                      selectedNavIndex: selectedNavIndex,
                      unselectedIconColor: unselectedIconColor,
                      onOpenNotifications: () => _openNotifications(context),
                      onNavTap: (index) => navigationShell.goBranch(
                        ProviderShellNav.branchIndexForNavTap(
                          navIndex: index,
                          isHomeService: isHomeService,
                        ),
                        initialLocation: selectedNavIndex == index,
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
            Expanded(
              child: Column(
                children: [
                  if (wide)
                    SizedBox(
                      height:
                          MediaQuery.paddingOf(context).top + kToolbarHeight,
                      child: AppBar(
                        primary: true,
                        automaticallyImplyLeading: false,
                        title: pageTitle,
                      ),
                    )
                  else
                    const SizedBox.shrink(),
                  Expanded(child: navigationShell),
                ],
              ),
            ),
          ],
        ),
        bottomNavigationBar: wide
            ? null
            : ColoredBox(
                color: Theme.of(context).cardColor,
                child: SafeArea(
                  top: false,
                  bottom: true,
                  child: Container(
                    height: 72,
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      border: const Border(
                        top: BorderSide(color: AppColors.borderSubtle),
                      ),
                    ),
                    child: Material(
                      type: MaterialType.transparency,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
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
                                    initialLocation: selectedNavIndex == i,
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
      ),
    );
  }
}
