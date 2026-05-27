import 'package:flutter/foundation.dart';
import 'package:toukh_ui/toukh_ui.dart';

/// Caches the Remote Config version check and notifies listeners when it completes.
class AppVersionGateService extends ChangeNotifier {
  AppUpdateGateResult? _result;
  Future<AppUpdateGateResult>? _inflight;

  bool get checked => _result != null;
  bool get needsUpdate => _result?.needsUpdate ?? false;

  Uri? get storeUri {
    if (_result?.storeUri != null) return _result!.storeUri;
    if (needsUpdate) {
      return ToukhStoreListings.resolveStoreUriForRemoteConfigKey(
        ToukhRemoteConfigKeys.toukhProviderVersion,
      );
    }
    return null;
  }

  Future<AppUpdateGateResult> ensureChecked() {
    return _inflight ??= _runCheck();
  }

  Future<AppUpdateGateResult> _runCheck() async {
    final result = await checkAppVersionAgainstRemoteConfig(
      minimumVersionKey: ToukhRemoteConfigKeys.toukhProviderVersion,
    );
    _result = result;
    notifyListeners();
    return result;
  }
}
