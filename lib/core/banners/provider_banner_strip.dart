import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:toukh_provider/core/router/app_routes.dart';
import 'package:toukh_provider/di/service_locator.dart';
import 'package:toukh_ui/toukh_ui.dart';

/// Banner page keys ([ToukhBannerTargets]) available in the provider app.
/// Tab routes are switched to; the rest are pushed.
const _tabs = <String, String>{
  'home': AppRoutes.home,
  'orders': AppRoutes.orders,
  'menu': AppRoutes.menu,
  'settings': AppRoutes.settings,
};
const _pages = <String, String>{
  'wallet': AppRoutes.wallet,
  'notifications': AppRoutes.notifications,
  'revenues': AppRoutes.revenues,
  'reviews': AppRoutes.reviews,
  'orders-history': AppRoutes.ordersHistory,
};

Future<bool> openProviderBannerPage(
  BuildContext context,
  String page,
  Map<String, String> payload,
) async {
  final tab = _tabs[page];
  if (tab != null) {
    context.go(tab);
    return true;
  }
  final path = _pages[page];
  if (path == null) return false;
  context.push(path);
  return true;
}

/// Banners for one provider-app [placement].
class ProviderBannerStrip extends StatelessWidget {
  const ProviderBannerStrip({
    super.key,
    required this.placement,
    this.padding = EdgeInsets.zero,
  });

  final String placement;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) => ToukhBannerStrip(
    service: getIt<ToukhBannerService>(),
    placement: placement,
    openPage: openProviderBannerPage,
    padding: padding,
  );
}
