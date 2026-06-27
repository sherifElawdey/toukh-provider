import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:toukh_provider/core/constants/app_constants.dart';
import 'package:toukh_provider/core/utils/phone_auth_helpers.dart';
import 'package:toukh_provider/domain/entities/delivery_config.dart';
import 'package:toukh_provider/domain/entities/menu_item.dart';
import 'package:toukh_provider/domain/entities/provider_account_status.dart';
import 'package:toukh_provider/domain/entities/provider_kind.dart';
import 'package:toukh_provider/domain/entities/provider_profile.dart';
import 'package:toukh_provider/domain/entities/shop_category.dart';
import 'package:toukh_provider/domain/entities/working_hours.dart';
import 'package:toukh_provider/data/repositories/firestore_provider_menu_repository.dart';

/// Password for all seeded provider accounts (matches CLI seed tool).
const String kProviderSeedPassword = '1234567890';

const String kSeedBrandImageUrl =
    'https://picsum.photos/seed/toukhbbrand/800/600';
const String kSeedIdFrontUrl =
    'https://picsum.photos/seed/toukhidfront/600/400';
const String kSeedIdBackUrl =
    'https://picsum.photos/seed/toukhidback/600/400';

List<String> portfolioUrlsForSeed(String seed) => [
      'https://picsum.photos/seed/${seed}a/800/600',
      'https://picsum.photos/seed/${seed}b/800/600',
      'https://picsum.photos/seed/${seed}c/800/600',
      'https://picsum.photos/seed/${seed}d/800/600',
    ];

/// Creates or updates the 12 demo provider accounts (Auth + Firestore).
///
/// Signs out after each account write (same as CLI). Final state is signed out.
Future<void> seedProviderAccounts({
  required FirebaseAuth auth,
  required FirebaseFirestore firestore,
  void Function(String message)? onProgress,
}) async {
  final defs = seedAccountDefinitions();
  onProgress?.call('Seeding ${defs.length} accounts…');
  for (final def in defs) {
    await _seedOneAccount(
      auth: auth,
      firestore: firestore,
      def: def,
      onProgress: onProgress,
    );
  }
  await auth.signOut();
  onProgress?.call('Done.');
}

Map<Weekday, DaySchedule> cairoWorkingWeekSeed() {
  const open = DaySchedule(
    enabled: true,
    twentyFourHours: false,
    openFromMinutes: 9 * 60,
    openToMinutes: 22 * 60,
  );
  const closed = DaySchedule(
    enabled: false,
    twentyFourHours: false,
    openFromMinutes: 0,
    openToMinutes: 0,
  );
  return {
    Weekday.mon: open,
    Weekday.tue: open,
    Weekday.wed: open,
    Weekday.thu: open,
    Weekday.fri: open,
    Weekday.sat: open,
    Weekday.sun: closed,
  };
}

