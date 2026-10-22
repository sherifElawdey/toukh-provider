import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:toukh_provider/domain/repositories/supermarket_catalog_repository.dart';
import 'package:toukh_ui/toukh_ui.dart';

class FirestoreSupermarketCatalogRepository implements SupermarketCatalogRepository {
  FirestoreSupermarketCatalogRepository(this._firestore);

  final FirebaseFirestore _firestore;

  @override
  Stream<List<SupermarketCatalogProduct>> watchActive() {
    return _firestore
        .collection(ToukhFirestoreCollections.supermarketCatalog)
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((d) => SupermarketCatalogProduct.fromFirestore(d.id, d.data()))
              .toList()
            ..sort(SupermarketCatalogProduct.compare),
        );
  }

  @override
  Future<SupermarketCatalogProduct?> getById(String id) async {
    final doc = await _firestore
        .collection(ToukhFirestoreCollections.supermarketCatalog)
        .doc(id)
        .get();
    final data = doc.data();
    return data == null ? null : SupermarketCatalogProduct.fromFirestore(doc.id, data);
  }
}
