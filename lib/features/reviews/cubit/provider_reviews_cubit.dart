import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:toukh_provider/domain/entities/provider_review_summary.dart';
import 'package:toukh_provider/domain/repositories/provider_reviews_repository.dart';

class ProviderReviewsState extends Equatable {
  const ProviderReviewsState({
    required this.loading,
    this.error,
    required this.reviews,
  });

  factory ProviderReviewsState.initial() => const ProviderReviewsState(
        loading: true,
        reviews: [],
      );

  final bool loading;
  final String? error;
  final List<ProviderReviewSummary> reviews;

  int get reviewCount => reviews.length;

  double get averageRating {
    if (reviews.isEmpty) return 0;
    final sum = reviews.fold<int>(0, (a, r) => a + r.rating);
    return sum / reviews.length;
  }

  ProviderReviewsState copyWith({
    bool? loading,
    String? error,
    bool clearError = false,
    List<ProviderReviewSummary>? reviews,
  }) {
    return ProviderReviewsState(
      loading: loading ?? this.loading,
      error: clearError ? null : (error ?? this.error),
      reviews: reviews ?? this.reviews,
    );
  }

  @override
  List<Object?> get props => [loading, error, reviews];
}

class ProviderReviewsCubit extends Cubit<ProviderReviewsState> {
  ProviderReviewsCubit(this._repo, this._providerId)
      : super(ProviderReviewsState.initial()) {
    _sub = _repo.watchReviews(_providerId).listen(
          (reviews) => emit(
            state.copyWith(
              loading: false,
              clearError: true,
              reviews: reviews,
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

  final ProviderReviewsRepository _repo;
  final String _providerId;
  StreamSubscription<List<ProviderReviewSummary>>? _sub;

  void retry() {
    emit(state.copyWith(loading: true, clearError: true));
    _sub?.cancel();
    _sub = _repo.watchReviews(_providerId).listen(
          (reviews) => emit(
            state.copyWith(
              loading: false,
              clearError: true,
              reviews: reviews,
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
