import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:toukh_provider/domain/entities/provider_home_service_request.dart';
import 'package:toukh_provider/domain/repositories/provider_home_service_requests_repository.dart';

const _kCollection = 'homeServiceRequests';

class FirestoreProviderHomeServiceRequestsRepository
    implements ProviderHomeServiceRequestsRepository {
  FirestoreProviderHomeServiceRequestsRepository(this._fs);

  final FirebaseFirestore _fs;

  double? _toDouble(dynamic v) {
    if (v is num) return v.toDouble();
    if (v is String && v.trim().isNotEmpty) {
      return double.tryParse(v.trim());
    }
    return null;
  }

  ProviderHomeServiceRequest _fromDoc(
    DocumentSnapshot<Map<String, dynamic>> d,
  ) {
    final data = d.data() ?? {};
    final ts = data['createdAt'];
    DateTime? created;
    if (ts is Timestamp) created = ts.toDate();

    DateTime? tsDate(String key) {
      final v = data[key];
      if (v is Timestamp) return v.toDate();
      return null;
    }

    return ProviderHomeServiceRequest(
      id: d.id,
      userId: data['userId'] as String? ?? '',
      customerName: (data['customerName'] as String?)?.trim(),
      providerId: data['providerId'] as String? ?? '',
      providerName: (data['providerName'] as String?)?.trim(),
      categoryId: data['categoryId'] as String? ?? '',
      categoryTitle: data['categoryTitle'] as String? ?? '',
      status: data['status'] as String? ?? '',
      createdAt: created,
      addressTitle: data['addressTitle'] as String?,
      addressFormatted: data['addressFormatted'] as String?,
      addressLat: (data['addressLat'] as num?)?.toDouble(),
      addressLng: (data['addressLng'] as num?)?.toDouble(),
      preferredTimeRaw: data['preferredTime'] as String?,
      note: (data['note'] as String?)?.trim(),
      noteImageUrl: data['noteImageUrl'] as String?,
      clientPriceEgp: _toDouble(data['clientPriceEgp']),
      quotedPriceEgp: _toDouble(data['quotedPriceEgp']),
      scheduledAt: tsDate('scheduledAt'),
      quotedAt: tsDate('quotedAt'),
      quoteUsesClientPrice: data['quoteUsesClientPrice'] as bool?,
    );
  }

  List<ProviderHomeServiceRequest> _sorted(
    List<ProviderHomeServiceRequest> list,
  ) {
    list.sort((a, b) {
      final at = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bt = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bt.compareTo(at);
    });
    return list;
  }

  @override
  Stream<List<ProviderHomeServiceRequest>> watchRequests(String providerId) {
    return _fs
        .collection(_kCollection)
        .where('providerId', isEqualTo: providerId)
        .snapshots()
        .map((snap) {
      final list = snap.docs.map(_fromDoc).toList();
      return _sorted(list);
    });
  }

  @override
  Stream<ProviderHomeServiceRequest?> watchRequest(String requestId) {
    return _fs
        .collection(_kCollection)
        .doc(requestId)
        .snapshots()
        .map((snap) => snap.exists ? _fromDoc(snap) : null);
  }

  @override
  Future<void> submitQuote({
    required String requestId,
    required String providerId,
    required double quotedPriceEgp,
    required DateTime scheduledAt,
  }) async {
    if (quotedPriceEgp < 0) {
      throw StateError('Invalid price');
    }
    final ref = _fs.collection(_kCollection).doc(requestId);
    final snap = await ref.get();
    if (!snap.exists) {
      throw StateError('Request not found');
    }
    final data = snap.data()!;
    if ((data['providerId'] as String?) != providerId) {
      throw StateError('Not authorized');
    }
    final current = (data['status'] as String? ?? '').trim().toLowerCase();
    if (current != 'pending') {
      throw StateError('Request cannot be updated');
    }
    final clientPrice = _toDouble(data['clientPriceEgp']);
    final usesClientPrice = clientPrice != null &&
        (quotedPriceEgp - clientPrice).abs() < 0.01;

    await ref.update({
      'status': 'awaiting_customer',
      'quotedPriceEgp': quotedPriceEgp,
      'scheduledAt': Timestamp.fromDate(scheduledAt.toUtc()),
      'quotedAt': FieldValue.serverTimestamp(),
      'quoteUsesClientPrice': usesClientPrice,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> declineRequest({
    required String requestId,
    required String providerId,
  }) async {
    final ref = _fs.collection(_kCollection).doc(requestId);
    final snap = await ref.get();
    if (!snap.exists) {
      throw StateError('Request not found');
    }
    final data = snap.data()!;
    if ((data['providerId'] as String?) != providerId) {
      throw StateError('Not authorized');
    }
    final current = (data['status'] as String? ?? '').trim().toLowerCase();
    if (current != 'pending') {
      throw StateError('Request cannot be updated');
    }
    await ref.update({
      'status': 'declined',
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
