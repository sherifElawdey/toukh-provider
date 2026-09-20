import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'package:toukh_provider/domain/entities/provider_wallet_transaction.dart';
import 'package:toukh_provider/domain/repositories/provider_wallet_repository.dart';

class WalletState extends Equatable {
  const WalletState({
    required this.balance,
    this.pendingEgp,
    required this.recent,
  });

  factory WalletState.initial() => const WalletState(
        balance: 0,
        recent: [],
      );

  final double balance;
  final double? pendingEgp;
  final List<ProviderWalletTransaction> recent;

  /// Prefer last platform fee (app / customer service); fall back to earnings.
  ProviderWalletTransaction? get lastFeeOrEarning {
    for (final t in recent) {
      if (t.isPlatformFee) return t;
    }
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
  }) {
    return WalletState(
      balance: balance ?? this.balance,
      pendingEgp: clearPending ? null : (pendingEgp ?? this.pendingEgp),
      recent: recent ?? this.recent,
    );
  }

  @override
  List<Object?> get props => [
        balance,
        pendingEgp,
        recent,
      ];
}

class WalletCubit extends Cubit<WalletState> {
  WalletCubit(this._repo, this._providerId) : super(WalletState.initial()) {
    _summarySub = _repo.watchWalletSummary(_providerId).listen(_onSummary);
    _recentSub =
        _repo.watchRecentTransactions(_providerId, limit: 10).listen(_onRecent);
  }

  final ProviderWalletRepository _repo;
  final String _providerId;

  StreamSubscription<ProviderWalletSummary>? _summarySub;
  StreamSubscription<List<ProviderWalletTransaction>>? _recentSub;

  double _latestBalance = 0;
  double? _latestPending;
  List<ProviderWalletTransaction> _latestRecent = const [];

  /// Re-subscribe to the wallet streams so fresh values are pulled in.
  Future<void> refresh() async {
    await _summarySub?.cancel();
    await _recentSub?.cancel();
    _summarySub = _repo.watchWalletSummary(_providerId).listen(_onSummary);
    _recentSub =
        _repo.watchRecentTransactions(_providerId, limit: 10).listen(_onRecent);
  }

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
