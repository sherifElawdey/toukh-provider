import 'package:equatable/equatable.dart';
import 'package:toukh_provider/domain/entities/provider_account_status.dart';
import 'package:toukh_ui/toukh_ui.dart';

/// A courier fleet account (`deliveryCompanies/{uid}`).
///
/// Lives outside `providers/` so the customer app never lists it. Status moves
/// unverified → active server-side (`activateDeliveryCompany`) once the phone
/// is verified.
class DeliveryCompany extends Equatable {
  const DeliveryCompany({
    required this.uid,
    required this.companyName,
    required this.managerName,
    required this.phone,
    required this.email,
    required this.phoneVerified,
    required this.status,
    required this.lat,
    required this.lng,
    required this.address,
    this.city,
    this.serviceAreaId,
    this.serviceAreaName,
    this.createdAt,
    this.updatedAt,
  });

  final String uid;
  final String companyName;
  final String managerName;

  /// Digits only, as stored on providers.
  final String phone;
  final String email;
  final bool phoneVerified;
  final ProviderAccountStatus status;

  final double lat;
  final double lng;
  final String address;
  final String? city;
  final String? serviceAreaId;
  final String? serviceAreaName;

  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool get isActive => status == ProviderAccountStatus.active;

  DeliveryCompany copyWith({bool? phoneVerified}) {
    return DeliveryCompany(
      uid: uid,
      companyName: companyName,
      managerName: managerName,
      phone: phone,
      email: email,
      phoneVerified: phoneVerified ?? this.phoneVerified,
      status: status,
      lat: lat,
      lng: lng,
      address: address,
      city: city,
      serviceAreaId: serviceAreaId,
      serviceAreaName: serviceAreaName,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  /// Registration payload (timestamps added by the repository). Status is
  /// always `unverified` from the app.
  Map<String, dynamic> toCreateMap() => {
    'uid': uid,
    'companyName': companyName,
    'managerName': managerName,
    'phone': phone,
    'email': email,
    'phoneVerified': false,
    'status': ProviderAccountStatus.unverified.wireValue,
    'lat': lat,
    'lng': lng,
    'address': address,
    if (city != null) 'city': city,
    if (serviceAreaId != null) 'serviceAreaId': serviceAreaId,
    if (serviceAreaName != null) 'serviceAreaName': serviceAreaName,
  };

  factory DeliveryCompany.fromFirestore(String uid, Map<String, dynamic> d) {
    String? s(Object? v) =>
        v is String && v.trim().isNotEmpty ? v.trim() : null;
    return DeliveryCompany(
      uid: uid,
      companyName: s(d['companyName']) ?? '',
      managerName: s(d['managerName']) ?? '',
      phone: s(d['phone']) ?? '',
      email: s(d['email']) ?? '',
      phoneVerified: d['phoneVerified'] as bool? ?? false,
      status:
          ProviderAccountStatus.tryParse(s(d['status'])) ??
          ProviderAccountStatus.unverified,
      lat: (d['lat'] as num?)?.toDouble() ?? 0,
      lng: (d['lng'] as num?)?.toDouble() ?? 0,
      address: s(d['address']) ?? '',
      city: s(d['city']),
      serviceAreaId: s(d['serviceAreaId']),
      serviceAreaName: s(d['serviceAreaName']),
      createdAt: ToukhFirestoreTimestamps.toDateTime(d['createdAt']),
      updatedAt: ToukhFirestoreTimestamps.toDateTime(d['updatedAt']),
    );
  }

  @override
  List<Object?> get props => [
    uid,
    companyName,
    managerName,
    phone,
    email,
    phoneVerified,
    status,
    lat,
    lng,
    address,
    city,
    serviceAreaId,
    serviceAreaName,
  ];
}
