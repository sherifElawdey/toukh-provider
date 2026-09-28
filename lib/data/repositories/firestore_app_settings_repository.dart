import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:toukh_provider/domain/repositories/app_settings_repository.dart';
import 'package:toukh_ui/toukh_ui.dart';

class FirestoreAppSettingsRepository implements AppSettingsRepository {
  FirestoreAppSettingsRepository(this._fs);

  final FirebaseFirestore _fs;

  DocumentReference<Map<String, dynamic>> get _global => _fs
      .collection(ToukhFirestoreCollections.appSettings)
      .doc(ToukhFirestoreDocs.appSettingsGlobal);

  @override
  Stream<OrderAcceptanceSla> watchAcceptanceSla() {
    return _global.snapshots().map(
          (snap) => OrderAcceptanceSla.fromFirestore(
            snap.data()?['orderAcceptanceSla'] as Map<String, dynamic>?,
          ),
        );
  }

  @override
  Stream<WalletBalanceLimits> watchWalletBalanceLimits() {
    return _global.snapshots().map(
          (snap) => WalletBalanceLimits.fromMap(
            snap.data()?[WalletBalanceLimits.firestoreKey] as Map<String, dynamic>?,
          ),
        );
  }
}
