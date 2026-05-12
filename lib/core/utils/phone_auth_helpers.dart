import 'package:toukh_provider/core/constants/app_constants.dart';

/// Synthetic Firebase Auth email for providers: `provider{digits}@toukh.com`.
String syntheticEmailFromPhone(String rawPhone) {
  final digits = rawPhone.replaceAll(RegExp(r'\D'), '');
  if (digits.isEmpty) {
    throw ArgumentError('Phone must contain digits');
  }
  return 'provider$digits@${AppConstants.syntheticEmailDomain}';
}

/// National digits for display (strips non-digits).
String displayDigits(String rawPhone) =>
    rawPhone.replaceAll(RegExp(r'\D'), '');
