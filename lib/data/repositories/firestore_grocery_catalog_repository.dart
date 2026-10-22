import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:toukh_provider/domain/repositories/grocery_catalog_repository.dart';
import 'package:toukh_ui/toukh_ui.dart';

class FirestoreGroceryCatalogRepository implements GroceryCatalogRepository {
  FirestoreGroceryCatalogRepository(this._firestore);

  final FirebaseFirestore _firestore;

  @override
  Stream<List<GroceryCatalogProduct>> watchActive() {
    return _firestore
        .collection(ToukhFirestoreCollections.groceryCatalog)
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((d) => GroceryCatalogProduct.fromFirestore(d.id, d.data()))
              .toList()
            ..sort(GroceryCatalogProduct.compare),
        );
  }

  @override
  Future<GroceryCatalogProduct?> getById(String id) async {
    final doc = await _firestore
        .collection(ToukhFirestoreCollections.groceryCatalog)
        .doc(id)
        .get();
    final data = doc.data();
    return data == null ? null : GroceryCatalogProduct.fromFirestore(doc.id, data);
  }
}
