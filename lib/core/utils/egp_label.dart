import 'package:get/get.dart';
import 'package:toukh_provider/l10n/app_strings.dart';

/// Localized money label: "EGP 120" in English, "120 ج.م" in Arabic.
String egpLabel(Object amount) =>
    AppStrings.Common.egpAmount.trParams({'amount': '$amount'});
