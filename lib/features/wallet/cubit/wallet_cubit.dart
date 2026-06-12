import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'package:toukh_provider/domain/entities/provider_wallet_transaction.dart';
import 'package:toukh_provider/domain/repositories/provider_wallet_repository.dart';

enum WalletChartPeriod { week, month, year }

class WalletChartPoint extends Equatable {
  const WalletChartPoint({
    required this.x,
    required this.y,
    required this.label,
  });

  final double x;
  final double y;
  final String label;

  @override
  List<Object?> get props => [x, y, label];
}

class WalletState extends Equatable {
  const WalletState({
    required this.balance,
    this.pendingEgp,
    required this.recent,
    required this.chartPeriod,
    required this.chartPoints,
    required this.chartMaxY,
    required this.chartLoading,
  });

  factory WalletState.initial() => const WalletState(
        balance: 0,
        recent: [],
        chartPeriod: WalletChartPeriod.week,
        chartPoints: [],
        chartMaxY: 1,
        chartLoading: true,
      );

  final double balance;
  final double? pendingEgp;
  final List<ProviderWalletTransaction> recent;
  final WalletChartPeriod chartPeriod;
  final List<WalletChartPoint> chartPoints;
  final double chartMaxY;
  final bool chartLoading;

  ProviderWalletTransaction? get lastEarning {
    for (final t in recent) {
      if (t.isEarning) return t;
    }
    return null;
  }

  WalletState copyWith({
    double? balance,
    double? pendingEgp,
    bool clearPending = false,
    List<ProviderWalletTransaction>? recent,
    WalletChartPeriod? chartPeriod,
    List<WalletChartPoint>? chartPoints,
    double? chartMaxY,
    bool? chartLoading,
  }) {
    return WalletState(
      balance: balance ?? this.balance,
      pendingEgp: clearPending ? null : (pendingEgp ?? this.pendingEgp),
      recent: recent ?? this.recent,
      chartPeriod: chartPeriod ?? this.chartPeriod,
      chartPoints: chartPoints ?? this.chartPoints,
      chartMaxY: chartMaxY ?? this.chartMaxY,
      chartLoading: chartLoading ?? this.chartLoading,
    );
  }

  @override
  List<Object?> get props => [
        balance,
        pendingEgp,
        recent,
        chartPeriod,
        chartPoints,
        chartMaxY,
        chartLoading,
      ];
}

DateTime _dateOnlyLocal(DateTime d) => DateTime(d.year, d.month, d.day);

({DateTime start, DateTime end}) _chartBounds(WalletChartPeriod p) {
  final now = DateTime.now();
  final end = now;
  switch (p) {
    case WalletChartPeriod.week:
      final today = _dateOnlyLocal(now);
      final start = today.subtract(const Duration(days: 6));
      return (start: start, end: end);
    case WalletChartPeriod.month:
      final start = DateTime(now.year, now.month, 1);
      return (start: start, end: end);
    case WalletChartPeriod.year:
      final start = DateTime(now.year, 1, 1);
      return (start: start, end: end);
  }
}

({List<WalletChartPoint> points, double maxY}) _aggregateChart(
  List<ProviderWalletTransaction> txs,
  WalletChartPeriod period,
) {
  final now = DateTime.now();
  switch (period) {
    case WalletChartPeriod.week:
      final today = _dateOnlyLocal(now);
      final points = <WalletChartPoint>[];
      var maxY = 0.0;
      for (var i = 0; i < 7; i++) {
        final day = today.subtract(Duration(days: 6 - i));
        var sum = 0.0;
        for (final t in txs) {
          final c = t.createdAt;
          if (c == null) continue;
          if (_dateOnlyLocal(c) == day) sum += t.amountEgp;
        }
        if (sum > maxY) maxY = sum;
        points.add(WalletChartPoint(
          x: i.toDouble(),
          y: sum,
          label: '${day.day}/${day.month}',
        ));
      }
      return (points: points, maxY: maxY > 0 ? maxY : 1);
    case WalletChartPeriod.month:
      final lastDay = now.day;
      final points = <WalletChartPoint>[];
      var maxY = 0.0;
      for (var day = 1; day <= lastDay; day++) {
        final bucket = DateTime(now.year, now.month, day);
        var sum = 0.0;
        for (final t in txs) {
          final c = t.createdAt;
          if (c == null) continue;
          if (_dateOnlyLocal(c) == bucket) sum += t.amountEgp;
        }
        if (sum > maxY) maxY = sum;
        points.add(WalletChartPoint(
          x: (day - 1).toDouble(),
          y: sum,
          label: '$day',
        ));
      }
      return (points: points, maxY: maxY > 0 ? maxY : 1);
    case WalletChartPeriod.year:
      final points = <WalletChartPoint>[];
      var maxY = 0.0;
      for (var m = 1; m <= 12; m++) {
        if (m > now.month) break;
        var sum = 0.0;
        for (final t in txs) {
          final c = t.createdAt;
          if (c == null) continue;
          if (c.year == now.year && c.month == m) sum += t.amountEgp;
        }
        if (sum > maxY) maxY = sum;
        const monthShort = [
          'J', 'F', 'M', 'A', 'M', 'J', 'J', 'A', 'S', 'O', 'N', 'D',
        ];
        points.add(WalletChartPoint(
          x: (m - 1).toDouble(),
          y: sum,
          label: monthShort[m - 1],
        ));
      }
      return (points: points, maxY: maxY > 0 ? maxY : 1);
  }
}

