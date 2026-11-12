import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:toukh_provider/domain/entities/driver_day_stats.dart';
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
    this.todayStats = const {},
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

  /// Today's orders per courier id; may include couriers no longer linked.
  final Map<String, DriverDayStats> todayStats;
  final String? actionInProgress;

  DriverDayStats statsFor(String driverId) =>
      todayStats[driverId] ?? DriverDayStats.empty;

  /// Today's totals across the linked couriers.
  DriverDayStats get teamToday => linkedDrivers.fold(
        DriverDayStats.empty,
        (sum, d) {
          final s = statsFor(d.uid);
          return sum.add(
            delivered: s.delivered,
            active: s.active,
            cancelled: s.cancelled,
          );
        },
      );

  int get onlineCount => linkedDrivers.where((d) => d.online).length;

  ManageDriversState copyWith({
    bool? loading,
    String? error,
    bool clearError = false,
    List<ProviderDriverLinkRequest>? pendingRequests,
    List<ProviderLinkedDriver>? linkedDrivers,
    Map<String, DriverDayStats>? todayStats,
    String? actionInProgress,
    bool clearAction = false,
  }) {
    return ManageDriversState(
      providerId: providerId,
      loading: loading ?? this.loading,
      error: clearError ? null : (error ?? this.error),
      pendingRequests: pendingRequests ?? this.pendingRequests,
      linkedDrivers: linkedDrivers ?? this.linkedDrivers,
      todayStats: todayStats ?? this.todayStats,
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
        todayStats,
        actionInProgress,
      ];
}

class ManageDriversCubit extends Cubit<ManageDriversState> {
  ManageDriversCubit(this._repo, this._providerId)
      : super(ManageDriversState.initial(_providerId)) {
    _watch();
  }

  final ProviderDriversRepository _repo;
  final String _providerId;
  StreamSubscription<ProviderDriversSnapshot>? _sub;
  StreamSubscription<Map<String, DriverDayStats>>? _statsSub;

  void _watch() {
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
    // Re-subscribing also moves "today" forward after midnight.
    _statsSub?.cancel();
    _statsSub = _repo.watchTodayStats(_providerId).listen(
          (stats) => emit(state.copyWith(todayStats: stats)),
          // Stats are extra: keep the lists usable if they fail.
          onError: (Object e) =>
              debugPrint('ManageDriversCubit: today stats failed: $e'),
        );
  }

  Future<bool> acceptRequest(String driverId) =>
      _respond(driverId: driverId, action: DriverLinkAction.accept);

  Future<bool> rejectRequest(String driverId) =>
      _respond(driverId: driverId, action: DriverLinkAction.reject);

  Future<bool> removeLinkedDriver({required String driverId}) =>
      _respond(driverId: driverId, action: DriverLinkAction.remove);

  /// Error value for a courier who can't be removed mid-delivery.
  static const removeBusyError = 'remove-busy';

  Future<bool> _respond({
    required String driverId,
    required DriverLinkAction action,
  }) async {
    if (state.actionInProgress != null) return false;
    emit(state.copyWith(actionInProgress: driverId, clearError: true));
    try {
      await _repo.respond(driverId: driverId, action: action);
      emit(state.copyWith(clearAction: true));
      return true;
    } on FirebaseFunctionsException catch (e) {
      final busy = action == DriverLinkAction.remove &&
          e.code == 'failed-precondition';
      emit(
        state.copyWith(
          clearAction: true,
          error: busy ? removeBusyError : e.toString(),
        ),
      );
      return false;
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
    _watch();
  }

  @override
  Future<void> close() async {
    await _sub?.cancel();
    await _statsSub?.cancel();
    return super.close();
  }
}
