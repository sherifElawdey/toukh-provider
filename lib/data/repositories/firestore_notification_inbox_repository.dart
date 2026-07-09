import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:toukh_provider/domain/repositories/notification_inbox_repository.dart';
import 'package:toukh_ui/toukh_ui.dart';

class FirestoreNotificationInboxRepository implements NotificationInboxRepository {
  FirestoreNotificationInboxRepository(this._firestore);

  final FirebaseFirestore _firestore;

  static const _recipient = ToukhNotificationRecipient.provider;
  static const _batchLimit = 500;

  CollectionReference<Map<String, dynamic>> _inbox(String uid) {
    return _firestore
        .collection(_recipient.collectionName)
        .doc(uid)
        .collection(ToukhNotificationPaths.notificationsSubcollection);
  }

  @override
  Stream<List<ToukhNotification>> watchInbox(String uid) {
    return _inbox(uid)
        .orderBy('createdAt', descending: true)
        .limit(100)
        .snapshots()
        .map((snap) => snap.docs.map(_fromDoc).toList());
  }

  @override
  Future<void> markOpened({
    required String uid,
    required String notificationId,
  }) async {
    await _inbox(uid).doc(notificationId).update({
      'opened': true,
      'openedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> deleteNotification({
    required String uid,
    required String notificationId,
  }) async {
    await _inbox(uid).doc(notificationId).delete();
  }

  @override
  Future<void> markAllOpened({required String uid}) async {
    final snap = await _inbox(uid).where('opened', isEqualTo: false).get();
    if (snap.docs.isEmpty) return;

    for (var i = 0; i < snap.docs.length; i += _batchLimit) {
      final batch = _firestore.batch();
      final chunk = snap.docs.skip(i).take(_batchLimit);
      for (final doc in chunk) {
        batch.update(doc.reference, {
          'opened': true,
          'openedAt': FieldValue.serverTimestamp(),
        });
      }
      await batch.commit();
    }
  }

  @override
  Future<void> clearInbox({required String uid}) async {
    while (true) {
      final snap = await _inbox(uid).limit(_batchLimit).get();
      if (snap.docs.isEmpty) return;

      final batch = _firestore.batch();
      for (final doc in snap.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();

      if (snap.docs.length < _batchLimit) return;
    }
  }

  @override
  Future<int> unreadCount(String uid) async {
    final snap = await _inbox(uid).where('opened', isEqualTo: false).count().get();
    return snap.count ?? 0;
  }

  ToukhNotification _fromDoc(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    final base = ToukhNotificationMapper.fromFirestore(doc.id, data);
    return base.copyWith(
      createdAt: _toDate(data['createdAt']),
      openedAt: _toDate(data['openedAt']),
    );
  }

  DateTime? _toDate(dynamic v) => ToukhFirestoreTimestamps.toDateTime(v);
}
