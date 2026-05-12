import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:toukh_provider/core/constants/app_assets.dart';
import 'package:toukh_provider/core/router/app_routes.dart';
import 'package:toukh_provider/features/auth/cubit/auth_cubit.dart';
import 'package:toukh_ui/toukh_ui.dart';
import 'package:toukh_provider/l10n/app_strings.dart';

class MainShellScaffold extends StatelessWidget {
  const MainShellScaffold({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  static List<_ShellNavItem> _navItems({required bool isRestaurant}) => [
        _ShellNavItem(
          label: AppStrings.Shell.home,
          icon: Icons.home_outlined,
          selectedIcon: Icons.home_rounded,
        ),
        _ShellNavItem(
          label: AppStrings.Shell.orders,
          icon: Icons.receipt_long_outlined,
          selectedIcon: Icons.receipt_long_rounded,
        ),
        _ShellNavItem(
          label: isRestaurant ? AppStrings.Shell.menu : AppStrings.Shell.gallery,
          icon: isRestaurant
              ? Icons.restaurant_menu_outlined
              : Icons.photo_library_outlined,
          selectedIcon: isRestaurant
              ? Icons.restaurant_menu_rounded
              : Icons.photo_library_rounded,
        ),
        _ShellNavItem(
          label: AppStrings.Shell.settings,
          icon: Icons.settings_outlined,
          selectedIcon: Icons.settings_rounded,
        ),
      ];

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthCubit>().state;
    final isRestaurant =
        authState is Authenticated && authState.profile.isRestaurantShop;
    final navItems = _navItems(isRestaurant: isRestaurant);
    final scheme = Theme.of(context).colorScheme;
    final unselectedIconColor = scheme.onSurface.withValues(alpha: 0.45);

    return Scaffold(
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
                navItems[navigationShell.currentIndex].label,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 20,
                  color: scheme.onSurface,
                ),
              ),
        actions: [
          IconButton(
            tooltip: AppStrings.Notifications.title.tr,
            onPressed: () => context.push(AppRoutes.notifications),
            icon: Icon(
              Icons.notifications_none_rounded,
              size: 26,
              color: AppColors.secondColor,
            ),
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
                      flex: navigationShell.currentIndex == i ? 3 : 2,
                      child: _ShellNavDestination(
                        item: navItems[i],
                        selected: navigationShell.currentIndex == i,
                        unselectedIconColor: unselectedIconColor,
                        onTap: () => navigationShell.goBranch(
                          i,
                          initialLocation: i == navigationShell.currentIndex,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ShellNavItem {
  const _ShellNavItem({
    required this.label,
    required this.icon,
    required this.selectedIcon,
  });

  final String label;
  final IconData icon;
  final IconData selectedIcon;
}

class _ShellNavDestination extends StatelessWidget {
  const _ShellNavDestination({
    required this.item,
    required this.selected,
    required this.unselectedIconColor,
    required this.onTap,
  });

  final _ShellNavItem item;
  final bool selected;
  final Color unselectedIconColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(28),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Center(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            padding: selected
                ? const EdgeInsets.symmetric(horizontal: 14, vertical: 10)
                : const EdgeInsets.all(10),
            decoration: selected
                ? BoxDecoration(
                    color: AppColors.bottomNavPill,
                    borderRadius: BorderRadius.circular(28),
                  )
                : null,
            child: selected
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      Icon(item.selectedIcon, color: Colors.white, size: 22),
                      const SizedBox(width: 8),
                      Flexible(
                        child: CustomText(
                          item.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ),
                    ],
                  )
                : Icon(item.icon, color: unselectedIconColor, size: 26),
          ),
        ),
      ),
    );
  }
}
