import 'package:flutter/foundation.dart';

import 'app_remote_config_version_gate.dart';
import 'toukh_store_listings.dart';

/// Caches the Remote Config version check and notifies listeners when it completes.
class AppVersionGateService extends ChangeNotifier {
  AppVersionGateService({required this.minimumVersionKey});

  final String minimumVersionKey;

  AppUpdateGateResult? _result;
  Future<AppUpdateGateResult>? _inflight;

  bool get checked => _result != null;
  bool get needsUpdate => _result?.needsUpdate ?? false;

  Uri? get storeUri {
    if (_result?.storeUri != null) return _result!.storeUri;
    if (needsUpdate) {
      return ToukhStoreListings.resolveStoreUriForRemoteConfigKey(
        minimumVersionKey,
      );
    }
    return null;
  }

  Future<AppUpdateGateResult> ensureChecked() {
    return _inflight ??= _runCheck();
  }

  Future<AppUpdateGateResult> _runCheck() async {
    final result = await checkAppVersionAgainstRemoteConfig(
      minimumVersionKey: minimumVersionKey,
    );
    _result = result;
    notifyListeners();
    return result;
  }
}
