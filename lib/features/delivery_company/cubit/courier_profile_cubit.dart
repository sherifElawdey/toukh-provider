import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:toukh_provider/domain/entities/company_courier.dart';
import 'package:toukh_provider/domain/entities/company_courier_stats.dart';
import 'package:toukh_provider/domain/repositories/delivery_company_repository.dart';

class CourierProfileState extends Equatable {
  const CourierProfileState({
    required this.driverId,
    this.loading = true,
    this.courier,
    this.stats,
    this.statsLoading = false,
    this.statsFailed = false,
    this.busy = false,
  });

  final String driverId;
  final bool loading;

  /// Null once loaded means the courier left (or never was in) the company.
  final CompanyCourier? courier;
  final CourierStats? stats;
  final bool statsLoading;
  final bool statsFailed;

  /// Enable / disable / remove in flight.
  final bool busy;

  CourierProfileState copyWith({
    bool? loading,
    CompanyCourier? courier,
    bool clearCourier = false,
    CourierStats? stats,
    bool? statsLoading,
    bool? statsFailed,
    bool? busy,
  }) {
    return CourierProfileState(
      driverId: driverId,
      loading: loading ?? this.loading,
      courier: clearCourier ? null : (courier ?? this.courier),
      stats: stats ?? this.stats,
      statsLoading: statsLoading ?? this.statsLoading,
      statsFailed: statsFailed ?? this.statsFailed,
      busy: busy ?? this.busy,
    );
  }

  @override
  List<Object?> get props => [
    driverId,
    loading,
    courier,
    stats,
    statsLoading,
    statsFailed,
    busy,
  ];
}

class CourierProfileCubit extends Cubit<CourierProfileState> {
  CourierProfileCubit(
    this._repo, {
    required this.companyId,
    required String driverId,
  }) : super(CourierProfileState(driverId: driverId)) {
    _sub = _repo
        .watchCourier(companyId, driverId)
        .listen(
          (c) {
            final mine = c != null && c.approved;
            final wasBusy = state.courier?.isBusy;
            emit(
              state.copyWith(
                loading: false,
                courier: mine ? c : null,
                clearCourier: !mine,
              ),
            );
            // Reload active jobs when the courier picks up or finishes one.
            if (mine && (state.stats == null || wasBusy != c.isBusy)) {
              loadStats();
            }
          },
          onError: (Object e) {
            debugPrint('CourierProfileCubit: watch failed: $e');
            emit(state.copyWith(loading: false, clearCourier: true));
          },
        );
  }

  final DeliveryCompanyRepository _repo;
  final String companyId;
  StreamSubscription<CompanyCourier?>? _sub;

  Future<void> loadStats() async {
    if (state.statsLoading || isClosed) return;
    emit(state.copyWith(statsLoading: true));
    try {
      final stats = await _repo.fetchCourierStats(state.driverId);
      if (isClosed) return;
      emit(
        state.copyWith(stats: stats, statsLoading: false, statsFailed: false),
      );
    } catch (e) {
      debugPrint('CourierProfileCubit: stats failed: $e');
      if (isClosed) return;
      emit(state.copyWith(statsLoading: false, statsFailed: true));
    }
  }

  Future<bool> setEnabled(bool enabled) => _run(
    () => _repo.setCourierEnabled(driverId: state.driverId, enabled: enabled),
  );

  Future<bool> remove() => _run(
    () => _repo.respondToCourier(
      driverId: state.driverId,
      action: CourierRequestAction.remove,
    ),
  );

  Future<bool> _run(Future<void> Function() action) async {
    if (state.busy) return false;
    emit(state.copyWith(busy: true));
    try {
      await action();
      return true;
    } catch (e) {
      debugPrint('CourierProfileCubit: action failed: $e');
      return false;
    } finally {
      if (!isClosed) emit(state.copyWith(busy: false));
    }
  }

  @override
  Future<void> close() async {
    await _sub?.cancel();
    return super.close();
  }
}
