import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:toukh_provider/core/constants/app_constants.dart';
import 'package:toukh_provider/domain/entities/provider_profile.dart';
import 'package:toukh_provider/domain/repositories/provider_profile_repository.dart';
import 'package:toukh_ui/toukh_ui.dart';

class FirestoreProviderProfileRepository implements ProviderProfileRepository {
  FirestoreProviderProfileRepository(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _providers =>
      _firestore.collection(AppConstants.providersCollection);

  @override
  Future<ProviderProfile?> getProfile(String uid) async {
    final snap = await _providers.doc(uid).get();
    if (!snap.exists) return null;
    final data = snap.data();
    if (data == null) return null;
    return ProviderProfile.fromFirestore(uid, data);
  }

  @override
  Stream<ProviderProfile?> watchProfile(String uid) {
    return _providers.doc(uid).snapshots().map((snap) {
      final data = snap.data();
      if (!snap.exists || data == null) return null;
      return ProviderProfile.fromFirestore(uid, data);
    });
  }

  @override
  Future<void> upsertProfile(ProviderProfile profile) async {
    await _providers.doc(profile.uid).set(
          profile.toFirestore(),
          SetOptions(merge: true),
        );
  }

  @override
  Future<bool> existsByPhone(String phoneDigits) async {
    final q = await _providers
        .where('phone', isEqualTo: phoneDigits)
        .limit(1)
        .get();
    return q.docs.isNotEmpty;
  }

  @override
  Future<void> addFcmToken({required String uid, required String token}) async {
    if (token.isEmpty) return;
    final snap = await _providers.doc(uid).get();
    final existing =
        (snap.data()?['fcmTokens'] as List<dynamic>?)?.cast<String>() ?? [];
    if (existing.contains(token)) return;
    final merged = ToukhFcmTokenSync.mergeFcmToken(existing, token);
    await _providers.doc(uid).set(
      {
        'fcmTokens': merged,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }
}
