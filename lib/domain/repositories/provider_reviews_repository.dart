import 'package:toukh_provider/domain/entities/provider_review_summary.dart';

abstract class ProviderReviewsRepository {
  Stream<List<ProviderReviewSummary>> watchReviews(String providerId);
}
