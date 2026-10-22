import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:toukh_provider/core/constants/app_constants.dart';
import 'package:toukh_provider/data/mappers/provider_driver_mapper.dart';
import 'package:toukh_provider/domain/entities/provider_driver_link_request.dart';
import 'package:toukh_provider/domain/entities/provider_linked_driver.dart';
import 'package:toukh_provider/domain/repositories/provider_drivers_repository.dart';

class FirestoreProviderDriversRepository implements ProviderDriversRepository {
  FirestoreProviderDriversRepository(
    this._firestore,
    this._functions,
  );

  final FirebaseFirestore _firestore;
  final FirebaseFunctions _functions;

  @override
  Stream<ProviderDriversSnapshot> watchDrivers(String providerId) {
    StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? pendingSub;
    StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? linkedSub;

    late StreamController<ProviderDriversSnapshot> controller;

    List<ProviderDriverLinkRequest> pending = [];
    List<ProviderLinkedDriver> linked = [];

    void emit() {
      if (controller.isClosed) return;
      controller.add(
        ProviderDriversSnapshot(
          pendingRequests: List.unmodifiable(pending),
          linkedDrivers: List.unmodifiable(linked),
        ),
      );
    }

    controller = StreamController<ProviderDriversSnapshot>(
      onListen: () {
        // Couriers ask by setting `pendingProviderId` on their driver doc; the
        // store's accept moves it to the server-owned `linkedProviderId`.
        pendingSub = _firestore
            .collection(AppConstants.driversCollection)
            .where('pendingProviderId', isEqualTo: providerId)
            .snapshots()
            .listen(
              (snap) {
                pending = snap.docs
                    // Registrants show up once their phone is verified.
                    .where((d) => d.data()['status'] != 'unverified')
                    .map(
                      (d) => ProviderDriverMapper.linkRequestFromFirestore(
                        d.id,
                        d.data(),
                      ),
                    )
                    .toList();
                pending.sort((a, b) {
                  final at = a.submittedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
                  final bt = b.submittedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
                  return bt.compareTo(at);
                });
                emit();
              },
              onError: controller.addError,
            );

        linkedSub = _firestore
            .collection(AppConstants.driversCollection)
            .where('linkedProviderId', isEqualTo: providerId)
            .snapshots()
            .listen(
              (snap) {
                linked = snap.docs
                    .map(
                      (d) => ProviderDriverMapper.linkedDriverFromFirestore(
                        d.id,
                        d.data(),
                      ),
                    )
                    .toList();
                linked.sort((a, b) => a.displayName.compareTo(b.displayName));
                emit();
              },
              onError: controller.addError,
            );
      },
      onCancel: () async {
        await pendingSub?.cancel();
        await linkedSub?.cancel();
      },
    );

    return controller.stream;
  }

  @override
  Future<void> respond({
    required String driverId,
    required DriverLinkAction action,
  }) async {
    final callable = _functions.httpsCallable('respondToLinkedDriver');
    await callable.call<Map<String, dynamic>>({
      'driverId': driverId,
      'action': action.name,
    });
  }
}
