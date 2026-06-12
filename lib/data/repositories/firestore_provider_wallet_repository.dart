import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:toukh_provider/core/constants/app_constants.dart';
import 'package:toukh_provider/domain/entities/provider_wallet_transaction.dart';
import 'package:toukh_provider/domain/repositories/provider_wallet_repository.dart';

class FirestoreProviderWalletRepository implements ProviderWalletRepository {
  FirestoreProviderWalletRepository(this._firestore);

  final FirebaseFirestore _firestore;

  static const _transactions = 'transactions';

  DocumentReference<Map<String, dynamic>> _providerRef(String providerId) =>
      _firestore.collection(AppConstants.providersCollection).doc(providerId);

  CollectionReference<Map<String, dynamic>> _txCol(String providerId) =>
      _providerRef(providerId).collection(_transactions);

  static double _balanceFromData(Map<String, dynamic>? data) {
    if (data == null) return 0;
    final v = data['walletBalanceEgp'];
    if (v is num) return v.toDouble();
    return 0;
  }

  static double? _pendingFromData(Map<String, dynamic>? data) {
    if (data == null) return null;
    final v = data['walletPendingEgp'];
    if (v is num) return v.toDouble();
    return null;
  }

  @override
  Stream<ProviderWalletSummary> watchWalletSummary(String providerId) {
    return _providerRef(providerId).snapshots().map((snap) {
      final data = snap.data();
      return ProviderWalletSummary(
        balanceEgp: _balanceFromData(data),
        pendingEgp: _pendingFromData(data),
      );
    });
  }

  @override
  Stream<List<ProviderWalletTransaction>> watchRecentTransactions(
    String providerId, {
    int limit = 10,
  }) {
    return _txCol(providerId)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((d) => ProviderWalletTransaction.fromFirestore(d.id, d.data()))
              .toList(),
        );
  }

  @override
  Future<List<ProviderWalletTransaction>> fetchTransactionsForChart(
    String providerId,
    DateTime periodStart,
    DateTime periodEnd, {
    int docLimit = 400,
  }) async {
    final snap = await _txCol(providerId)
        .orderBy('createdAt', descending: true)
        .limit(docLimit)
        .get();

    final start = periodStart.toUtc();
    final end = periodEnd.toUtc();

    final out = <ProviderWalletTransaction>[];
    for (final d in snap.docs) {
      final t = ProviderWalletTransaction.fromFirestore(d.id, d.data());
      final c = t.createdAt?.toUtc();
      if (c == null) continue;
      if (c.isBefore(start) || c.isAfter(end)) continue;
      if (t.direction != ProviderWalletTxDirection.credit) continue;
      out.add(t);
    }
    return out;
  }

  @override
  Future<({List<ProviderWalletTransaction> items, DocumentSnapshot? lastDoc})>
      fetchTransactionsPage(
    String providerId, {
    int pageSize = 20,
    DocumentSnapshot? startAfter,
  }) async {
    var q = _txCol(providerId)
        .orderBy('createdAt', descending: true)
        .limit(pageSize);
    if (startAfter != null) {
      q = q.startAfterDocument(startAfter);
    }
    final snap = await q.get();
    if (snap.docs.isEmpty) {
      return (items: <ProviderWalletTransaction>[], lastDoc: null);
    }
    final items = snap.docs
        .map((d) => ProviderWalletTransaction.fromFirestore(d.id, d.data()))
        .toList();
    return (items: items, lastDoc: snap.docs.last);
  }
}
