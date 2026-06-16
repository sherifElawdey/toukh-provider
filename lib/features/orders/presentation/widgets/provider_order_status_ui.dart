import 'package:flutter/material.dart';
import 'package:toukh_ui/toukh_ui.dart';

Color providerOrderStatusColor(String statusWire) {
  final w = ProviderOrderStatusWire.normalize(statusWire);
  if (ProviderOrderStatusWire.isDelivered(w)) return AppColors.success;
  if (w == ProviderOrderStatusWire.cancelled) return AppColors.error;
  if (w == ProviderOrderStatusWire.placed || w == ProviderOrderStatusWire.pending) {
    return AppColors.warning;
  }
  if (w == ProviderOrderStatusWire.courierRequested ||
      w == ProviderOrderStatusWire.courierAssigned) {
    return AppColors.secondColor;
  }
  return AppColors.appColor;
}

IconData providerOrderStatusIcon(String statusWire) {
  final w = ProviderOrderStatusWire.normalize(statusWire);
  return switch (w) {
    ProviderOrderStatusWire.placed || ProviderOrderStatusWire.pending =>
      ToukhIcons.orders,
    ProviderOrderStatusWire.accepted || ProviderOrderStatusWire.preparing =>
      ToukhIcons.restaurant,
    ProviderOrderStatusWire.courierRequested ||
    ProviderOrderStatusWire.courierAssigned =>
      ToukhIcons.delivery,
    ProviderOrderStatusWire.readyForPickup ||
    ProviderOrderStatusWire.pickedUp ||
    ProviderOrderStatusWire.outForDelivery =>
      PhosphorIconsRegular.package,
    ProviderOrderStatusWire.delivered || ProviderOrderStatusWire.completed =>
      ToukhIcons.success,
    ProviderOrderStatusWire.cancelled => PhosphorIconsRegular.xCircle,
    _ => ToukhIcons.orders,
  };
}

Color providerOrderStatusColorForRow(ProviderMasterOrderRow row) {
  final slice = row.slice;
  if (slice.cancelledAt != null ||
      slice.providerState.trim().toLowerCase() == 'rejected') {
    return AppColors.error;
  }
  return providerOrderStatusColor(slice.statusWire);
}

IconData providerOrderStatusIconForRow(ProviderMasterOrderRow row) {
  final slice = row.slice;
  if (slice.cancelledAt != null ||
      slice.providerState.trim().toLowerCase() == 'rejected') {
    return PhosphorIconsRegular.xCircle;
  }
  return providerOrderStatusIcon(slice.statusWire);
}
