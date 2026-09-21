import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;

import 'toukh_remote_config_keys.dart';

/// Replace placeholders with your live store listings before shipping.
abstract final class ToukhStoreListings {
  ToukhStoreListings._();

  // TODO: set real Android applicationId / Play package name for each app.
  static const String _playPackageToukhClient = 'com.toukh.toukh';
  static const String _playPackageToukhDelivery = 'com.toukh.delivery';
  static const String _playPackageToukhProvider = 'com.toukh.provider.toukh_provider';

  // TODO: set real Apple App Store numeric IDs (or full https URLs) for each app.
  static const String _appStoreIdToukhClient = '0000000000';
  static const String _appStoreIdToukhDelivery = '0000000000';
  static const String _appStoreIdToukhProvider = '0000000000';

  static Uri playStoreUri(String packageName) => Uri.parse(
        'https://play.google.com/store/apps/details?id=$packageName',
      );

  static Uri appStoreUri(String appStoreId) =>
      Uri.parse('https://apps.apple.com/app/id$appStoreId');

  /// Resolves the store listing for the current platform from [minimumVersionKey].
  ///
  /// Throws [ArgumentError] if [minimumVersionKey] is not one of
  /// [ToukhRemoteConfigKeys] values.
  static Uri resolveStoreUriForRemoteConfigKey(String minimumVersionKey) {
    final playPackage = switch (minimumVersionKey) {
      ToukhRemoteConfigKeys.toukhClientVersion => _playPackageToukhClient,
      ToukhRemoteConfigKeys.toukhDeliveryVersion => _playPackageToukhDelivery,
      ToukhRemoteConfigKeys.toukhProviderVersion => _playPackageToukhProvider,
      _ => throw ArgumentError.value(
          minimumVersionKey,
          'minimumVersionKey',
          'Unknown Remote Config key',
        ),
    };
    final appStoreId = switch (minimumVersionKey) {
      ToukhRemoteConfigKeys.toukhClientVersion => _appStoreIdToukhClient,
      ToukhRemoteConfigKeys.toukhDeliveryVersion => _appStoreIdToukhDelivery,
      ToukhRemoteConfigKeys.toukhProviderVersion => _appStoreIdToukhProvider,
      _ => throw ArgumentError.value(
          minimumVersionKey,
          'minimumVersionKey',
          'Unknown Remote Config key',
        ),
    };

    if (kIsWeb) {
      // Web: default to Play Store listing (adjust if you ship a web storefront).
      return playStoreUri(playPackage);
    }
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return appStoreUri(appStoreId);
    }
    return playStoreUri(playPackage);
  }
}
