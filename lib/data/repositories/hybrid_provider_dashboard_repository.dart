import 'package:flutter/foundation.dart';
import 'package:toukh_provider/domain/entities/dashboard_firestore_payload.dart';
import 'package:toukh_provider/domain/repositories/provider_dashboard_repository.dart';
import 'package:toukh_provider/data/mock/provider_dashboard_mock_seed.dart';
import 'package:toukh_provider/data/repositories/firestore_provider_dashboard_repository.dart';

/// Release: forwards Firestore. Debug/profile: if there are no orders, shows
/// curated mock data for layout QA.
class HybridProviderDashboardRepository implements ProviderDashboardRepository {
  HybridProviderDashboardRepository(this._firestoreRepo);

  final FirestoreProviderDashboardRepository _firestoreRepo;

  @override
  Stream<DashboardFirestorePayload> watchFirestorePayload(String providerUid) {
    return _firestoreRepo.watchFirestorePayload(providerUid).map((payload) {
      if (!_shouldInjectMock(payload)) return payload;
      return DashboardFirestorePayload(
        orders: ProviderDashboardMockSeed.orders,
        reviews: ProviderDashboardMockSeed.reviews,
        usedMockFallback: true,
      );
    });
  }

  bool _shouldInjectMock(DashboardFirestorePayload payload) {
    if (!(kDebugMode || kProfileMode)) return false;
    return payload.orders.isEmpty;
  }
}
