import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:toukh_provider/features/shell/provider_notification_badge_cubit.dart';
import 'package:toukh_provider/features/shell/provider_web_layout.dart';
import 'package:toukh_provider/features/shell/widgets/shell_nav_item.dart';
import 'package:toukh_provider/l10n/app_strings.dart';
import 'package:toukh_ui/toukh_ui.dart';

class ProviderShellSidebar extends StatelessWidget {
  const ProviderShellSidebar({
    super.key,
    required this.navItems,
    required this.selectedNavIndex,
    required this.unselectedIconColor,
    required this.onNavTap,
    required this.onOpenNotifications,
  });

  final List<ShellNavItem> navItems;
  final int selectedNavIndex;
  final Color unselectedIconColor;
  final ValueChanged<int> onNavTap;
  final VoidCallback onOpenNotifications;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return SizedBox(
      width: ProviderWebLayout.sidebarWidth,
      child: Material(
        color: scheme.surface,
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: BorderDirectional(
              end: BorderSide(color: scheme.onSurface.withValues(alpha: 0.08)),
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Padding(
                    padding: EdgeInsetsDirectional.only(start: 8, bottom: 28),
                    child: Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: HavitAppBarLogo(height: 36),
                    ),
                  ),
                  for (var i = 0; i < navItems.length; i++) ...[
                    _SidebarDestination(
                      item: navItems[i],
                      selected: selectedNavIndex == i,
                      unselectedIconColor: unselectedIconColor,
                      onTap: () => onNavTap(i),
                    ),
                    if (i != navItems.length - 1) const SizedBox(height: 4),
                  ],
                  const Spacer(),
                  _SidebarNotificationsButton(
                    unselectedIconColor: unselectedIconColor,
                    onPressed: onOpenNotifications,
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

class _SidebarDestination extends StatelessWidget {
  const _SidebarDestination({
    required this.item,
    required this.selected,
    required this.unselectedIconColor,
    required this.onTap,
  });

  final ShellNavItem item;
  final bool selected;
  final Color unselectedIconColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final foreground = selected ? Colors.white : unselectedIconColor;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? AppColors.bottomNavPill : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Icon(
              selected ? item.selectedIcon : item.icon,
              color: foreground,
              size: 22,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: CustomText(
                item.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: foreground,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                  fontSize: 15,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SidebarNotificationsButton extends StatelessWidget {
  const _SidebarNotificationsButton({
    required this.unselectedIconColor,
    required this.onPressed,
  });

  final Color unselectedIconColor;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<
      ProviderNotificationBadgeCubit,
      ProviderNotificationBadgeState
    >(
      builder: (context, badge) {
        return InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Badge(
                  isLabelVisible: badge.notificationCount > 0,
                  label: CustomText('${badge.notificationCount}'),
                  child: Icon(
                    ToukhIcons.notifications,
                    size: 22,
                    color: AppColors.secondColor,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: CustomText(
                    AppStrings.Notifications.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: unselectedIconColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
