import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:toukh_provider/domain/entities/order_history_stats.dart';
import 'package:toukh_provider/domain/repositories/provider_order_history_repository.dart';
import 'package:toukh_ui/toukh_ui.dart';

class FirestoreProviderOrderHistoryRepository
    implements ProviderOrderHistoryRepository {
  FirestoreProviderOrderHistoryRepository(this._firestore);

  final FirebaseFirestore _firestore;

  static const _statsBatchLimit = 2000;

  static DateTime _startOfDay(DateTime d) =>
      DateTime(d.year, d.month, d.day);

  static DateTime _endOfDay(DateTime d) =>
      DateTime(d.year, d.month, d.day, 23, 59, 59, 999);

  static bool _hasProviderSlice(MasterOrder m, String providerUid) =>
      m.hasProviderSlice(providerUid);

  static bool _isCanceledSlice(ProviderOrderSlice slice) {
    if (slice.cancelledAt != null) return true;
    if (ProviderOrderStatusWire.normalize(slice.statusWire) ==
        ProviderOrderStatusWire.cancelled) {
      return true;
    }
    return slice.providerState.trim().toLowerCase() == 'rejected';
  }

  Query<Map<String, dynamic>> _finishedQuery(
    String providerId, {
    DateTime? from,
    DateTime? to,
  }) {
    var q = _firestore
        .collection(ToukhOrderPaths.finishedOrders)
        .where('providerIds', arrayContains: providerId);
    if (from != null) {
      q = q.where(
        'finishedAt',
        isGreaterThanOrEqualTo: Timestamp.fromDate(_startOfDay(from)),
      );
    }
    if (to != null) {
      q = q.where(
        'finishedAt',
        isLessThanOrEqualTo: Timestamp.fromDate(_endOfDay(to)),
      );
    }
    return q.orderBy('finishedAt', descending: true);
  }

  Query<Map<String, dynamic>> _activeMasterQuery(
    String providerId, {
    DateTime? from,
    DateTime? to,
  }) {
    var q = _firestore
        .collection(ToukhOrderPaths.masterOrders)
        .where('providerIds', arrayContains: providerId);
    if (from != null) {
      q = q.where(
        'createdAt',
        isGreaterThanOrEqualTo: Timestamp.fromDate(_startOfDay(from)),
      );
    }
    if (to != null) {
      q = q.where(
        'createdAt',
        isLessThanOrEqualTo: Timestamp.fromDate(_endOfDay(to)),
      );
    }
    return q.orderBy('createdAt', descending: true);
  }

  List<ProviderMasterOrderRow> _rowsFromFinishedDocs(
    Iterable<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
    String providerId,
  ) {
    final rows = <ProviderMasterOrderRow>[];
    for (final doc in docs) {
      final order = FinishedOrder.fromMap(doc.id, doc.data()).order;
      if (!_hasProviderSlice(order, providerId)) continue;
      rows.add(ProviderMasterOrderRow.fromMaster(order, providerId));
    }
    return rows;
  }

  @override
  Future<OrderHistoryStats> fetchStats(
    String providerId, {
    DateTime? from,
    DateTime? to,
  }) async {
    final finishedQ = _finishedQuery(providerId, from: from, to: to);
    final finishedCountSnap = await finishedQ.count().get();
    final finishedCount = finishedCountSnap.count ?? 0;

    var activeCount = 0;
    final masterSnap = await _activeMasterQuery(providerId, from: from, to: to)
        .limit(_statsBatchLimit)
        .get();
    for (final doc in masterSnap.docs) {
      final order = MasterOrder.fromMap(doc.id, doc.data());
      if (!_hasProviderSlice(order, providerId)) continue;
      final slice = order.sliceFor(providerId);
      if (slice != null && !slice.isTerminal) activeCount++;
    }

    var completed = 0;
    var canceled = 0;
    final statsSnap = await finishedQ.limit(_statsBatchLimit).get();
    for (final doc in statsSnap.docs) {
      final order = FinishedOrder.fromMap(doc.id, doc.data()).order;
      if (!_hasProviderSlice(order, providerId)) continue;
      final slice = order.sliceFor(providerId);
      if (slice == null) continue;
      if (slice.isDelivered) {
        completed++;
      } else if (_isCanceledSlice(slice)) {
        canceled++;
      }
    }

    return OrderHistoryStats(
      totalOrders: finishedCount + activeCount,
      completedOrders: completed,
      canceledOrders: canceled,
    );
  }

  @override
  Future<OrderHistoryPage> fetchPage(
    String providerId, {
    int pageSize = 20,
    DateTime? from,
    DateTime? to,
    Object? startAfter,
  }) async {
    var q = _finishedQuery(providerId, from: from, to: to).limit(pageSize);
    if (startAfter is DocumentSnapshot<Map<String, dynamic>>) {
      q = q.startAfterDocument(startAfter);
    }
    final snap = await q.get();
    if (snap.docs.isEmpty) {
      return const OrderHistoryPage(rows: [], lastDoc: null);
    }
    return OrderHistoryPage(
      rows: _rowsFromFinishedDocs(snap.docs, providerId),
      lastDoc: snap.docs.last,
    );
  }
}
