import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:toukh_provider/domain/repositories/cleaning_catalog_repository.dart';
import 'package:toukh_ui/toukh_ui.dart';

class FirestoreCleaningCatalogRepository implements CleaningCatalogRepository {
  FirestoreCleaningCatalogRepository(this._firestore);

  final FirebaseFirestore _firestore;

  @override
  Stream<List<CleaningCatalogProduct>> watchActive() {
    return _firestore
        .collection(ToukhFirestoreCollections.cleaningCatalog)
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((d) => CleaningCatalogProduct.fromFirestore(d.id, d.data()))
              .toList()
            ..sort(CleaningCatalogProduct.compare),
        );
  }

  @override
  Future<CleaningCatalogProduct?> getById(String id) async {
    final doc = await _firestore
        .collection(ToukhFirestoreCollections.cleaningCatalog)
        .doc(id)
        .get();
    final data = doc.data();
    return data == null ? null : CleaningCatalogProduct.fromFirestore(doc.id, data);
  }
}
