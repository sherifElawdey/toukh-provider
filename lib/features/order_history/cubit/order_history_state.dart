import 'package:equatable/equatable.dart';
import 'package:toukh_provider/domain/entities/order_history_stats.dart';
import 'package:toukh_ui/toukh_ui.dart';

class OrderHistoryState extends Equatable {
  const OrderHistoryState({
    this.stats = const OrderHistoryStats.zero(),
    this.items = const [],
    this.loading = false,
    this.loadingMore = false,
    this.statsLoading = false,
    this.hasMore = true,
    this.dateFrom,
    this.dateTo,
    this.error,
  });

  final OrderHistoryStats stats;
  final List<ProviderMasterOrderRow> items;
  final bool loading;
  final bool loadingMore;
  final bool statsLoading;
  final bool hasMore;
  final DateTime? dateFrom;
  final DateTime? dateTo;
  final String? error;

  OrderHistoryState copyWith({
    OrderHistoryStats? stats,
    List<ProviderMasterOrderRow>? items,
    bool? loading,
    bool? loadingMore,
    bool? statsLoading,
    bool? hasMore,
    DateTime? dateFrom,
    DateTime? dateTo,
    bool clearDateFrom = false,
    bool clearDateTo = false,
    String? error,
    bool clearError = false,
  }) {
    return OrderHistoryState(
      stats: stats ?? this.stats,
      items: items ?? this.items,
      loading: loading ?? this.loading,
      loadingMore: loadingMore ?? this.loadingMore,
      statsLoading: statsLoading ?? this.statsLoading,
      hasMore: hasMore ?? this.hasMore,
      dateFrom: clearDateFrom ? null : (dateFrom ?? this.dateFrom),
      dateTo: clearDateTo ? null : (dateTo ?? this.dateTo),
      error: clearError ? null : (error ?? this.error),
    );
  }

  @override
  List<Object?> get props => [
        stats,
        items,
        loading,
        loadingMore,
        statsLoading,
        hasMore,
        dateFrom,
        dateTo,
        error,
      ];
}
