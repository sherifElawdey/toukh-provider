import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:toukh_provider/domain/entities/provider_home_service_request.dart';
import 'package:toukh_provider/domain/entities/provider_kind.dart';
import 'package:toukh_provider/domain/repositories/provider_home_service_requests_repository.dart';
import 'package:toukh_provider/features/auth/cubit/auth_cubit.dart';
import 'package:toukh_ui/toukh_ui.dart';

/// Keeps provider local visit reminders in sync for Home Service accounts only.
///
/// Scheduling sources:
/// 1. FCM (`home_service_request_accepted`) via [ToukhPushMessaging]
/// 2. Live [watchRequests] while the app is open
/// 3. [restorePendingNotifications] on auth (iOS terminated fallback)
class HomeServiceVisitReminderCoordinator {
  HomeServiceVisitReminderCoordinator(
    this._authCubit,
    this._repository,
  ) {
    _authSub = _authCubit.stream.listen(_onAuth);
    _onAuth(_authCubit.state);
  }

  final AuthCubit _authCubit;
  final ProviderHomeServiceRequestsRepository _repository;

  StreamSubscription<AuthState>? _authSub;
  StreamSubscription<List<ProviderHomeServiceRequest>>? _requestsSub;
  String? _activeUid;

  void _onAuth(AuthState state) {
    if (state is Authenticated &&
        state.profile.serviceType == ServiceType.homeService) {
      unawaited(_startForUser(state.user.uid));
      return;
    }
    unawaited(_stop());
  }

  Future<void> _startForUser(String uid) async {
    if (_activeUid == uid && _requestsSub != null) {
      await _restore(uid);
      return;
    }
    await _stop();
    _activeUid = uid;
    await _restore(uid);
    _requestsSub = _repository.watchRequests(uid).listen(
      (requests) {
        unawaited(_sync(requests));
      },
      onError: (Object e, StackTrace st) {
        debugPrint(
          'Provider HomeServiceVisitReminderCoordinator stream failed: $e\n$st',
        );
      },
    );
  }

  Future<void> _restore(String uid) async {
    try {
      final requests = await _repository.watchRequests(uid).first;
      await _sync(requests);
    } catch (e, st) {
      debugPrint(
        'Provider HomeServiceVisitReminderCoordinator.restore failed: $e\n$st',
      );
    }
  }

  Future<void> _sync(List<ProviderHomeServiceRequest> requests) async {
    final now = DateTime.now().toUtc();
    final accepted = <VisitReminderTarget>[];
    final known = <String>{};
    for (final r in requests) {
      known.add(r.id);
      final visit = r.scheduledAt;
      if (r.statusNormalized == 'accepted' &&
          visit != null &&
          visit.toUtc().isAfter(now)) {
        accepted.add(VisitReminderTarget(requestId: r.id, visitDate: visit));
      }
    }
    await ToukhVisitReminderScheduler.instance.syncVisitReminders(
      role: VisitReminderRole.provider,
      accepted: accepted,
      knownRequestIds: known,
    );
  }

  Future<void> _stop() async {
    await _requestsSub?.cancel();
    _requestsSub = null;
    _activeUid = null;
  }

  Future<void> dispose() async {
    await _authSub?.cancel();
    _authSub = null;
    await _stop();
  }
}
