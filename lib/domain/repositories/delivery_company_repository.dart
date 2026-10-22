import 'package:toukh_provider/domain/entities/company_courier.dart';
import 'package:toukh_provider/domain/entities/company_courier_stats.dart';
import 'package:toukh_provider/domain/entities/delivery_company.dart';

abstract class DeliveryCompanyRepository {
  Stream<DeliveryCompany?> watchCompany(String uid);

  Future<DeliveryCompany?> getCompany(String uid);

  Future<void> createCompany(DeliveryCompany company);

  Future<void> markPhoneVerified(String uid);

  /// Server flips status to active once the phone is verified.
  Future<void> activate();

  /// Every courier pointing at [companyId]: joined and requesting.
  Stream<List<CompanyCourier>> watchCouriers(String companyId);

  /// Null when the driver is not affiliated with [companyId].
  Stream<CompanyCourier?> watchCourier(String companyId, String driverId);

  Future<void> respondToCourier({
    required String driverId,
    required CourierRequestAction action,
  });

  Future<void> setCourierEnabled({
    required String driverId,
    required bool enabled,
  });

  Future<FleetOverview> fetchFleetOverview();

  Future<CourierStats> fetchCourierStats(String driverId);

  /// Live and finished jobs of every courier over the last [days] days.
  Future<List<CompanyOrder>> fetchOrders({int days = 7});

  Future<CompanyEarnings> fetchEarnings();

  /// Owner-editable profile fields only.
  Future<void> updateInfo(
    String uid, {
    required String companyName,
    required String managerName,
  });
}

enum CourierRequestAction { accept, reject, remove }