/// Same rows as [tool/seed_providers.dart] — single source of truth for demos.
List<SeedAccountDefinition> seedAccountDefinitions() {
  final wh = cairoWorkingWeekSeed();
  const cairoLat = 30.0444;
  const cairoLng = 31.2357;
  const addr = 'Tahrir Square area, Cairo, Egypt';

  DeliveryConfig shopDelivery() => const DeliveryConfig(
        offersDelivery: true,
        isFree: true,
        avgPrepMinutes: 25,
      );

  MenuItemEntity dish(String idPrefix, String name, String cat, double p1,
      [double? p2]) {
    return MenuItemEntity(
      id: idPrefix,
      name: name,
      description: 'Seeded demo item',
      category: cat,
      imageUrl: 'https://picsum.photos/seed/${idPrefix}img/400/300',
      sizes: p2 == null
          ? [MenuItemSize(label: 'Regular', priceEgp: p1)]
          : [
              MenuItemSize(label: 'Regular', priceEgp: p1),
              MenuItemSize(label: 'Large', priceEgp: p2),
            ],
    );
  }

  final menuNile = [
    dish('nile_foul', 'Classic foul', 'Breakfast', 35, 55),
    dish('nile_falafel', 'Ta\'ameya plate', 'Breakfast', 40),
    dish('nile_feteer', 'Feteer meshaltet', 'Mains', 75, 110),
    dish('nile_koshari', 'Koshari', 'Mains', 45),
    dish('nile_juice', 'Fresh mango juice', 'Drinks', 45),
    dish('nile_sobia', 'Sobia', 'Drinks', 25),
  ];

  final menuOasis = [
    dish('oasis_grill', 'Mixed grill platter', 'Mains', 185, 240),
    dish('oasis_burger', 'Beef burger', 'Mains', 95, 120),
    dish('oasis_salad', 'Greek salad', 'Salads', 65),
    dish('oasis_soup', 'Lentil soup', 'Starters', 45),
    dish('oasis_kunafa', 'Kunafa cream', 'Desserts', 85),
    dish('oasis_mojito', 'Lemon mint cooler', 'Drinks', 40),
  ];

  return [
    SeedAccountDefinition(
      label: 'Restaurant · Nile',
      phoneDigits: '01234567891',
      serviceType: ServiceType.restaurant,
      shopCategory: ShopCategory.restaurant,
      workingHours: wh,
      lat: cairoLat,
      lng: cairoLng,
      formattedAddress: addr,
      businessName: 'Nile Street Kitchen',
      description: 'Homestyle Egyptian breakfast and lunch.',
      deliveryConfig: shopDelivery(),
      avgPrepMinutes: 20,
      menuItems: menuNile,
      portfolioImageUrls: null,
    ),
    SeedAccountDefinition(
      label: 'Restaurant · Oasis',
      phoneDigits: '01234567892',
      serviceType: ServiceType.restaurant,
      shopCategory: ShopCategory.restaurant,
      workingHours: wh,
      lat: cairoLat,
      lng: cairoLng,
      formattedAddress: addr,
      businessName: 'Oasis Grill House',
      description: 'Grills, salads, and desserts for the family.',
      deliveryConfig: shopDelivery(),
      avgPrepMinutes: 30,
      menuItems: menuOasis,
      portfolioImageUrls: null,
    ),
    SeedAccountDefinition(
      label: 'Supermarket · Fresh',
      phoneDigits: '01234567893',
      serviceType: ServiceType.restaurant,
      shopCategory: ShopCategory.supermarket,
      workingHours: wh,
      lat: cairoLat,
      lng: cairoLng,
      formattedAddress: addr,
      businessName: 'Fresh Cart Supermarket',
      description: 'Groceries and daily essentials.',
      deliveryConfig: shopDelivery(),
      portfolioImageUrls: portfolioUrlsForSeed('supa'),
    ),
    SeedAccountDefinition(
      label: 'Supermarket · Metro',
      phoneDigits: '01234567894',
      serviceType: ServiceType.restaurant,
      shopCategory: ShopCategory.supermarket,
      workingHours: wh,
      lat: cairoLat,
      lng: cairoLng,
      formattedAddress: addr,
      businessName: 'Metro Foods Market',
      description: 'Imported goods and local produce.',
      deliveryConfig: shopDelivery(),
      portfolioImageUrls: portfolioUrlsForSeed('supb'),
    ),
    SeedAccountDefinition(
      label: 'Pharmacy · Care',
      phoneDigits: '01234567895',
      serviceType: ServiceType.restaurant,
      shopCategory: ShopCategory.pharmacy,
      workingHours: wh,
      lat: cairoLat,
      lng: cairoLng,
      formattedAddress: addr,
      businessName: 'Care Pharmacy',
      description: 'OTC medicines and personal care.',
      deliveryConfig: shopDelivery(),
      portfolioImageUrls: portfolioUrlsForSeed('pharma'),
    ),
    SeedAccountDefinition(
      label: 'Pharmacy · Vital',
      phoneDigits: '01234567896',
      serviceType: ServiceType.restaurant,
      shopCategory: ShopCategory.pharmacy,
      workingHours: wh,
      lat: cairoLat,
      lng: cairoLng,
      formattedAddress: addr,
      businessName: 'Vital Care Pharmacy',
      description: 'Prescription support and wellness.',
      deliveryConfig: shopDelivery(),
      portfolioImageUrls: portfolioUrlsForSeed('pharmb'),
    ),
    SeedAccountDefinition(
      label: 'Grocery · Green',
      phoneDigits: '01234567897',
      serviceType: ServiceType.restaurant,
      shopCategory: ShopCategory.fruitVeg,
      workingHours: wh,
      lat: cairoLat,
      lng: cairoLng,
      formattedAddress: addr,
      businessName: 'Green Basket Produce',
      description: 'Fresh fruits and vegetables daily.',
      deliveryConfig: shopDelivery(),
      portfolioImageUrls: portfolioUrlsForSeed('veg'),
    ),
    SeedAccountDefinition(
      label: 'Grocery · Harvest',
      phoneDigits: '01234567898',
      serviceType: ServiceType.restaurant,
      shopCategory: ShopCategory.fruitVeg,
      workingHours: wh,
      lat: cairoLat,
      lng: cairoLng,
      formattedAddress: addr,
      businessName: 'Harvest Corner',
      description: 'Seasonal produce and herbs.',
      deliveryConfig: shopDelivery(),
      portfolioImageUrls: portfolioUrlsForSeed('vegb'),
    ),
    SeedAccountDefinition(
      label: 'Home · Plumber',
      phoneDigits: '01234567899',
      serviceType: ServiceType.homeService,
      serviceCategoryId: 'plumber',
      workingHours: wh,
      lat: cairoLat,
      lng: cairoLng,
      formattedAddress: addr,
      businessName: 'ClearFlow Plumbing',
      description: 'Leaks, installations, and maintenance.',
      deliveryConfig: const DeliveryConfig(offersDelivery: false, isFree: true),
      portfolioImageUrls: portfolioUrlsForSeed('plumb'),
    ),
    SeedAccountDefinition(
      label: 'Home · Electrician',
      phoneDigits: '01234567900',
      serviceType: ServiceType.homeService,
      serviceCategoryId: 'electrician',
      workingHours: wh,
      lat: cairoLat,
      lng: cairoLng,
      formattedAddress: addr,
      businessName: 'SafeWire Electrical',
      description: 'Repairs, fixtures, and safety checks.',
      deliveryConfig: const DeliveryConfig(offersDelivery: false, isFree: true),
      portfolioImageUrls: portfolioUrlsForSeed('elec'),
    ),
    SeedAccountDefinition(
      label: 'Home · AC Technician',
      phoneDigits: '01234567901',
      serviceType: ServiceType.homeService,
      serviceCategoryId: 'ac_technician',
      workingHours: wh,
      lat: cairoLat,
      lng: cairoLng,
      formattedAddress: addr,
      businessName: 'CoolAir Service',
      description: 'Split-unit maintenance and gas refill.',
      deliveryConfig: const DeliveryConfig(offersDelivery: false, isFree: true),
      portfolioImageUrls: portfolioUrlsForSeed('ac'),
    ),
    SeedAccountDefinition(
      label: 'Home · Nurse',
      phoneDigits: '01234567902',
      serviceType: ServiceType.homeService,
      serviceCategoryId: 'nurse',
      workingHours: wh,
      lat: cairoLat,
      lng: cairoLng,
      formattedAddress: addr,
      businessName: 'HomeCare Nursing',
      description: 'At-home nursing and elder care.',
      deliveryConfig: const DeliveryConfig(offersDelivery: false, isFree: true),
      portfolioImageUrls: portfolioUrlsForSeed('nurse'),
    ),
  ];
}

