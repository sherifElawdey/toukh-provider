import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:toukh_provider/domain/entities/provider_dashboard_order.dart';
import 'package:toukh_provider/l10n/app_strings.dart';
import 'package:toukh_ui/toukh_ui.dart';

String formatDashboardEgp(BuildContext context, double value) {
  final locale = Localizations.localeOf(context).toLanguageTag();
  final fmt = NumberFormat.decimalPattern(locale);
  return '${fmt.format(value.round())} EGP';
}

String dashboardOrderStatusLabel(ProviderOrderDashboard o) {
  final w = o.statusWire.toLowerCase();
  if (w == 'preparing' || w == 'ready' || w == 'ready_for_pickup') {
    return AppStrings.Home.dashboardStatusPreparing.tr;
  }
  if (w == 'picked_up') {
    return AppStrings.Home.dashboardStatusPickup.tr;
  }
  return switch (o.status) {
    OrderStatus.placed => AppStrings.Home.dashboardStatusNew.tr,
    OrderStatus.accepted => AppStrings.Home.dashboardStatusPreparing.tr,
    OrderStatus.pickedUp => AppStrings.Home.dashboardStatusPickup.tr,
    OrderStatus.delivered || OrderStatus.cancelled =>
      o.statusWire.isNotEmpty ? o.statusWire : '—',
  };
}
