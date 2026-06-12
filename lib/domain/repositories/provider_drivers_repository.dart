import 'package:toukh_provider/domain/entities/provider_driver_link_request.dart';
import 'package:toukh_provider/domain/entities/provider_linked_driver.dart';

class ProviderDriversSnapshot {
  const ProviderDriversSnapshot({
    required this.pendingRequests,
    required this.linkedDrivers,
  });

  final List<ProviderDriverLinkRequest> pendingRequests;
  final List<ProviderLinkedDriver> linkedDrivers;
}

abstract class ProviderDriversRepository {
  Stream<ProviderDriversSnapshot> watchDrivers(String providerId);

  Future<void> respondToRequest({
    required String driverId,
    required bool accept,
  });
}