Future<void> _seedOneAccount({
  required FirebaseAuth auth,
  required FirebaseFirestore firestore,
  required SeedAccountDefinition def,
  void Function(String message)? onProgress,
}) async {
  final email = syntheticEmailFromPhone(def.phoneDigits);
  final phone = displayDigits(def.phoneDigits);

  UserCredential? cred;
  try {
    cred = await auth.createUserWithEmailAndPassword(
      email: email,
      password: kProviderSeedPassword,
    );
  } on FirebaseAuthException catch (e) {
    if (e.code == 'email-already-in-use') {
      onProgress?.call('${def.label}: refresh Firestore');
      cred = await auth.signInWithEmailAndPassword(
        email: email,
        password: kProviderSeedPassword,
      );
    } else {
      rethrow;
    }
  }

  final uid = cred.user!.uid;
  final now = DateTime.now();

  final profile = ProviderProfile(
    uid: uid,
    phone: phone,
    email: email,
    password: kProviderSeedPassword,
    phoneVerified: true,
    serviceType: def.serviceType,
    shopCategory: def.shopCategory,
    serviceCategoryId: def.serviceCategoryId,
    name: def.businessName,
    description: def.description,
    brandImageUrl: kSeedBrandImageUrl,
    idFrontUrl: kSeedIdFrontUrl,
    idBackUrl: kSeedIdBackUrl,
    lat: def.lat,
    lng: def.lng,
    address: def.formattedAddress,
    city: def.city ?? 'cairo',
    workingHours: def.workingHours,
    deliveryConfig: def.deliveryConfig,
    avgPrepMinutes: def.avgPrepMinutes,
    portfolioImageUrls: def.portfolioImageUrls,
    status: ProviderAccountStatus.active,
    registrationExtrasComplete: true,
    createdAt: now,
    updatedAt: now,
  );

  await firestore
      .collection(AppConstants.providersCollection)
      .doc(uid)
      .set(profile.toFirestore(), SetOptions(merge: true));

  if (def.menuItems != null && def.menuItems!.isNotEmpty) {
    await _seedMenuSubcollection(
      firestore: firestore,
      providerId: uid,
      items: def.menuItems!,
    );
  }

  onProgress?.call('${def.label} ok');
  await auth.signOut();
}

