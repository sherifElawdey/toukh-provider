import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'package:toukh_provider/domain/entities/block_info.dart';
import 'package:toukh_provider/domain/entities/delivery_config.dart';
import 'package:toukh_provider/domain/entities/menu_item.dart';
import 'package:toukh_provider/domain/entities/provider_account_status.dart';
import 'package:toukh_provider/domain/entities/provider_kind.dart';
import 'package:toukh_provider/domain/entities/shop_category.dart';
import 'package:toukh_provider/domain/entities/working_hours.dart';

class ProviderProfile extends Equatable {
  const ProviderProfile({
    required this.uid,
    required this.phone,
    required this.email,
    required this.password,
    required this.phoneVerified,
    required this.serviceType,
    this.shopCategory,
    this.serviceCategoryId,
    required this.name,
    this.description,
    this.brandImageUrl,
    this.idFrontUrl,
    this.idBackUrl,
    this.lat,
    this.lng,
    this.address,
    this.workingHours = const {},
    this.deliveryConfig,
    /// Prep time for restaurants (minutes), independent of delivery toggle.
    this.avgPrepMinutes,
    this.menuItems,
    this.portfolioImageUrls,
    required this.status,
    this.blockInfo,
    this.b2FileIds = const {},
    this.registrationExtrasComplete = false,
    this.fcmTokens = const [],
    this.walletBalanceEgp,
    this.walletPendingEgp,
    required this.createdAt,
    required this.updatedAt,
  });

  final String uid;
  final String phone;
  final String email;
  final String password;
  final bool phoneVerified;
  final ServiceType serviceType;
  final ShopCategory? shopCategory;
  final String? serviceCategoryId;

  final String name;
  final String? description;
  final String? brandImageUrl;
  final String? idFrontUrl;
  final String? idBackUrl;

  final double? lat;
  final double? lng;
  final String? address;

  final Map<Weekday, DaySchedule> workingHours;
  final DeliveryConfig? deliveryConfig;
  final int? avgPrepMinutes;

  final List<MenuItemEntity>? menuItems;
  final List<String>? portfolioImageUrls;

  final ProviderAccountStatus status;
  final BlockInfo? blockInfo;
  final Map<String, String> b2FileIds;

  /// True after post-OTP menu or portfolio was saved.
  final bool registrationExtrasComplete;

  final List<String> fcmTokens;

  /// Settled balance shown on provider dashboard (EGP).
  final double? walletBalanceEgp;

  /// Optional pending payouts (EGP).
  final double? walletPendingEgp;

  final DateTime createdAt;
  final DateTime updatedAt;

