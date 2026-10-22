import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:toukh_provider/core/constants/app_constants.dart';
import 'package:toukh_provider/domain/entities/company_courier.dart';
import 'package:toukh_provider/domain/entities/company_courier_stats.dart';
import 'package:toukh_provider/domain/entities/delivery_company.dart';
import 'package:toukh_provider/domain/repositories/delivery_company_repository.dart';
import 'package:toukh_ui/toukh_ui.dart';

class FirestoreDeliveryCompanyRepository implements DeliveryCompanyRepository {
  FirestoreDeliveryCompanyRepository(this._firestore, this._functions);

  final FirebaseFirestore _firestore;
  final FirebaseFunctions _functions;

  CollectionReference<Map<String, dynamic>> get _companies =>
      _firestore.collection(AppConstants.deliveryCompaniesCollection);

  CollectionReference<Map<String, dynamic>> get _drivers =>
      _firestore.collection(AppConstants.driversCollection);

  @override
  Stream<DeliveryCompany?> watchCompany(String uid) {
    return _companies.doc(uid).snapshots().map((snap) {
      final data = snap.data();
      if (!snap.exists || data == null) return null;
      return DeliveryCompany.fromFirestore(uid, data);
    });
  }

  @override
  Future<DeliveryCompany?> getCompany(String uid) async {
    final snap = await _companies.doc(uid).get();
    final data = snap.data();
    if (!snap.exists || data == null) return null;
    return DeliveryCompany.fromFirestore(uid, data);
  }

  @override
  Future<void> createCompany(DeliveryCompany company) {
    return _companies.doc(company.uid).set({
      ...company.toCreateMap(),
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> markPhoneVerified(String uid) {
    return _companies.doc(uid).update({
      'phoneVerified': true,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> activate() async {
    await _functions.httpsCallable('activateDeliveryCompany').call<Object?>();
  }

  @override
  Stream<List<CompanyCourier>> watchCouriers(String companyId) {
    return _drivers
        .where('deliveryCompanyId', isEqualTo: companyId)
        .snapshots()
        .map((snap) {
          final list =
              snap.docs
                  .map((d) => _courierFromFirestore(d.id, d.data(), companyId))
                  .toList()
                ..sort((a, b) => a.displayName.compareTo(b.displayName));
          return list;
        });
  }

  @override
  Stream<CompanyCourier?> watchCourier(String companyId, String driverId) {
    return _drivers.doc(driverId).snapshots().map((snap) {
      final data = snap.data();
      if (!snap.exists || data == null) return null;
      if (_string(data['deliveryCompanyId']) != companyId) return null;
      return _courierFromFirestore(snap.id, data, companyId);
    });
  }

  @override
  Future<void> respondToCourier({
    required String driverId,
    required CourierRequestAction action,
  }) async {
    await _functions.httpsCallable('respondToCompanyCourier').call<Object?>({
      'driverId': driverId,
      'action': action.name,
    });
  }

  @override
  Future<void> setCourierEnabled({
    required String driverId,
    required bool enabled,
  }) async {
    await _functions.httpsCallable('setCompanyCourierEnabled').call<Object?>({
      'driverId': driverId,
      'enabled': enabled,
    });
  }

  @override
  Future<FleetOverview> fetchFleetOverview() async {
    final result = await _functions
        .httpsCallable('getCompanyFleetOverview')
        .call<Object?>();
    return FleetOverview.fromMap(_asMap(result.data));
  }

  @override
  Future<CourierStats> fetchCourierStats(String driverId) async {
    final result = await _functions
        .httpsCallable('getCompanyCourierStats')
        .call<Object?>({'driverId': driverId});
    return CourierStats.fromMap(_asMap(result.data));
  }

  @override
  Future<List<CompanyOrder>> fetchOrders({int days = 7}) async {
    final result = await _functions
        .httpsCallable('getCompanyOrders')
        .call<Object?>({'days': days});
    final raw = _asMap(result.data)['orders'];
    return raw is List ? raw.map(CompanyOrder.fromMap).toList() : const [];
  }

  @override
  Future<CompanyEarnings> fetchEarnings() async {
    final result = await _functions
        .httpsCallable('getCompanyEarnings')
        .call<Object?>();
    return CompanyEarnings.fromMap(_asMap(result.data));
  }

  @override
  Future<void> updateInfo(
    String uid, {
    required String companyName,
    required String managerName,
  }) {
    return _companies.doc(uid).update({
      'companyName': companyName,
      'managerName': managerName,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  static CompanyCourier _courierFromFirestore(
    String uid,
    Map<String, dynamic> d,
    String companyId,
  ) {
    final first = _string(d['firstName']) ?? '';
    final last = _string(d['lastName']) ?? '';
    final name = '$first $last'.trim();
    return CompanyCourier(
      uid: uid,
      displayName: name.isNotEmpty
          ? name
          : _string(d['name']) ?? _string(d['displayName']) ?? '—',
      phone: _string(d['phone']) ?? '',
      vehicleType: _string(d['vehicleType']) ?? 'motorcycle',
      profilePhotoUrl: _string(d['profilePhotoUrl']),
      accountStatus: _string(d['status']) ?? 'unverified',
      online: d['online'] as bool? ?? false,
      enabled: d['enabledByProvider'] as bool? ?? true,
      approved:
          companyId.isNotEmpty && _string(d['companyApprovedId']) == companyId,
      activeOrderId: _string(d['activeOrderId']),
      activeDeliveryTaskId: _string(d['activeDeliveryTaskId']),
      activeRideId: _string(d['activeRideId']),
      requestedAt: ToukhFirestoreTimestamps.toDateTime(d['createdAt']),
      approvedAt: ToukhFirestoreTimestamps.toDateTime(d['companyApprovedAt']),
    );
  }

  static Map<String, dynamic> _asMap(Object? raw) =>
      raw is Map ? raw.map((k, v) => MapEntry('$k', v)) : const {};

  static String? _string(Object? v) =>
      v is String && v.trim().isNotEmpty ? v.trim() : null;
}
