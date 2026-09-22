import 'package:flutter/services.dart';

/// Restricts price inputs to ASCII digits and a decimal point (no Arabic numerals).
abstract final class EnglishPriceInput {
  EnglishPriceInput._();

  static final List<TextInputFormatter> formatters = [
    FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
  ];
}