class WalletCubit extends Cubit<WalletState> {
  WalletCubit(this._repo, this._providerId) : super(WalletState.initial()) {
    _summarySub = _repo.watchWalletSummary(_providerId).listen(_onSummary);
    _recentSub =
        _repo.watchRecentTransactions(_providerId, limit: 10).listen(_onRecent);
    _refreshChart();
  }

  final ProviderWalletRepository _repo;
  final String _providerId;

  StreamSubscription<ProviderWalletSummary>? _summarySub;
  StreamSubscription<List<ProviderWalletTransaction>>? _recentSub;

  double _latestBalance = 0;
  double? _latestPending;
  List<ProviderWalletTransaction> _latestRecent = const [];

  void _onSummary(ProviderWalletSummary summary) {
    _latestBalance = summary.balanceEgp;
    _latestPending = summary.pendingEgp;
    _emitCore();
  }

  void _onRecent(List<ProviderWalletTransaction> v) {
    _latestRecent = v;
    _emitCore();
  }

  void _emitCore() {
    emit(
      state.copyWith(
        balance: _latestBalance,
        pendingEgp: _latestPending,
        recent: List<ProviderWalletTransaction>.from(_latestRecent),
      ),
    );
  }

  Future<void> _refreshChart() async {
    emit(state.copyWith(chartLoading: true));
    final bounds = _chartBounds(state.chartPeriod);
    try {
      final txs = await _repo.fetchTransactionsForChart(
        _providerId,
        bounds.start,
        bounds.end,
      );
      final agg = _aggregateChart(txs, state.chartPeriod);
      emit(
        state.copyWith(
          chartPoints: agg.points,
          chartMaxY: agg.maxY,
          chartLoading: false,
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          chartPoints: const [],
          chartMaxY: 1,
          chartLoading: false,
        ),
      );
    }
  }

  Future<void> setChartPeriod(WalletChartPeriod p) async {
    emit(state.copyWith(chartPeriod: p, chartLoading: true));
    final bounds = _chartBounds(p);
    try {
      final txs = await _repo.fetchTransactionsForChart(
        _providerId,
        bounds.start,
        bounds.end,
      );
      final agg = _aggregateChart(txs, p);
      emit(
        state.copyWith(
          chartPoints: agg.points,
          chartMaxY: agg.maxY,
          chartLoading: false,
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          chartPoints: const [],
          chartMaxY: 1,
          chartLoading: false,
        ),
      );
    }
  }

  @override
  Future<void> close() {
    _summarySub?.cancel();
    _recentSub?.cancel();
    return super.close();
  }
}

class WalletHistoryState extends Equatable {
  const WalletHistoryState({
    this.items = const [],
    this.loading = false,
    this.loadingMore = false,
    this.hasMore = true,
    this.error,
  });

  final List<ProviderWalletTransaction> items;
  final bool loading;
  final bool loadingMore;
  final bool hasMore;
  final String? error;

  WalletHistoryState copyWith({
    List<ProviderWalletTransaction>? items,
    bool? loading,
    bool? loadingMore,
    bool? hasMore,
    String? error,
    bool clearError = false,
  }) {
    return WalletHistoryState(
      items: items ?? this.items,
      loading: loading ?? this.loading,
      loadingMore: loadingMore ?? this.loadingMore,
      hasMore: hasMore ?? this.hasMore,
      error: clearError ? null : (error ?? this.error),
    );
  }

  @override
  List<Object?> get props => [items, loading, loadingMore, hasMore, error];
}

class WalletHistoryCubit extends Cubit<WalletHistoryState> {
  WalletHistoryCubit(this._repo, this._providerId)
      : super(const WalletHistoryState());

  final ProviderWalletRepository _repo;
  final String _providerId;
  static const _pageSize = 20;

  DocumentSnapshot? _cursor;

  Future<void> loadInitial() async {
    emit(state.copyWith(loading: true, clearError: true));
    _cursor = null;
    try {
      final page =
          await _repo.fetchTransactionsPage(_providerId, pageSize: _pageSize);
      _cursor = page.lastDoc;
      final hasMore = page.items.length == _pageSize && page.lastDoc != null;
      emit(
        state.copyWith(
          items: page.items,
          loading: false,
          hasMore: hasMore,
        ),
      );
    } catch (e) {
      emit(state.copyWith(loading: false, error: e.toString()));
    }
  }

  Future<void> loadMore() async {
    if (!state.hasMore || state.loadingMore || _cursor == null) return;
    emit(state.copyWith(loadingMore: true, clearError: true));
    try {
      final page = await _repo.fetchTransactionsPage(
        _providerId,
        pageSize: _pageSize,
        startAfter: _cursor,
      );
      _cursor = page.lastDoc;
      final hasMore = page.items.length == _pageSize && page.lastDoc != null;
      emit(
        state.copyWith(
          items: [...state.items, ...page.items],
          loadingMore: false,
          hasMore: hasMore,
        ),
      );
    } catch (e) {
      emit(state.copyWith(loadingMore: false, error: e.toString()));
    }
  }
}
