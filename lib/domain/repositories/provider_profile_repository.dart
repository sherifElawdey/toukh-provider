import 'package:toukh_provider/domain/entities/provider_profile.dart';

abstract class ProviderProfileRepository {
  Future<ProviderProfile?> getProfile(String uid);

  Stream<ProviderProfile?> watchProfile(String uid);

  Future<void> upsertProfile(ProviderProfile profile);

  /// Returns true if any document in [providers] has this national/E.164 digit string.
  Future<bool> existsByPhone(String phoneDigits);

  Future<void> addFcmToken({required String uid, required String token});
}
