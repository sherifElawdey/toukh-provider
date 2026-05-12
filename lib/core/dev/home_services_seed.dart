import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:toukh_provider/data/repositories/firestore_home_service_categories_repository.dart';

/// Sample documents for Firestore collection [FirestoreHomeServiceCategoriesRepository.collectionName].
///
/// **Security:** registration reads this collection while the user is **not** signed in.
/// Firestore rules must allow `read` on `HomeServices` for that flow (e.g. public read in dev).
Future<void> seedHomeServiceCategories({
  required FirebaseFirestore firestore,
  void Function(String message)? onProgress,
}) async {
  final col = firestore.collection(
    FirestoreHomeServiceCategoriesRepository.collectionName,
  );

  final samples = <String, Map<String, dynamic>>{
    'home_cat_cleaning': {
      'id': 'home_cat_cleaning',
      'title': 'Cleaning',
      'description':
          'Residential and office cleaning, deep clean, and move-out packages.',
      'imageUrl': 'https://picsum.photos/seed/toukhclean/400/400',
      'isActive': true,
    },
    'home_cat_electrical': {
      'id': 'home_cat_electrical',
      'title': 'Electrical',
      'description':
          'Wiring repairs, fixture installation, breaker issues, and safety checks.',
      'imageUrl': 'https://picsum.photos/seed/toukhelec/400/400',
      'isActive': true,
    },
    'home_cat_plumbing': {
      'id': 'home_cat_plumbing',
      'title': 'Plumbing',
      'description':
          'Leaks, clogs, water heaters, and bathroom or kitchen plumbing work.',
      'imageUrl': 'https://picsum.photos/seed/toukhplumb/400/400',
      'isActive': true,
    },
    'home_cat_ac': {
      'id': 'home_cat_ac',
      'title': 'AC & cooling',
      'description':
          'Split-unit service, maintenance, gas refill coordination, and diagnostics.',
      'imageUrl': 'https://picsum.photos/seed/toukhac/400/400',
      'isActive': true,
    },
    'home_cat_painting': {
      'id': 'home_cat_painting',
      'title': 'Painting',
      'description': 'Interior and exterior painting, prep, and touch-ups.',
      'imageUrl': 'https://picsum.photos/seed/toukhpaint/400/400',
      'isActive': true,
    },
    'home_cat_beauty': {
      'id': 'home_cat_beauty',
      'title': 'Beauty at home',
      'description':
          'Hair, nails, and skincare services at the customer location.',
      'imageUrl': 'https://picsum.photos/seed/toukhbeauty/400/400',
      'isActive': true,
    },
    'home_cat_inactive_demo': {
      'id': 'home_cat_inactive_demo',
      'title': 'Inactive demo',
      'description':
          'This row is inactive — it should not appear in the registration list.',
      'isActive': false,
    },
  };

  onProgress?.call('Writing ${samples.length} HomeServices documents…');
  for (final e in samples.entries) {
    await col.doc(e.key).set(e.value, SetOptions(merge: true));
  }
  onProgress?.call('HomeServices seed complete.');
}
