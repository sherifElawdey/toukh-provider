import 'package:get/get.dart';
import 'package:toukh_ui/toukh_ui.dart';

String appFirebaseError(Object error) {
  final msg = firebaseUserMessage(
    error,
    localize: (key, {params = const {}}) =>
        params.isEmpty ? key.tr : key.trParams(params),
  );
  return _phoneAuthWording(msg);
}

/// Replaces email-centric Firebase English text with phone wording for provider auth.
String _phoneAuthWording(String message) {
  var result = message;
  result = result.replaceAll(
    RegExp(r'e-mail address', caseSensitive: false),
    'phone number',
  );
  result = result.replaceAll(
    RegExp(r'email address', caseSensitive: false),
    'phone number',
  );
  result = result.replaceAll(
    RegExp(r'\bemail\b', caseSensitive: false),
    'phone number',
  );
  return result;
}
