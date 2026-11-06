import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:toukh_provider/domain/repositories/app_settings_repository.dart';
import 'package:toukh_ui/toukh_ui.dart';

class FirestoreAppSettingsRepository implements AppSettingsRepository {
  FirestoreAppSettingsRepository(this._fs);

  final FirebaseFirestore _fs;

  DocumentReference<Map<String, dynamic>> get _global => _fs
      .collection(ToukhFirestoreCollections.appSettings)
      .doc(ToukhFirestoreDocs.appSettingsGlobal);

  // The three watchers below read one doc and are called from build(), so
  // they share a single listener instead of opening one per call.
  late final _globalDoc = ToukhSharedStream<Map<String, dynamic>?>(
    () => _global.snapshots().map((snap) => snap.data()),
  );

  @override
  Stream<OrderAcceptanceSla> watchAcceptanceSla() {
    return _globalDoc.stream.map(
          (data) => OrderAcceptanceSla.fromFirestore(
            data?['orderAcceptanceSla'] as Map<String, dynamic>?,
          ),
        );
  }

  @override
  Stream<DispatchSettings> watchDispatchSettings() {
    return _globalDoc.stream.map(
          (data) => DispatchSettings.fromMap(
            data?['dispatchSettings'] as Map<String, dynamic>?,
          ),
        );
  }

  @override
  Stream<WalletBalanceLimits> watchWalletBalanceLimits() {
    return _globalDoc.stream.map(
          (data) => WalletBalanceLimits.fromMap(
            data?[WalletBalanceLimits.firestoreKey] as Map<String, dynamic>?,
          ),
        );
  }
}
