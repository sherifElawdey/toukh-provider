import 'package:equatable/equatable.dart';
import 'package:toukh_provider/domain/entities/provider_dashboard_order.dart';
import 'package:toukh_provider/domain/entities/provider_review_summary.dart';

/// Raw orders + reviews from dashboard repository before cubit aggregates.
class DashboardFirestorePayload extends Equatable {
  const DashboardFirestorePayload({
    required this.orders,
    required this.reviews,
    this.usedMockFallback = false,
  });

  final List<ProviderOrderDashboard> orders;
  final List<ProviderReviewSummary> reviews;

  /// True when [HybridProviderDashboardRepository] substituted demo data.
  final bool usedMockFallback;

  @override
  List<Object?> get props => [orders, reviews, usedMockFallback];
}
