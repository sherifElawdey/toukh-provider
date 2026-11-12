import 'package:toukh_provider/domain/entities/provider_review_summary.dart';

abstract class ProviderReviewsRepository {
  /// Newest first, live; [limit] is the loaded window.
  Stream<List<ProviderReviewSummary>> watchReviews(String providerId, {int? limit});

  /// Count and average rating across **all** reviews (server aggregate).
  Future<({int count, double average})> fetchSummary(String providerId);
}
