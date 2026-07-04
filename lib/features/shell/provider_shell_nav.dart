import 'package:toukh_provider/domain/entities/provider_kind.dart';
import 'package:toukh_provider/features/shell/widgets/shell_nav_item.dart';
import 'package:toukh_provider/l10n/app_strings.dart';
import 'package:toukh_ui/toukh_ui.dart';

/// Maps bottom-nav taps to [StatefulNavigationShell] branch indices.
abstract final class ProviderShellNav {
  ProviderShellNav._();

  static const _homeBranch = 0;
  static const _ordersBranch = 1;
  static const _scheduleBranch = 2;
  static const _settingsBranch = 3;

  static List<ShellNavItem> navItems({
    required bool isRestaurant,
    required bool isHomeService,
  }) {
    if (isHomeService) {
      return [
        ShellNavItem(
          label: AppStrings.Shell.home,
          icon: ToukhIcons.home,
          selectedIcon: ToukhIcons.homeSelected,
        ),
        ShellNavItem(
          label: AppStrings.Shell.schedule,
          icon: ToukhIcons.calendar,
          selectedIcon: ToukhIcons.calendar,
        ),
        ShellNavItem(
          label: AppStrings.Shell.orders,
          icon: ToukhIcons.orders,
          selectedIcon: ToukhIcons.ordersSelected,
        ),
        ShellNavItem(
          label: AppStrings.Shell.settings,
          icon: ToukhIcons.settings,
          selectedIcon: ToukhIcons.settingsSelected,
        ),
      ];
    }

    return [
      ShellNavItem(
        label: AppStrings.Shell.home,
        icon: ToukhIcons.home,
        selectedIcon: ToukhIcons.homeSelected,
      ),
      ShellNavItem(
        label: AppStrings.Shell.orders,
        icon: ToukhIcons.orders,
        selectedIcon: ToukhIcons.ordersSelected,
      ),
      ShellNavItem(
        label: isRestaurant ? AppStrings.Shell.menu : AppStrings.Shell.gallery,
        icon: isRestaurant ? ToukhIcons.menu : ToukhIcons.gallery,
        selectedIcon: isRestaurant
            ? ToukhIcons.menuSelected
            : ToukhIcons.gallerySelected,
      ),
      ShellNavItem(
        label: AppStrings.Shell.settings,
        icon: ToukhIcons.settings,
        selectedIcon: ToukhIcons.settingsSelected,
      ),
    ];
  }

  static int branchIndexForNavTap({
    required int navIndex,
    required bool isHomeService,
  }) {
    if (!isHomeService) return navIndex;
    return switch (navIndex) {
      0 => _homeBranch,
      1 => _scheduleBranch,
      2 => _ordersBranch,
      3 => _settingsBranch,
      _ => _homeBranch,
    };
  }

  static int navIndexForBranch({
    required int branchIndex,
    required bool isHomeService,
  }) {
    if (!isHomeService) return branchIndex;
    return switch (branchIndex) {
      _homeBranch => 0,
      _scheduleBranch => 1,
      _ordersBranch => 2,
      _settingsBranch => 3,
      _ => 0,
    };
  }

  static bool isHomeServiceProvider(ServiceType? type) =>
      type == ServiceType.homeService;
}
