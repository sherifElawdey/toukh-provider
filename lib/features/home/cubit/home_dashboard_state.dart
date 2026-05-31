import 'package:equatable/equatable.dart';
import 'package:toukh_provider/domain/entities/provider_dashboard_order.dart';
import 'package:toukh_provider/domain/entities/provider_review_summary.dart';

enum DashboardChartPeriod { week, month }

/// One bar/point in the orders-over-time chart (calendar day, local).
class OrderRateBucket extends Equatable {
  const OrderRateBucket({required this.dayStart, required this.count});

  final DateTime dayStart;
  final int count;

  @override
  List<Object?> get props => [dayStart, count];
}

class DashboardPeriodMetrics extends Equatable {
  const DashboardPeriodMetrics({
    required this.ordersPlaced,
    required this.completionRatio,
    required this.revenueEgp,
    required this.denominatorForCompletion,
    required this.completedCount,
    required this.ordersCanceled,
  });

  final int ordersPlaced;

  /// Share of accepted-stage orders that reached delivered (0–1).
  final double completionRatio;
  final double revenueEgp;
  final int denominatorForCompletion;
  final int completedCount;

  /// Orders with [OrderStatus.cancelled] in the selected period window.
  final int ordersCanceled;

  @override
  List<Object?> get props => [
        ordersPlaced,
        completionRatio,
        revenueEgp,
        denominatorForCompletion,
        completedCount,
        ordersCanceled,
      ];
}

class BestsellerRow extends Equatable {
  const BestsellerRow({
    required this.label,
    this.itemId,
    required this.unitsSold,
    required this.revenueEgp,
  });

  final String label;
  final String? itemId;
  final int unitsSold;
  final double revenueEgp;

  @override
  List<Object?> get props => [label, itemId, unitsSold, revenueEgp];
}

class HomeDashboardState extends Equatable {
  const HomeDashboardState({
    required this.loading,
    this.errorMessage,
    required this.authenticated,
    required this.providerDisplayName,
    required this.orders,
    required this.reviews,
    required this.chartPeriod,
    required this.walletBalanceEgp,
    this.walletPendingEgp,
    required this.showMenuInsights,
    required this.inProgressOrders,
    required this.weekMetrics,
    required this.monthMetrics,
    required this.chartBuckets,
    required this.bestsellers,
    required this.visibleReviews,
  });

  final bool loading;
  final String? errorMessage;
  final bool authenticated;

  /// First name or full display label for greeting.
  final String providerDisplayName;

  final List<ProviderOrderDashboard> orders;
  final List<ProviderReviewSummary> reviews;

  final DashboardChartPeriod chartPeriod;

  final double walletBalanceEgp;
  final double? walletPendingEgp;

  final bool showMenuInsights;

  final List<ProviderOrderDashboard> inProgressOrders;

  final DashboardPeriodMetrics weekMetrics;
  final DashboardPeriodMetrics monthMetrics;

  final List<OrderRateBucket> chartBuckets;

  final List<BestsellerRow> bestsellers;

  final List<ProviderReviewSummary> visibleReviews;

  DashboardPeriodMetrics get metricsForSelectedPeriod =>
      chartPeriod == DashboardChartPeriod.week ? weekMetrics : monthMetrics;

  factory HomeDashboardState.initial() {
    return HomeDashboardState(
      loading: true,
      authenticated: false,
      providerDisplayName: '',
      orders: const [],
      reviews: const [],
      chartPeriod: DashboardChartPeriod.week,
      walletBalanceEgp: 0,
      walletPendingEgp: null,
      showMenuInsights: false,
      inProgressOrders: const [],
      weekMetrics: _emptyMetrics,
      monthMetrics: _emptyMetrics,
      chartBuckets: const [],
      bestsellers: const [],
      visibleReviews: const [],
    );
  }

  static const _emptyMetrics = DashboardPeriodMetrics(
    ordersPlaced: 0,
    completionRatio: 0,
    revenueEgp: 0,
    denominatorForCompletion: 0,
    completedCount: 0,
    ordersCanceled: 0,
  );

  HomeDashboardState copyWith({
    bool? loading,
    String? errorMessage,
    bool? authenticated,
    String? providerDisplayName,
    List<ProviderOrderDashboard>? orders,
    List<ProviderReviewSummary>? reviews,
    DashboardChartPeriod? chartPeriod,
    double? walletBalanceEgp,
    double? walletPendingEgp,
    bool? showMenuInsights,
    List<ProviderOrderDashboard>? inProgressOrders,
    DashboardPeriodMetrics? weekMetrics,
    DashboardPeriodMetrics? monthMetrics,
    List<OrderRateBucket>? chartBuckets,
    List<BestsellerRow>? bestsellers,
    List<ProviderReviewSummary>? visibleReviews,
    bool clearError = false,
  }) {
    return HomeDashboardState(
      loading: loading ?? this.loading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      authenticated: authenticated ?? this.authenticated,
      providerDisplayName: providerDisplayName ?? this.providerDisplayName,
      orders: orders ?? this.orders,
      reviews: reviews ?? this.reviews,
      chartPeriod: chartPeriod ?? this.chartPeriod,
      walletBalanceEgp: walletBalanceEgp ?? this.walletBalanceEgp,
      walletPendingEgp: walletPendingEgp ?? this.walletPendingEgp,
      showMenuInsights: showMenuInsights ?? this.showMenuInsights,
      inProgressOrders: inProgressOrders ?? this.inProgressOrders,
      weekMetrics: weekMetrics ?? this.weekMetrics,
      monthMetrics: monthMetrics ?? this.monthMetrics,
      chartBuckets: chartBuckets ?? this.chartBuckets,
      bestsellers: bestsellers ?? this.bestsellers,
      visibleReviews: visibleReviews ?? this.visibleReviews,
    );
  }

  @override
  List<Object?> get props => [
        loading,
        errorMessage,
        authenticated,
        providerDisplayName,
        orders,
        reviews,
        chartPeriod,
        walletBalanceEgp,
        walletPendingEgp,
        showMenuInsights,
        inProgressOrders,
        weekMetrics,
        monthMetrics,
        chartBuckets,
        bestsellers,
        visibleReviews,
      ];
}
