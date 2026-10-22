import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:toukh_provider/domain/entities/company_courier.dart';
import 'package:toukh_provider/domain/entities/company_courier_stats.dart';
import 'package:toukh_provider/domain/repositories/delivery_company_repository.dart';

class CompanyFleetState extends Equatable {
  const CompanyFleetState({
    required this.companyId,
    this.loading = true,
    this.couriers = const [],
    this.overview = FleetOverview.empty,
    this.overviewLoading = false,
    this.overviewFailed = false,
    this.actionInProgress,
    this.actionError,
  });

  final String companyId;
  final bool loading;

  /// Live from Firestore: joined couriers and join requests.
  final List<CompanyCourier> couriers;

  /// Today's numbers from `getCompanyFleetOverview`.
  final FleetOverview overview;
  final bool overviewLoading;
  final bool overviewFailed;
  final String? actionInProgress;
  final String? actionError;

  List<CompanyCourier> get members =>
      couriers.where((c) => c.approved).toList();

  List<CompanyCourier> get requests =>
      couriers.where((c) => !c.approved).toList()..sort(
        (a, b) => (b.requestedAt ?? DateTime(0)).compareTo(
          a.requestedAt ?? DateTime(0),
        ),
      );

  CompanyFleetState copyWith({
    bool? loading,
    List<CompanyCourier>? couriers,
    FleetOverview? overview,
    bool? overviewLoading,
    bool? overviewFailed,
    String? actionInProgress,
    bool clearAction = false,
    String? actionError,
    bool clearActionError = false,
  }) {
    return CompanyFleetState(
      companyId: companyId,
      loading: loading ?? this.loading,
      couriers: couriers ?? this.couriers,
      overview: overview ?? this.overview,
      overviewLoading: overviewLoading ?? this.overviewLoading,
      overviewFailed: overviewFailed ?? this.overviewFailed,
      actionInProgress: clearAction
          ? null
          : (actionInProgress ?? this.actionInProgress),
      actionError: clearActionError ? null : (actionError ?? this.actionError),
    );
  }

  @override
  List<Object?> get props => [
    companyId,
    loading,
    couriers,
    overview,
    overviewLoading,
    overviewFailed,
    actionInProgress,
    actionError,
  ];
}

class CompanyFleetCubit extends Cubit<CompanyFleetState> {
  CompanyFleetCubit(this._repo, String companyId)
    : super(CompanyFleetState(companyId: companyId)) {
    _watch();
    _timer = Timer.periodic(_overviewInterval, (_) => refreshOverview());
  }

  static const _overviewInterval = Duration(minutes: 2);

  final DeliveryCompanyRepository _repo;
  StreamSubscription<List<CompanyCourier>>? _sub;
  Timer? _timer;
  Set<String> _memberIds = const {};
  Set<String> _busyIds = const {};

  void _watch() {
    _sub?.cancel();
    _sub = _repo
        .watchCouriers(state.companyId)
        .listen(
          (list) {
            emit(state.copyWith(loading: false, couriers: list));
            // Membership or busy changes alter the overview: reload it.
            final members = {
              for (final c in list)
                if (c.approved) c.uid,
            };
            final busy = {
              for (final c in list)
                if (c.approved && c.isBusy) c.uid,
            };
            if (!setEquals(members, _memberIds) || !setEquals(busy, _busyIds)) {
              _memberIds = members;
              _busyIds = busy;
              refreshOverview();
            }
          },
          onError: (Object e) {
            debugPrint('CompanyFleetCubit: couriers watch failed: $e');
            emit(state.copyWith(loading: false));
          },
        );
  }

  Future<void> refreshOverview() async {
    if (state.overviewLoading || isClosed) return;
    emit(state.copyWith(overviewLoading: true));
    try {
      final overview = await _repo.fetchFleetOverview();
      if (isClosed) return;
      emit(
        state.copyWith(
          overview: overview,
          overviewLoading: false,
          overviewFailed: false,
        ),
      );
    } catch (e) {
      debugPrint('CompanyFleetCubit: overview failed: $e');
      if (isClosed) return;
      emit(state.copyWith(overviewLoading: false, overviewFailed: true));
    }
  }

  Future<void> refresh() async {
    _watch();
    await refreshOverview();
  }

  Future<bool> accept(String driverId) => _run(
    driverId,
    () => _repo.respondToCourier(
      driverId: driverId,
      action: CourierRequestAction.accept,
    ),
  );

  Future<bool> reject(String driverId) => _run(
    driverId,
    () => _repo.respondToCourier(
      driverId: driverId,
      action: CourierRequestAction.reject,
    ),
  );

  Future<bool> _run(String driverId, Future<void> Function() action) async {
    if (state.actionInProgress != null) return false;
    emit(state.copyWith(actionInProgress: driverId, clearActionError: true));
    try {
      await action();
      emit(state.copyWith(clearAction: true));
      return true;
    } catch (e) {
      emit(state.copyWith(clearAction: true, actionError: e.toString()));
      return false;
    }
  }

  @override
  Future<void> close() async {
    _timer?.cancel();
    await _sub?.cancel();
    return super.close();
  }
}
