/// Static configuration for the Backblaze B2 native API client.
///
/// SECURITY:
/// The credentials below are embedded in the shipped app binary. They belong
/// to a *Master Application Key* with full account privileges. Anyone able to
/// extract the APK/IPA (trivial for an attacker) will be able to:
///   - list / read / delete / overwrite ANY file in ANY bucket on the account,
///   - create and revoke application keys,
///   - delete the whole account.
///
/// Before going to production, replace this with a **per-bucket application
/// key** (scope limited to `toukh1` and capabilities limited to
/// `listFiles,readFiles,writeFiles,shareFiles,deleteFiles`), and inject it at
/// build time via:
///
///     flutter build apk --dart-define=B2_KEY_ID=... \
///                       --dart-define=B2_APPLICATION_KEY=... \
///                       --dart-define=B2_BUCKET_NAME=...
///
/// The hard-coded defaults stay as a development fallback.
abstract final class BackblazeB2Config {
  BackblazeB2Config._();

  static const String keyId = String.fromEnvironment(
    'B2_KEY_ID',
    defaultValue: '7f0a5ef7c898',
  );

  static const String applicationKey = String.fromEnvironment(
    'B2_APPLICATION_KEY',
    defaultValue: '005df9a78939f9fdad122c0c0b37916e350deca536',
  );

  /// Bucket that receives driver images (profile photo + ID photos).
  static const String bucketName = String.fromEnvironment(
    'B2_BUCKET_NAME',
    defaultValue: 'toukh1',
  );

  /// B2 native API root used by `b2_authorize_account`.
  static const String authorizeBaseUrl = 'https://api.backblazeb2.com';
}
