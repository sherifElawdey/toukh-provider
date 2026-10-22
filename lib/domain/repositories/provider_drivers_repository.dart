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

  /// Accept / reject a courier's link request, or end an approved link.
  Future<void> respond({
    required String driverId,
    required DriverLinkAction action,
  });
}

/// Wire values of the `respondToLinkedDriver` callable.
enum DriverLinkAction { accept, reject, remove }
