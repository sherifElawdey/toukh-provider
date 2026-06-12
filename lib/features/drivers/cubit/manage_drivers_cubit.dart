import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:toukh_provider/domain/entities/provider_driver_link_request.dart';
import 'package:toukh_provider/domain/entities/provider_linked_driver.dart';
import 'package:toukh_provider/domain/repositories/provider_drivers_repository.dart';

class ManageDriversState extends Equatable {
  const ManageDriversState({
    required this.providerId,
    required this.loading,
    this.error,
    required this.pendingRequests,
    required this.linkedDrivers,
    this.actionInProgress,
  });

  factory ManageDriversState.initial(String providerId) => ManageDriversState(
        providerId: providerId,
        loading: true,
        pendingRequests: const [],
        linkedDrivers: const [],
      );

  final String providerId;
  final bool loading;
  final String? error;
  final List<ProviderDriverLinkRequest> pendingRequests;
  final List<ProviderLinkedDriver> linkedDrivers;
  final String? actionInProgress;

  ManageDriversState copyWith({
    bool? loading,
    String? error,
    bool clearError = false,
    List<ProviderDriverLinkRequest>? pendingRequests,
    List<ProviderLinkedDriver>? linkedDrivers,
    String? actionInProgress,
    bool clearAction = false,
  }) {
    return ManageDriversState(
      providerId: providerId,
      loading: loading ?? this.loading,
      error: clearError ? null : (error ?? this.error),
      pendingRequests: pendingRequests ?? this.pendingRequests,
      linkedDrivers: linkedDrivers ?? this.linkedDrivers,
      actionInProgress:
          clearAction ? null : (actionInProgress ?? this.actionInProgress),
    );
  }

  @override
  List<Object?> get props => [
        providerId,
        loading,
        error,
        pendingRequests,
        linkedDrivers,
        actionInProgress,
      ];
}

class ManageDriversCubit extends Cubit<ManageDriversState> {
  ManageDriversCubit(this._repo, this._providerId)
      : super(ManageDriversState.initial(_providerId)) {
    _sub = _repo.watchDrivers(_providerId).listen(
          (snapshot) => emit(
            state.copyWith(
              loading: false,
              clearError: true,
              pendingRequests: snapshot.pendingRequests,
              linkedDrivers: snapshot.linkedDrivers,
            ),
          ),
          onError: (Object e) => emit(
            state.copyWith(
              loading: false,
              error: e.toString(),
            ),
          ),
        );
  }

  final ProviderDriversRepository _repo;
  final String _providerId;
  StreamSubscription<ProviderDriversSnapshot>? _sub;

  Future<bool> acceptRequest(String driverId) =>
      _respond(driverId: driverId, accept: true);

  Future<bool> rejectRequest(String driverId) =>
      _respond(driverId: driverId, accept: false);

  Future<bool> _respond({
    required String driverId,
    required bool accept,
  }) async {
    if (state.actionInProgress != null) return false;
    emit(state.copyWith(actionInProgress: driverId, clearError: true));
    try {
      await _repo.respondToRequest(driverId: driverId, accept: accept);
      emit(state.copyWith(clearAction: true));
      return true;
    } catch (e) {
      emit(
        state.copyWith(
          clearAction: true,
          error: e.toString(),
        ),
      );
      return false;
    }
  }

  void retry() {
    emit(state.copyWith(loading: true, clearError: true));
    _sub?.cancel();
    _sub = _repo.watchDrivers(_providerId).listen(
          (snapshot) => emit(
            state.copyWith(
              loading: false,
              clearError: true,
              pendingRequests: snapshot.pendingRequests,
              linkedDrivers: snapshot.linkedDrivers,
            ),
          ),
          onError: (Object e) => emit(
            state.copyWith(
              loading: false,
              error: e.toString(),
            ),
          ),
        );
  }

  @override
  Future<void> close() async {
    await _sub?.cancel();
    return super.close();
  }
}
