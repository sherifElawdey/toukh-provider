import 'dart:async';

import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart' show debugPrint, kDebugMode;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:pub_semver/pub_semver.dart';

import 'toukh_remote_config_keys.dart';
import 'toukh_store_listings.dart';

/// Outcome of [checkAppVersionAgainstRemoteConfig].
final class AppUpdateGateResult {
  const AppUpdateGateResult({
    required this.needsUpdate,
    required this.currentVersion,
    this.minimumVersion,
    this.storeUri,
    this.error,
  });

  final bool needsUpdate;
  final String currentVersion;
  final String? minimumVersion;
  final Uri? storeUri;
  final Object? error;
}

AppUpdateGateResult _evaluate({
  required String currentRaw,
  required String minimumRaw,
  required String minimumVersionKey,
  Object? error,
}) {
  if (minimumRaw.isEmpty) {
    return AppUpdateGateResult(
      needsUpdate: false,
      currentVersion: currentRaw,
      minimumVersion: minimumRaw,
      error: error,
    );
  }

  try {
    final minimum = Version.parse(minimumRaw);
    final current = Version.parse(currentRaw);
    final needs = current < minimum;
    final storeUri = needs
        ? ToukhStoreListings.resolveStoreUriForRemoteConfigKey(minimumVersionKey)
        : null;
    return AppUpdateGateResult(
      needsUpdate: needs,
      currentVersion: currentRaw,
      minimumVersion: minimumRaw,
      storeUri: storeUri,
      error: error,
    );
  } catch (e) {
    debugPrint('[AppUpdateGate] semver parse failed: $e');
    return AppUpdateGateResult(
      needsUpdate: false,
      currentVersion: currentRaw,
      minimumVersion: minimumRaw,
      error: e,
    );
  }
}

/// Fetches Remote Config, reads [minimumVersionKey], and compares to the installed app version.
///
/// Activates any previously fetched values first, then attempts a short network refresh.
/// On any failure (network, RC not configured, parse errors), returns [AppUpdateGateResult]
/// with [AppUpdateGateResult.needsUpdate] `false` (or cached minimum) so the app stays usable offline.
Future<AppUpdateGateResult> checkAppVersionAgainstRemoteConfig({
  required String minimumVersionKey,
  Duration fetchTimeout = const Duration(seconds: 4),
}) async {
  final info = await PackageInfo.fromPlatform();
  final currentRaw = info.version.trim();
  if (!ToukhRemoteConfigKeys.all.contains(minimumVersionKey)) {
    return AppUpdateGateResult(
      needsUpdate: false,
      currentVersion: currentRaw,
      error: ArgumentError.value(
        minimumVersionKey,
        'minimumVersionKey',
        'Use one of ToukhRemoteConfigKeys.*',
      ),
    );
  }

  try {
    final rc = FirebaseRemoteConfig.instance;
    await rc.setDefaults({
      for (final k in ToukhRemoteConfigKeys.all) k: '',
    });

    await rc.setConfigSettings(
      RemoteConfigSettings(
        fetchTimeout: fetchTimeout,
        minimumFetchInterval:
            kDebugMode ? Duration.zero : const Duration(hours: 1),
      ),
    );

    // Use last-fetched values immediately so offline / slow networks don't block.
    try {
      await rc.activate();
    } catch (_) {}

    Object? fetchError;
    try {
      // Dart timeout as a hard ceiling — FlutterFire fetchTimeout is not always reliable.
      await rc.fetchAndActivate().timeout(fetchTimeout);
    } on TimeoutException catch (e) {
      fetchError = e;
      debugPrint(
        '[AppUpdateGate] fetch timed out after $fetchTimeout; using cached/defaults',
      );
    } catch (e) {
      fetchError = e;
      debugPrint('[AppUpdateGate] fetch failed; using cached/defaults: $e');
    }

    final minimumRaw = rc.getString(minimumVersionKey).trim();
    debugPrint('[AppUpdateGate] minimumRaw: $minimumRaw');
    final result = _evaluate(
      currentRaw: currentRaw,
      minimumRaw: minimumRaw,
      minimumVersionKey: minimumVersionKey,
      error: fetchError,
    );
    debugPrint('[AppUpdateGate] needs: ${result.needsUpdate}');
    return result;
  } catch (e, st) {
    debugPrint('[AppUpdateGate] Remote Config / version check failed: $e');
    debugPrint('$st');
    return AppUpdateGateResult(
      needsUpdate: false,
      currentVersion: currentRaw,
      error: e,
    );
  }
}
