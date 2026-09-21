import 'dart:async';
import 'dart:io';

import 'package:toukh_provider/core/dev/provider_showcase_mocks.dart';
import 'package:toukh_provider/domain/entities/provider_home_service_request.dart';
import 'package:toukh_provider/domain/repositories/notification_inbox_repository.dart';
import 'package:toukh_provider/domain/repositories/provider_gallery_repository.dart';
import 'package:toukh_provider/domain/repositories/provider_home_service_requests_repository.dart';
import 'package:toukh_provider/domain/repositories/provider_orders_repository.dart';
import 'package:toukh_ui/toukh_ui.dart';

/// In-memory orders for showcase (no Firestore).
class MockProviderOrdersRepository implements ProviderOrdersRepository {
  @override
  Stream<List<MasterOrder>> watchOrders(String providerUid) =>
      Stream.value(ProviderShowcaseMocks.ordersFor(providerUid));

  @override
  Future<MasterOrder?> getOrderById({
    required String providerId,
    required String orderId,
  }) async {
    for (final o in ProviderShowcaseMocks.ordersFor(providerId)) {
      if (o.id == orderId) return o;
    }
    return null;
  }

  @override
  Future<void> approveOrder({
    required String providerId,
    required String orderId,
    required bool storeDelivers,
  }) async {}

  @override
  Future<void> cancelOrder({
    required String providerId,
    required String orderId,
    String? reason,
  }) async {}

  @override
  Future<String> requestDelivery({
    required String providerId,
    required String orderId,
    required Location searchCenter,
  }) async =>
      'mock_delivery_request';

  @override
  Future<void> markReadyForPickup({
    required String providerId,
    required String orderId,
  }) async {}

  @override
  Future<void> markStoreOutForDelivery({
    required String providerId,
    required String orderId,
  }) async {}

  @override
  Future<void> assignStoreDriverAndDispatch({
    required String providerId,
    required String orderId,
    required String driverId,
    required String driverName,
    String? driverPhotoUrl,
  }) async {}

  @override
  Future<void> confirmHandoffToCourier({
    required String providerId,
    required String orderId,
  }) async {}

  @override
  Future<void> markDelivered({
    required String providerId,
    required String orderId,
    required String completionCode,
  }) async {}

  @override
  Future<void> approvePharmacyRequest({
    required String providerId,
    required String masterOrderId,
    required String pharmacistNote,
    required List<String> approvedItemIds,
    required double quotedSubtotalEgp,
    required double quotedDeliveryFeeEgp,
  }) async {}
}

/// In-memory home-service requests for showcase.
class MockProviderHomeServiceRequestsRepository
    implements ProviderHomeServiceRequestsRepository {
  @override
  Stream<List<ProviderHomeServiceRequest>> watchRequests(String providerId) =>
      Stream.value(ProviderShowcaseMocks.requestsFor(providerId));

  @override
  Stream<ProviderHomeServiceRequest?> watchRequest(String requestId) {
    ProviderHomeServiceRequest? found;
    for (final r in ProviderShowcaseMocks.requestsFor('showcase')) {
      if (r.id == requestId) {
        found = r;
        break;
      }
    }
    return Stream.value(found);
  }

  @override
  Future<void> submitQuote({
    required String requestId,
    required String providerId,
    required double quotedPriceEgp,
    required DateTime scheduledAt,
  }) async {}

  @override
  Future<void> declineRequest({
    required String requestId,
    required String providerId,
  }) async {}

  @override
  Future<void> markOnMyWay({
    required String requestId,
    required String providerId,
  }) async {}

  @override
  Future<void> markCompleted({
    required String requestId,
    required String providerId,
    required String completionCode,
  }) async {}
}

/// In-memory notification inbox for showcase.
class MockNotificationInboxRepository implements NotificationInboxRepository {
  List<ToukhNotification> _items = ProviderShowcaseMocks.notifications();

  @override
  Stream<List<ToukhNotification>> watchInbox(String uid) =>
      Stream.value(List.unmodifiable(_items));

  @override
  Future<void> markOpened({
    required String uid,
    required String notificationId,
  }) async {
    _items = [
      for (final n in _items)
        if (n.id == notificationId)
          n.copyWith(opened: true, openedAt: DateTime.now())
        else
          n,
    ];
  }

  @override
  Future<void> deleteNotification({
    required String uid,
    required String notificationId,
  }) async {
    _items = [for (final n in _items) if (n.id != notificationId) n];
  }

  @override
  Future<void> markAllOpened({required String uid}) async {
    final now = DateTime.now();
    _items = [
      for (final n in _items) n.copyWith(opened: true, openedAt: now),
    ];
  }

  @override
  Future<void> clearInbox({required String uid}) async {
    _items = [];
  }

  @override
  Future<int> unreadCount(String uid) async =>
      _items.where((n) => !n.opened).length;
}

/// In-memory gallery for showcase.
class MockProviderGalleryRepository implements ProviderGalleryRepository {
  MockProviderGalleryRepository() {
    _items = ProviderShowcaseMocks.gallery();
  }

  late List<ProviderGalleryItem> _items;
  final _controller = StreamController<List<ProviderGalleryItem>>.broadcast();

  void _emit() {
    if (!_controller.isClosed) {
      _controller.add(List.unmodifiable(_items));
    }
  }

  @override
  Stream<List<ProviderGalleryItem>> watchGallery(String providerId) {
    return Stream.multi((listener) {
      listener.add(List.unmodifiable(_items));
      final sub = _controller.stream.listen(
        listener.add,
        onError: listener.addError,
        onDone: listener.close,
      );
      listener.onCancel = sub.cancel;
    });
  }

  @override
  Future<void> addImages(String providerId, List<File> files) async {
    final now = DateTime.now();
    var i = _items.length;
    for (final _ in files) {
      i++;
      _items = [
        ..._items,
        ProviderGalleryItem(
          id: 'mock_local_$i',
          url: 'https://picsum.photos/seed/toukh-provider-local$i/600/600',
          fileId: 'local_$i',
          fileName: 'upload_$i.jpg',
          createdAt: now,
        ),
      ];
    }
    _emit();
  }

  @override
  Future<void> deleteImage({
    required String providerId,
    required ProviderGalleryItem item,
  }) async {
    _items = [for (final g in _items) if (g.id != item.id) g];
    _emit();
  }
}
