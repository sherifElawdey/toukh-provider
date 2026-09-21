/// Firebase Remote Config parameter keys for minimum supported app versions.
abstract final class ToukhRemoteConfigKeys {
  ToukhRemoteConfigKeys._();

  static const toukhClientVersion = 'toukh_client_version';
  static const toukhDeliveryVersion = 'toukh_delivery_version';
  static const toukhProviderVersion = 'toukh_provider_version';

  static const Set<String> all = {
    toukhClientVersion,
    toukhDeliveryVersion,
    toukhProviderVersion,
  };
}
