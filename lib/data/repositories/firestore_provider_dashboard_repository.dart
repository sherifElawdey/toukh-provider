import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:toukh_ui/toukh_ui.dart';
import 'package:toukh_provider/core/constants/app_constants.dart';
import 'package:toukh_provider/domain/entities/dashboard_firestore_payload.dart';
import 'package:toukh_provider/domain/entities/provider_dashboard_order.dart';
import 'package:toukh_provider/domain/entities/provider_review_summary.dart';
import 'package:toukh_provider/domain/repositories/provider_dashboard_repository.dart';

class FirestoreProviderDashboardRepository implements ProviderDashboardRepository {
  FirestoreProviderDashboardRepository(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _ordersCol(String providerUid) =>
      _firestore
          .collection(AppConstants.providersCollection)
          .doc(providerUid)
          .collection('orders');

  CollectionReference<Map<String, dynamic>> _reviewsCol(String providerUid) =>
      _firestore
          .collection(AppConstants.providersCollection)
          .doc(providerUid)
          .collection('reviews');

  @override
  Stream<DashboardFirestorePayload> watchFirestorePayload(String providerUid) {
    StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? subOrders;
    StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? subReviews;

    late StreamController<DashboardFirestorePayload> controller;

    List<ProviderOrderDashboard> orders = [];
    List<ProviderReviewSummary> reviews = [];

    void emit() {
      if (!controller.isClosed) {
        controller.add(
          DashboardFirestorePayload(
            orders: List.unmodifiable(orders),
            reviews: List.unmodifiable(reviews),
          ),
        );
      }
    }

    controller = StreamController<DashboardFirestorePayload>(
      onListen: () {
        subOrders = _ordersCol(providerUid)
            .orderBy('createdAt', descending: true)
            .limit(500)
            .snapshots()
            .listen(
              (snap) {
                orders = snap.docs.map((d) => _mapOrder(d.id, d.data())).toList();
                emit();
              },
              onError: controller.addError,
            );

        subReviews = _reviewsCol(providerUid)
            .orderBy('createdAt', descending: true)
            .limit(60)
            .snapshots()
            .listen(
              (snap) {
                reviews =
                    snap.docs.map((d) => _mapReview(d.id, d.data())).toList();
                emit();
              },
              onError: controller.addError,
            );
      },
      onCancel: () async {
        await subOrders?.cancel();
        await subReviews?.cancel();
      },
    );

    return controller.stream;
  }

  static ProviderOrderDashboard _mapOrder(String id, Map<String, dynamic> data) {
    final wire = (data['status'] as String?)?.trim().toLowerCase() ?? 'placed';
    final status = _mapOrderStatus(wire);
    final itemsRaw = data['items'] as List<dynamic>? ?? [];
    final items = itemsRaw
        .map((e) => _mapLine(Map<String, dynamic>.from(e as Map)))
        .whereType<ProviderOrderLineItem>()
        .toList();

    final total =
        _double(data['totalEgp']) ??
            _double(data['amountEgp']) ??
            _double(data['total']) ??
            0.0;

    return ProviderOrderDashboard(
      id: id,
      status: status,
      statusWire: wire,
      createdAt: _date(data['createdAt']),
      acceptedAt: _date(data['acceptedAt']),
      deliveredAt: _date(data['deliveredAt']) ?? _date(data['completedAt']),
      totalEgp: total,
      customerName: _string(data['customerName']) ?? _string(data['clientName']),
      items: items,
    );
  }

  static OrderStatus _mapOrderStatus(String wire) {
    switch (wire) {
      case 'preparing':
      case 'ready':
      case 'ready_for_pickup':
        return OrderStatus.accepted;
      default:
        return OrderStatus.fromWire(wire);
    }
  }

  static ProviderOrderLineItem? _mapLine(Map<String, dynamic> m) {
    final name = _string(m['name']) ?? _string(m['itemName']);
    if (name == null || name.isEmpty) return null;
    final qty = _int(m['quantity']) ?? 1;
    final line = _double(m['lineTotalEgp']) ??
        _double(m['lineTotal']) ??
        _double(m['priceEgp']) ??
        0.0;
    return ProviderOrderLineItem(
      itemId: _string(m['itemId']) ?? _string(m['menuItemId']),
      name: name,
      quantity: qty,
      lineTotalEgp: line,
    );
  }

  static ProviderReviewSummary _mapReview(String id, Map<String, dynamic> data) {
    final ratingRaw = data['rating'];
    final rating = ratingRaw is int
        ? ratingRaw.clamp(1, 5)
        : (ratingRaw is num ? ratingRaw.round().clamp(1, 5) : 5);

    return ProviderReviewSummary(
      id: id,
      rating: rating,
      comment: _string(data['comment']) ?? _string(data['text']),
      authorName:
          _string(data['authorName']) ?? _string(data['customerName']),
      createdAt: _date(data['createdAt']),
    );
  }

  static DateTime? _date(dynamic v) {
    if (v is Timestamp) return v.toDate();
    return null;
  }

  static double? _double(dynamic v) {
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v.replaceAll(',', ''));
    return null;
  }

  static int? _int(dynamic v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    return null;
  }

  static String? _string(dynamic v) {
    if (v is String && v.trim().isNotEmpty) return v.trim();
    return null;
  }
}
