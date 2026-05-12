import 'package:toukh_provider/domain/entities/dashboard_firestore_payload.dart';

abstract class ProviderDashboardRepository {
  /// Combined stream of orders and reviews under `providers/{providerUid}`.
  Stream<DashboardFirestorePayload> watchFirestorePayload(String providerUid);
}
