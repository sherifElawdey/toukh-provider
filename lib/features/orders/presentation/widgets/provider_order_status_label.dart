import 'package:get/get.dart';
import 'package:toukh_provider/l10n/app_strings.dart';
import 'package:toukh_provider/shared/shared.dart';

String providerOrderStatusLabel(ProviderMasterOrderRow row) {
  if (row.isAwaitingStoreDriverAccept) {
    return AppStrings.Orders.awaitingDriverApproval.tr;
  }
  return ToukhStatusKeys.provider(row.slice.statusWire).tr;
}
