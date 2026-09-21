/// Compile-time product feature switches shared by consumer / delivery / provider.
abstract final class ToukhFeatureFlags {
  ToukhFeatureFlags._();

  /// When false, hide wallet screens, nav tiles, dashboard cards, and
  /// wallet as a checkout/payment option. Backend wallet code stays intact.
  static const bool walletEnabled = false;
}
