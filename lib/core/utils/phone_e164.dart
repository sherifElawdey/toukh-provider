/// Normalizes user input to E.164: trims, ensures a single leading '+' plus digits.
String toFirebaseE164(String raw) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty) return '';
  final digits = trimmed.replaceAll(RegExp(r'\D'), '');
  if (digits.isEmpty) return '';
  return '+$digits';
}

const String kEgyptCallingCodeDigits = '20';

String egyptMobileE164(String tenNationalDigits) {
  final d = tenNationalDigits.replaceAll(RegExp(r'\D'), '');
  if (d.length != 10) return '';
  return '+$kEgyptCallingCodeDigits$d';
}

String? egyptTenDigitsFromStored(String? storedDigits) {
  if (storedDigits == null || storedDigits.isEmpty) return null;
  var d = storedDigits.replaceAll(RegExp(r'\D'), '');
  if (d.startsWith('0020')) {
    d = d.substring(4);
  }
  if (d.startsWith(kEgyptCallingCodeDigits) && d.length >= 12) {
    d = d.substring(2);
  }
  if (d.startsWith('0') && d.length == 11) {
    d = d.substring(1);
  }
  if (d.length > 10) {
    d = d.substring(d.length - 10);
  }
  return d.isEmpty ? null : d;
}

String formatEgyptTenDigitsDisplay(String digitsOnly) {
  final d = digitsOnly.replaceAll(RegExp(r'\D'), '');
  final t = d.length > 10 ? d.substring(0, 10) : d;
  if (t.isEmpty) return '';
  if (t.length <= 3) return t;
  if (t.length <= 6) {
    return '${t.substring(0, 3)} ${t.substring(3)}';
  }
  return '${t.substring(0, 3)} ${t.substring(3, 6)} ${t.substring(6)}';
}

String maskEgyptNationalPhoneLastThree(String storedDigits) {
  final ten = egyptTenDigitsFromStored(storedDigits);
  if (ten == null || ten.isEmpty) return '****';
  final d = ten.replaceAll(RegExp(r'\D'), '');
  if (d.length >= 3) {
    return '****${d.substring(d.length - 3)}';
  }
  return '****$d';
}