  ProviderProfile copyWith({
    String? uid,
    String? phone,
    String? email,
    String? password,
    bool? phoneVerified,
    ServiceType? serviceType,
    ShopCategory? shopCategory,
    String? serviceCategoryId,
    String? name,
    String? description,
    String? brandImageUrl,
    String? idFrontUrl,
    String? idBackUrl,
    double? lat,
    double? lng,
    String? address,
    Map<Weekday, DaySchedule>? workingHours,
    DeliveryConfig? deliveryConfig,
    int? avgPrepMinutes,
    List<MenuItemEntity>? menuItems,
    List<String>? portfolioImageUrls,
    ProviderAccountStatus? status,
    BlockInfo? blockInfo,
    Map<String, String>? b2FileIds,
    bool? registrationExtrasComplete,
    List<String>? fcmTokens,
    double? walletBalanceEgp,
    double? walletPendingEgp,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ProviderProfile(
      uid: uid ?? this.uid,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      password: password ?? this.password,
      phoneVerified: phoneVerified ?? this.phoneVerified,
      serviceType: serviceType ?? this.serviceType,
      shopCategory: shopCategory ?? this.shopCategory,
      serviceCategoryId: serviceCategoryId ?? this.serviceCategoryId,
      name: name ?? this.name,
      description: description ?? this.description,
      brandImageUrl: brandImageUrl ?? this.brandImageUrl,
      idFrontUrl: idFrontUrl ?? this.idFrontUrl,
      idBackUrl: idBackUrl ?? this.idBackUrl,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      address: address ?? this.address,
      workingHours: workingHours ?? this.workingHours,
      deliveryConfig: deliveryConfig ?? this.deliveryConfig,
      avgPrepMinutes: avgPrepMinutes ?? this.avgPrepMinutes,
      menuItems: menuItems ?? this.menuItems,
      portfolioImageUrls: portfolioImageUrls ?? this.portfolioImageUrls,
      status: status ?? this.status,
      blockInfo: blockInfo ?? this.blockInfo,
      b2FileIds: b2FileIds ?? this.b2FileIds,
      registrationExtrasComplete:
          registrationExtrasComplete ?? this.registrationExtrasComplete,
      fcmTokens: fcmTokens ?? this.fcmTokens,
      walletBalanceEgp: walletBalanceEgp ?? this.walletBalanceEgp,
      walletPendingEgp: walletPendingEgp ?? this.walletPendingEgp,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toFirestore() {
    final wh = <String, dynamic>{};
    for (final e in workingHours.entries) {
      wh[e.key.wireValue] = e.value.toMap();
    }
    return {
      'phone': phone,
      'email': email,
      'password': password,
      'phoneVerified': phoneVerified,
      'serviceType': serviceType.wireValue,
      if (shopCategory != null) 'shopCategory': shopCategory!.wireValue,
      if (serviceCategoryId != null) 'serviceCategoryId': serviceCategoryId,
      'name': name,
      if (description != null) 'description': description,
      if (brandImageUrl != null) 'brandImageUrl': brandImageUrl,
      if (idFrontUrl != null) 'idFrontUrl': idFrontUrl,
      if (idBackUrl != null) 'idBackUrl': idBackUrl,
      if (lat != null) 'lat': lat,
      if (lng != null) 'lng': lng,
      if (address != null) 'address': address,
      'workingHours': wh,
      if (deliveryConfig != null) 'deliveryConfig': deliveryConfig!.toFirestore(),
      if (avgPrepMinutes != null) 'avgPrepMinutes': avgPrepMinutes,
      // Menu items live under providers/{id}/Menu/{category}/items/{itemId}.
      if (portfolioImageUrls != null) 'portfolioImageUrls': portfolioImageUrls,
      'status': status.wireValue,
      if (blockInfo != null) 'blockInfo': blockInfo!.toFirestore(),
      if (b2FileIds.isNotEmpty) 'b2FileIds': b2FileIds,
      'registrationExtrasComplete': registrationExtrasComplete,
      if (fcmTokens.isNotEmpty) 'fcmTokens': fcmTokens,
      if (walletBalanceEgp != null) 'walletBalanceEgp': walletBalanceEgp,
      if (walletPendingEgp != null) 'walletPendingEgp': walletPendingEgp,
      // 'providerId': uid,
      'id': uid,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  static ProviderProfile fromFirestore(String? uid, Map<String, dynamic> data) {
    final whRaw = data['workingHours'] as Map<String, dynamic>? ?? {};
    final wh = <Weekday, DaySchedule>{};
    for (final e in whRaw.entries) {
      final day = Weekday.tryParse(e.key);
      if (day != null) {
        wh[day] = DaySchedule.fromMap(Map<String, dynamic>.from(e.value as Map));
      }
    }

    List<MenuItemEntity>? menuItems;
    final mi = data['menuItems'] as List<dynamic>?;
    if (mi != null) {
      menuItems = mi
          .map((e) => MenuItemEntity.fromFirestore(
                Map<String, dynamic>.from(e as Map),
              ))
          .toList();
    }

    final createdTs = data['createdAt'];
    final updatedTs = data['updatedAt'];
    final createdAt = createdTs is Timestamp
        ? createdTs.toDate()
        : DateTime.now();
    final updatedAt = updatedTs is Timestamp
        ? updatedTs.toDate()
        : createdAt;

    return ProviderProfile(
      uid: uid ?? data['id'] as String? ?? data['providerId'] as String? ?? '',

      avgPrepMinutes: data['avgPrepMinutes'] as int?,
      phone: data['phone'] as String? ?? '',
      email: data['email'] as String? ?? '',
      password: data['password'] as String? ?? '',
      phoneVerified: data['phoneVerified'] as bool? ?? false,
      serviceType: ServiceType.tryParse((data['serviceType'] as String?) ??(data['kind'] as String?) ) ?? ServiceType.restaurant,
      shopCategory: ShopCategory.tryParse(data['shopCategory'] as String?),
      serviceCategoryId: data['serviceCategoryId'] as String?,
      name: data['name'] as String? ?? '',
      description: data['description'] as String?,
      brandImageUrl: data['brandImageUrl'] as String?,
      idFrontUrl: data['idFrontUrl'] as String?,
      idBackUrl: data['idBackUrl'] as String?,
      lat: (data['lat'] as num?)?.toDouble(),
      lng: (data['lng'] as num?)?.toDouble(),
      address: data['formattedAddress'] as String? ?? data['address'] as String?,
      workingHours: wh,
      deliveryConfig: DeliveryConfig.fromFirestore(
        data['deliveryConfig'] as Map<String, dynamic>?,
      ),
      menuItems: menuItems,
      portfolioImageUrls: (data['portfolioImageUrls'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      status: ProviderAccountStatus.tryParse(data['status'] as String?) ??
          ProviderAccountStatus.pending,
      blockInfo: BlockInfo.fromFirestore(
        data['blockInfo'] as Map<String, dynamic>?,
      ),
      b2FileIds: Map<String, String>.from(
        (data['b2FileIds'] as Map?)?.cast<String, String>() ?? {},
      ),
      registrationExtrasComplete:
          data['registrationExtrasComplete'] as bool? ?? false,
      fcmTokens:
          (data['fcmTokens'] as List<dynamic>?)?.map((e) => e as String).toList() ??
              const [],
      walletBalanceEgp: (data['walletBalanceEgp'] as num?)?.toDouble(),
      walletPendingEgp: (data['walletPendingEgp'] as num?)?.toDouble(),
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  bool get isRestaurantShop =>
      serviceType == ServiceType.restaurant && shopCategory == ShopCategory.restaurant;

  bool get isPharmacy =>
      serviceType == ServiceType.pharmacy ||
      shopCategory == ShopCategory.pharmacy;

  /// Display label for verification screens (matches delivery `DriverProfile`).
  String get displayName => name;

  @override
  List<Object?> get props => [
        uid,
        phone,
        email,
        password,
        phoneVerified,
    serviceType,
        shopCategory,
        serviceCategoryId,
        name,
        description,
        brandImageUrl,
        idFrontUrl,
        idBackUrl,
        lat,
        lng,
        address,
        workingHours,
        deliveryConfig,
        avgPrepMinutes,
        menuItems,
        portfolioImageUrls,
        status,
        registrationExtrasComplete,
        walletBalanceEgp,
        walletPendingEgp,
      ];
}
