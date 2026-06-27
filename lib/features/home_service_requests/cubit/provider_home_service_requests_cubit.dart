import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:toukh_provider/core/firebase/app_firebase_errors.dart';
import 'package:toukh_provider/core/notifications/provider_order_alert_controller.dart';
import 'package:toukh_provider/domain/entities/provider_home_service_request.dart';
import 'package:toukh_provider/domain/repositories/provider_home_service_requests_repository.dart';
import 'package:toukh_provider/features/auth/cubit/auth_cubit.dart';
import 'package:toukh_provider/features/home_service_requests/cubit/provider_home_service_requests_state.dart';
import 'package:toukh_ui/toukh_ui.dart';

export 'provider_home_service_requests_state.dart';

class ProviderHomeServiceRequestsCubit
    extends Cubit<ProviderHomeServiceRequestsState> {
  ProviderHomeServiceRequestsCubit({
    required AuthCubit authCubit,
    required ProviderHomeServiceRequestsRepository requestsRepository,
  })  : _authCubit = authCubit,
        _requestsRepository = requestsRepository,
        super(const ProviderHomeServiceRequestsState());

  final AuthCubit _authCubit;
  final ProviderHomeServiceRequestsRepository _requestsRepository;

  StreamSubscription<List<ProviderHomeServiceRequest>>? _sub;
  String? _boundUid;
  bool _requestsStreamPrimed = false;
  final Set<String> _alertedIncomingRequestIds = {};

  void start() {
    _authCubit.stream.listen(_onAuth);
    _onAuth(_authCubit.state);
  }

  void _onAuth(AuthState auth) {
    if (auth is! Authenticated) {
      _boundUid = null;
      _sub?.cancel();
      _sub = null;
      _requestsStreamPrimed = false;
      _alertedIncomingRequestIds.clear();
      emit(const ProviderHomeServiceRequestsState(loading: false, requests: []));
      return;
    }

    final uid = auth.user.uid;
    if (_boundUid == uid) return;

    _boundUid = uid;
    _sub?.cancel();
    emit(state.copyWith(loading: true, providerUid: uid, clearError: true));

    _sub = _requestsRepository.watchRequests(uid).listen(
      (requests) {
        _maybeShowIncomingRequestAlerts(uid, requests);
        emit(state.copyWith(
          loading: false,
          requests: requests,
          clearError: true,
        ));
      },
      onError: (Object e) {
        emit(state.copyWith(
          loading: false,
          errorMessage: appFirebaseError(e),
        ));
      },
    );
  }

  Future<void> submitQuote({
    required String requestId,
    required double quotedPriceEgp,
    required DateTime scheduledAt,
  }) async {
    final uid = state.providerUid;
    if (uid == null) return;
    await _requestsRepository.submitQuote(
      requestId: requestId,
      providerId: uid,
      quotedPriceEgp: quotedPriceEgp,
      scheduledAt: scheduledAt,
    );
  }

  Future<void> decline(String requestId) async {
    final uid = state.providerUid;
    if (uid == null) return;
    await _requestsRepository.declineRequest(
      requestId: requestId,
      providerId: uid,
    );
  }

  ProviderHomeServiceRequest? requestById(String requestId) {
    for (final r in state.requests) {
      if (r.id == requestId) return r;
    }
    return null;
  }

  void _maybeShowIncomingRequestAlerts(
    String providerId,
    List<ProviderHomeServiceRequest> requests,
  ) {
    if (!_requestsStreamPrimed) {
      _requestsStreamPrimed = true;
      for (final request in requests) {
        if (request.isIncoming) {
          _alertedIncomingRequestIds.add(request.id);
        }
      }
      return;
    }

    for (final request in requests) {
      if (!request.isIncoming) continue;
      if (_alertedIncomingRequestIds.contains(request.id)) continue;
      _alertedIncomingRequestIds.add(request.id);

      final notification =
          ToukhHomeServiceNotificationTemplates.notificationFromProviderRequest(
        notificationId: request.id,
        request: _requestToNotificationMap(request),
        providerId: providerId,
        requestId: request.id,
      );
      ProviderOrderAlertController.instance.show(notification);
    }
  }

  Map<String, dynamic> _requestToNotificationMap(
    ProviderHomeServiceRequest request,
  ) {
    return {
      'userId': request.userId,
      'customerName': request.customerName,
      'categoryTitle': request.categoryTitle,
      'note': request.note,
      'status': request.status,
    };
  }

  @override
  Future<void> close() {
    _sub?.cancel();
    return super.close();
  }
}
