import 'package:get/get.dart';
import 'package:toukh_ui/toukh_ui.dart';

String appFirebaseError(Object error) {
  return firebaseUserMessage(
    error,
    localize: (key, {params = const {}}) =>
        params.isEmpty ? key.tr : key.trParams(params),
  );
}
