import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:toukh_provider/domain/entities/provider_review_summary.dart';
import 'package:toukh_provider/domain/repositories/provider_reviews_repository.dart';
import 'package:toukh_ui/toukh_ui.dart';

class ProviderReviewsState extends Equatable {
  const ProviderReviewsState({
    required this.loading,
    this.error,
    required this.reviews,
    this.hasMore = false,
    this.loadingMore = false,
    this.totalCount,
    this.totalAverage,
  });

  factory ProviderReviewsState.initial() => const ProviderReviewsState(
        loading: true,
        reviews: [],
      );

  final bool loading;
  final String? error;

  /// Loaded window, newest first (grows as the provider scrolls / pages).
  final List<ProviderReviewSummary> reviews;
  final bool hasMore;
  final bool loadingMore;

  /// Server aggregates over **all** reviews (null until fetched).
  final int? totalCount;
  final double? totalAverage;

  int get reviewCount => totalCount ?? reviews.length;

  double get averageRating {
    final avg = totalAverage;
    if (avg != null) return avg;
    if (reviews.isEmpty) return 0;
    final sum = reviews.fold<int>(0, (a, r) => a + r.rating);
    return sum / reviews.length;
  }

  ProviderReviewsState copyWith({
    bool? loading,
    String? error,
    bool clearError = false,
    List<ProviderReviewSummary>? reviews,
    bool? hasMore,
    bool? loadingMore,
    int? totalCount,
    double? totalAverage,
  }) {
    return ProviderReviewsState(
      loading: loading ?? this.loading,
      error: clearError ? null : (error ?? this.error),
      reviews: reviews ?? this.reviews,
      hasMore: hasMore ?? this.hasMore,
      loadingMore: loadingMore ?? this.loadingMore,
      totalCount: totalCount ?? this.totalCount,
      totalAverage: totalAverage ?? this.totalAverage,
    );
  }

  @override
  List<Object?> get props =>
      [loading, error, reviews, hasMore, loadingMore, totalCount, totalAverage];
}

class ProviderReviewsCubit extends Cubit<ProviderReviewsState> {
  ProviderReviewsCubit(this._repo, this._providerId)
      : super(ProviderReviewsState.initial()) {
    _listen();
    unawaited(_loadSummary());
  }

  final ProviderReviewsRepository _repo;
  final String _providerId;
  StreamSubscription<List<ProviderReviewSummary>>? _sub;

  static final _chunk = ToukhPageSizes.forMode(toukhDefaultPagingMode);
  int _window = _chunk;

  void _listen() {
    final window = _window;
    _sub = _repo.watchReviews(_providerId, limit: window).listen(
          (reviews) => emit(
            state.copyWith(
              loading: false,
              loadingMore: false,
              clearError: true,
              reviews: reviews,
              hasMore: reviews.length >= window,
            ),
          ),
          onError: (Object e) => emit(
            state.copyWith(
              loading: false,
              loadingMore: false,
              error: e.toString(),
            ),
          ),
        );
  }

  Future<void> _loadSummary() async {
    try {
      final s = await _repo.fetchSummary(_providerId);
      if (!isClosed) {
        emit(state.copyWith(totalCount: s.count, totalAverage: s.average));
      }
    } catch (_) {
      // Header falls back to the loaded window.
    }
  }

  /// Widens the live window by one chunk (last row reached / next page).
  Future<void> loadMore() async {
    if (!state.hasMore || state.loadingMore) return;
    _window += _chunk;
    emit(state.copyWith(loadingMore: true));
    await _sub?.cancel();
    _listen();
  }

  void retry() {
    emit(state.copyWith(loading: true, clearError: true));
    _sub?.cancel();
    _window = _chunk;
    _listen();
    unawaited(_loadSummary());
  }

  @override
  Future<void> close() async {
    await _sub?.cancel();
    return super.close();
  }
}
