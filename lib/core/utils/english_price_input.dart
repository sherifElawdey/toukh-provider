import 'package:flutter/services.dart';
import 'package:toukh_ui/toukh_ui.dart';

/// Price inputs: Arabic digits are accepted and turned into English ones, then
/// only ASCII digits and a decimal point are kept.
abstract final class EnglishPriceInput {
  EnglishPriceInput._();

  static final List<TextInputFormatter> formatters = [
    const EnglishDigitsInputFormatter(),
    FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
  ];
}
