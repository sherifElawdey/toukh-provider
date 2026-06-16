import 'package:bloc/bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:toukh_provider/domain/repositories/provider_order_history_repository.dart';

import 'order_history_state.dart';

export 'order_history_state.dart';

class OrderHistoryCubit extends Cubit<OrderHistoryState> {
  OrderHistoryCubit(this._repo, this._providerId)
      : super(const OrderHistoryState());

  final ProviderOrderHistoryRepository _repo;
  final String _providerId;
  static const _pageSize = 20;

  DocumentSnapshot<Map<String, dynamic>>? _cursor;

  Future<void> loadInitial() async {
    emit(
      state.copyWith(
        loading: true,
        statsLoading: true,
        clearError: true,
      ),
    );
    _cursor = null;
    try {
      final stats = await _repo.fetchStats(
        _providerId,
        from: state.dateFrom,
        to: state.dateTo,
      );
      final page = await _repo.fetchPage(
        _providerId,
        pageSize: _pageSize,
        from: state.dateFrom,
        to: state.dateTo,
      );
      _cursor = page.lastDoc;
      final hasMore = page.rows.length == _pageSize && page.lastDoc != null;
      emit(
        state.copyWith(
          stats: stats,
          items: page.rows,
          loading: false,
          statsLoading: false,
          hasMore: hasMore,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          loading: false,
          statsLoading: false,
          error: e.toString(),
        ),
      );
    }
  }

  Future<void> loadMore() async {
    if (!state.hasMore || state.loadingMore || _cursor == null) return;
    emit(state.copyWith(loadingMore: true, clearError: true));
    try {
      final page = await _repo.fetchPage(
        _providerId,
        pageSize: _pageSize,
        from: state.dateFrom,
        to: state.dateTo,
        startAfter: _cursor,
      );
      _cursor = page.lastDoc;
      final hasMore = page.rows.length == _pageSize && page.lastDoc != null;
      emit(
        state.copyWith(
          items: [...state.items, ...page.rows],
          loadingMore: false,
          hasMore: hasMore,
        ),
      );
    } catch (e) {
      emit(state.copyWith(loadingMore: false, error: e.toString()));
    }
  }

  Future<void> setDateRange(DateTime? from, DateTime? to) async {
    emit(
      state.copyWith(
        dateFrom: from,
        dateTo: to,
        clearDateFrom: from == null,
        clearDateTo: to == null,
      ),
    );
    await loadInitial();
  }

  Future<void> clearDateRange() async {
    emit(
      state.copyWith(
        clearDateFrom: true,
        clearDateTo: true,
      ),
    );
    await loadInitial();
  }
}
