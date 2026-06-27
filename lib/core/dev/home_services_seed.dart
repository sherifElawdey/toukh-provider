import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:toukh_provider/data/repositories/firestore_home_service_categories_repository.dart';

/// Sample documents for Firestore collection [FirestoreHomeServiceCategoriesRepository.collectionName].
///
/// Document id and `id` field use the same slug (e.g. `plumber`) so
/// `providers.serviceCategoryId` matches toukh client queries via `hs_<slug>`.
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
    'plumber': {
      'id': 'plumber',
      'title': 'سباك',
      'description':
          'إصلاح التسريبات، تركيب وصيانة مواسير المياه، فتح الانسدادات، وخدمات الحمام والمطبخ.',
      'imageUrl': 'https://picsum.photos/seed/toukhplumber/400/400',
      'isActive': true,
    },
    'electrician': {
      'id': 'electrician',
      'title': 'كهربائي',
      'description':
          'إصلاح الأعطال الكهربائية، تركيب الإنارة والمفاتيح، صيانة اللوحات الكهربائية، وضمان السلامة.',
      'imageUrl': 'https://picsum.photos/seed/toukhelectrician/400/400',
      'isActive': true,
    },
    'painter': {
      'id': 'painter',
      'title': 'دهان',
      'description':
          'دهانات داخلية وخارجية، معالجة الجدران، وتشطيبات احترافية للمنازل والمكاتب.',
      'imageUrl': 'https://picsum.photos/seed/toukhpainter/400/400',
      'isActive': true,
    },
    'carpenter': {
      'id': 'carpenter',
      'title': 'نجار',
      'description':
          'تركيب وصيانة الأثاث الخشبي، الأبواب والشبابيك، والإصلاحات النجارية للمنزل.',
      'imageUrl': 'https://picsum.photos/seed/toukhcarpenter/400/400',
      'isActive': true,
    },
    'nurse': {
      'id': 'nurse',
      'title': 'ممرض / ممرضة',
      'description':
          'رعاية صحية منزلية، قياس العلامات الحيوية، متابعة بعد العمليات، ورعاية كبار السن.',
      'imageUrl': 'https://picsum.photos/seed/toukhnurse/400/400',
      'isActive': true,
    },
    'ac_technician': {
      'id': 'ac_technician',
      'title': 'فني تكييف',
      'description':
          'تركيب وصيانة أجهزة التكييف، تنظيف الفلاتر، تعبئة الغاز، وتشخيص الأعطال.',
      'imageUrl': 'https://picsum.photos/seed/toukhac/400/400',
      'isActive': true,
    },
    'pickup_truck': {
      'id': 'pickup_truck',
      'title': 'نقل عفش (بيك أب)',
      'description':
          'نقل الأثاث والبضائع بسيارات بيك أب، تحميل وتفريغ آمن داخل المدينة.',
      'imageUrl': 'https://picsum.photos/seed/toukhpickup/400/400',
      'isActive': true,
    },
    'private_car': {
      'id': 'private_car',
      'title': 'سيارة خاصة',
      'description':
          'خدمة نقل خاص بالسيارة للرحلات داخل المدينة أو بين المناطق بأسعار مرنة.',
      'imageUrl': 'https://picsum.photos/seed/toukhprivatecar/400/400',
      'isActive': true,
    },
    'home_appliances': {
      'id': 'home_appliances',
      'title': 'أجهزة كهربائية ومنزلية',
      'description':
          'صيانة وتركيب الأجهزة المنزلية: غسالات، ثلاجات، بوتاجازات، وسخانات.',
      'imageUrl': 'https://picsum.photos/seed/toukhappliances/400/400',
      'isActive': true,
    },
    'tv_repair': {
      'id': 'tv_repair',
      'title': 'صيانة رسيفرات وشاشات',
      'description':
          'إصلاح شاشات التلفزيون والرسيفر، ضبط القنوات، وصيانة أجهزة العرض.',
      'imageUrl': 'https://picsum.photos/seed/toukhtv/400/400',
      'isActive': true,
    },
  };

  onProgress?.call('Writing ${samples.length} HomeServices documents…');
  for (final e in samples.entries) {
    await col.doc(e.key).set(e.value, SetOptions(merge: true));
  }
  onProgress?.call('HomeServices seed complete.');
}
