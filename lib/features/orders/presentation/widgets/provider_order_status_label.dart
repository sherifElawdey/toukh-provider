import 'package:get/get.dart';
import 'package:toukh_ui/toukh_ui.dart';

String providerOrderStatusLabel(ProviderMasterOrderRow row) {
  return ToukhStatusKeys.provider(row.slice.statusWire).tr;
}
