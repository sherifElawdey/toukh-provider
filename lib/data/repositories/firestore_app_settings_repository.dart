import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:toukh_provider/domain/repositories/app_settings_repository.dart';
import 'package:toukh_ui/toukh_ui.dart';

class FirestoreAppSettingsRepository implements AppSettingsRepository {
  FirestoreAppSettingsRepository(this._fs);

  final FirebaseFirestore _fs;

  @override
  Stream<OrderAcceptanceSla> watchAcceptanceSla() {
    return _fs.collection('appSettings').doc('global').snapshots().map(
          (snap) => OrderAcceptanceSla.fromFirestore(
            snap.data()?['orderAcceptanceSla'] as Map<String, dynamic>?,
          ),
        );
  }
}
