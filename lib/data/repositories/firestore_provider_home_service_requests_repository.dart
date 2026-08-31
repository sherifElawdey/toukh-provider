import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import 'package:toukh_provider/domain/entities/pre_service_question.dart';
import 'package:toukh_provider/domain/entities/provider_home_service_request.dart';
import 'package:toukh_provider/domain/repositories/provider_home_service_requests_repository.dart';
import 'package:toukh_provider/features/home_service_requests/cubit/home_service_schedule_helpers.dart';
import 'package:toukh_ui/toukh_ui.dart';

const _kCollection = 'homeServiceRequests';

class FirestoreProviderHomeServiceRequestsRepository
    implements ProviderHomeServiceRequestsRepository {
  FirestoreProviderHomeServiceRequestsRepository(
    this._fs, {
    FirebaseFunctions? functions,
  }) : _functions = functions;

  final FirebaseFirestore _fs;
  final FirebaseFunctions? _functions;

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
    final created = ToukhFirestoreTimestamps.toDateTime(ts);

    DateTime? tsDate(String key) => ToukhFirestoreTimestamps.toDateTime(data[key]);

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
      startAddressTitle: data['startAddressTitle'] as String?,
      startAddressFormatted: data['startAddressFormatted'] as String?,
      startLat: (data['startLat'] as num?)?.toDouble(),
      startLng: (data['startLng'] as num?)?.toDouble(),
      destinationAddressTitle: data['destinationAddressTitle'] as String?,
      destinationAddressFormatted:
          data['destinationAddressFormatted'] as String?,
      destinationLat: (data['destinationLat'] as num?)?.toDouble(),
      destinationLng: (data['destinationLng'] as num?)?.toDouble(),
      cargoDescription: (data['cargoDescription'] as String?)?.trim(),
      withDriver: data['withDriver'] as bool?,
      preferredTimeRaw: data['preferredTime'] as String?,
      preferredDate: tsDate('preferredDate'),
      note: (data['note'] as String?)?.trim(),
      noteImageUrl: data['noteImageUrl'] as String?,
      preServiceAnswers:
          PreServiceAnswer.listFromFirestore(data['preServiceAnswers']),
      clientPriceEgp: _toDouble(data['clientPriceEgp']),
      quotedPriceEgp: _toDouble(data['quotedPriceEgp']),
      scheduledAt: tsDate('scheduledAt'),
      quotedAt: tsDate('quotedAt'),
      quoteUsesClientPrice: data['quoteUsesClientPrice'] as bool?,
      customerPhone: (data['customerPhone'] as String?)?.trim(),
      customerPhotoUrl: (data['customerPhotoUrl'] as String?)?.trim(),
      onMyWayAt: tsDate('onMyWayAt'),
      completedAt: tsDate('completedAt'),
      cancelledAt: tsDate('cancelledAt'),
      completionCode: data['completionCode'] as String?,
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

  @override
  Future<void> markOnMyWay({
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
    if (current != 'accepted') {
      throw StateError('Request cannot be updated');
    }
    final scheduledTs = data['scheduledAt'];
    if (scheduledTs is! Timestamp) {
      throw StateError('Visit date is not scheduled');
    }
    if (!isVisitToday(scheduledTs.toDate())) {
      throw StateError('On My Way is only available on the visit day');
    }

    final active = await _fs
        .collection(_kCollection)
        .where('providerId', isEqualTo: providerId)
        .where('status', isEqualTo: 'in_progress')
        .limit(2)
        .get();
    final hasOtherActive = active.docs.any((d) => d.id != requestId);
    if (hasOtherActive) {
      throw StateError('Another visit is already in progress');
    }

    await ref.update({
      'status': 'in_progress',
      'onMyWayAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> markCompleted({
    required String requestId,
    required String providerId,
    required String completionCode,
  }) async {
    final functions = _functions;
    if (functions != null) {
      try {
        await functions.httpsCallable('completeHomeServiceRequest').call({
          'requestId': requestId,
          'completionCode': completionCode,
        });
        return;
      } on FirebaseFunctionsException catch (e) {
        if (e.code != 'not-found' && e.code != 'unavailable') {
          if (kDebugMode) {
            debugPrint(
              'completeHomeServiceRequest failed: ${e.code} ${e.message}',
            );
          }
          final message = e.message?.trim();
          throw StateError(
            (message != null && message.isNotEmpty)
                ? message
                : 'Could not complete request.',
          );
        }
      }
    }
    await _markCompletedFallback(
      requestId: requestId,
      providerId: providerId,
      completionCode: completionCode,
    );
  }

  Future<void> _markCompletedFallback({
    required String requestId,
    required String providerId,
    required String completionCode,
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
    if (current != 'in_progress') {
      throw StateError('Request cannot be updated');
    }
    final storedCode = data['completionCode'] as String?;
    if (storedCode != null &&
        storedCode.isNotEmpty &&
        completionCode != storedCode) {
      throw StateError('Incorrect completion code.');
    }

    await ref.update({
      'status': 'completed',
      'completedAt': FieldValue.serverTimestamp(),
      'ratingCompleted': false,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
