import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:toukh_provider/domain/entities/home_service_category.dart';
import 'package:toukh_provider/domain/repositories/home_service_categories_repository.dart';

/// Firestore collection `HomeServices` (read during unauthenticated registration).
class FirestoreHomeServiceCategoriesRepository
    implements HomeServiceCategoriesRepository {
  FirestoreHomeServiceCategoriesRepository(this._firestore);

  final FirebaseFirestore _firestore;

  static const String collectionName = 'HomeServices';

  @override
  Stream<List<HomeServiceCategory>> watchActiveCategories() {
    return _firestore
        .collection(collectionName)
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snap) {
      final list = snap.docs
          .map((d) => HomeServiceCategory.fromFirestore(d.id, d.data()))
          .where((c) => c.title.isNotEmpty)
          .toList();
      list.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
      return list;
    });
  }
}
