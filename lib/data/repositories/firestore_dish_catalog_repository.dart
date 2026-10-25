import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:toukh_provider/domain/repositories/dish_catalog_repository.dart';
import 'package:toukh_ui/toukh_ui.dart';

class FirestoreDishCatalogRepository implements DishCatalogRepository {
  FirestoreDishCatalogRepository(this._firestore);

  final FirebaseFirestore _firestore;

  @override
  Stream<List<DishCatalogProduct>> watchActive() {
    return _firestore
        .collection(ToukhFirestoreCollections.dishCatalog)
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((d) => DishCatalogProduct.fromFirestore(d.id, d.data()))
              .toList()
            ..sort(DishCatalogProduct.compare),
        );
  }
}