Future<void> _seedMenuSubcollection({
  required FirebaseFirestore firestore,
  required String providerId,
  required List<MenuItemEntity> items,
}) async {
  final menuCol =
      firestore.collection(AppConstants.providersCollection).doc(providerId).collection('Menu');
  final existing = await menuCol.get();
  for (final cat in existing.docs) {
    final itemDocs = await cat.reference.collection('items').get();
    for (final doc in itemDocs.docs) {
      await doc.reference.delete();
    }
    await cat.reference.delete();
  }

  final menuRepo = FirestoreProviderMenuRepository(firestore);
  final categories = <String>{};
  for (final item in items) {
    final c = item.category?.trim();
    if (c != null && c.isNotEmpty) categories.add(c);
  }
  if (categories.isEmpty) categories.add('General');
  for (final c in categories) {
    await menuRepo.upsertCategory(providerId, c);
  }
  for (final item in items) {
    await menuRepo.upsertItem(providerId, item);
  }
}

class SeedAccountDefinition {
  const SeedAccountDefinition({
    required this.label,
    required this.phoneDigits,
    required this.serviceType,
    this.shopCategory,
    this.serviceCategoryId,
    required this.workingHours,
    required this.lat,
    required this.lng,
    required this.formattedAddress,
    this.city,
    required this.businessName,
    required this.description,
    required this.deliveryConfig,
    this.avgPrepMinutes,
    this.menuItems,
    this.portfolioImageUrls,
  });

  final String label;
  final String phoneDigits;
  final ServiceType serviceType;
  final ShopCategory? shopCategory;
  final String? serviceCategoryId;
  final Map<Weekday, DaySchedule> workingHours;
  final double lat;
  final double lng;
  final String formattedAddress;
  final String? city;
  final String businessName;
  final String description;
  final DeliveryConfig deliveryConfig;
  final int? avgPrepMinutes;
  final List<MenuItemEntity>? menuItems;
  final List<String>? portfolioImageUrls;
}
