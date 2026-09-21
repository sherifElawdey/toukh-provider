import 'package:toukh_provider/shared/firestore/toukh_firestore_collections.dart';

/// Firestore collection paths for the order orchestration layer.
abstract final class ToukhOrderPaths {
  ToukhOrderPaths._();

  static const masterOrders = ToukhFirestoreCollections.masterOrders;
  static const finishedOrders = ToukhFirestoreCollections.finishedOrders;
  static const deliveryTasks = ToukhFirestoreCollections.deliveryTasks;
  static const deliveryRequests = ToukhFirestoreCollections.deliveryRequests;
  static const orderTimelines = ToukhFirestoreCollections.orderTimelines;
  static const timelineEventsSubcollection =
      ToukhFirestoreCollections.timelineEvents;

  static String masterOrder(String id) => '$masterOrders/$id';

  static String finishedOrder(String id) => '$finishedOrders/$id';

  /// Legacy path — active orders use [masterOrders] only.
  static String providerOrders(String providerId) =>
      '${ToukhFirestoreCollections.providers}/$providerId/${ToukhFirestoreCollections.orders}';

  static String providerOrder(String providerId, String orderId) =>
      '${providerOrders(providerId)}/$orderId';

  static String deliveryTask(String id) => '$deliveryTasks/$id';

  static String timelineEvents(String timelineId) =>
      '$orderTimelines/$timelineId/$timelineEventsSubcollection';

  static String userOrderSummary(String uid, String summaryId) =>
      '${ToukhFirestoreCollections.users}/$uid/${ToukhFirestoreCollections.orders}/$summaryId';
}
