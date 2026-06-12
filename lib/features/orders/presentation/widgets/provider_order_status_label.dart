import 'package:get/get.dart';
import 'package:toukh_provider/l10n/app_strings.dart';
import 'package:toukh_ui/toukh_ui.dart';

String providerOrderStatusLabel(ProviderMasterOrderRow row) {
  final w = ProviderOrderStatusWire.normalize(row.slice.statusWire);
  switch (w) {
    case ProviderOrderStatusWire.placed:
    case ProviderOrderStatusWire.pending:
      return AppStrings.Orders.statusNew.tr;
    case ProviderOrderStatusWire.accepted:
    case ProviderOrderStatusWire.preparing:
      return AppStrings.Orders.statusPreparing.tr;
    case ProviderOrderStatusWire.courierRequested:
      return AppStrings.Orders.statusCourierRequested.tr;
    case ProviderOrderStatusWire.courierAssigned:
      return AppStrings.Orders.statusCourierAssigned.tr;
    case ProviderOrderStatusWire.readyForPickup:
      return AppStrings.Orders.statusReadyForPickup.tr;
    case ProviderOrderStatusWire.outForDelivery:
      return AppStrings.Orders.statusOutForDelivery.tr;
    case ProviderOrderStatusWire.pickedUp:
      return AppStrings.Orders.statusPickup.tr;
    case ProviderOrderStatusWire.delivered:
    case ProviderOrderStatusWire.completed:
      return AppStrings.Orders.statusDelivered.tr;
    case ProviderOrderStatusWire.cancelled:
      return AppStrings.Orders.statusCancelled.tr;
    default:
      return row.slice.statusWire;
  }
}
