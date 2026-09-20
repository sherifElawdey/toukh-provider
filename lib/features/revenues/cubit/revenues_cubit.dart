import 'dart:async';
import 'dart:math' as math;

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:toukh_provider/domain/entities/dashboard_firestore_payload.dart';
import 'package:toukh_provider/domain/entities/provider_dashboard_order.dart';
import 'package:toukh_provider/domain/entities/provider_wallet_transaction.dart';
import 'package:toukh_provider/domain/repositories/provider_dashboard_repository.dart';
import 'package:toukh_provider/domain/repositories/provider_wallet_repository.dart';

class RevenueMonthKey extends Equatable {
  const RevenueMonthKey(this.year, this.month);

  factory RevenueMonthKey.fromDate(DateTime d) =>
      RevenueMonthKey(d.year, d.month);

  factory RevenueMonthKey.current() => RevenueMonthKey.fromDate(DateTime.now());

  final int year;
  final int month;

  DateTime get start => DateTime(year, month, 1);

  DateTime get endExclusive =>
      month == 12 ? DateTime(year + 1, 1, 1) : DateTime(year, month + 1, 1);

  bool contains(DateTime? d) {
    if (d == null) return false;
    return !d.isBefore(start) && d.isBefore(endExclusive);
  }

  String get label =>
      '${month.toString().padLeft(2, '0')}/$year';

  @override
  List<Object?> get props => [year, month];
}

class RevenueChartPoint extends Equatable {
  const RevenueChartPoint({
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

class RevenuesState extends Equatable {
  const RevenuesState({
    required this.loading,
    required this.selectedMonth,
    required this.availableMonths,
    required this.acceptedCount,
    required this.rejectedCount,
    required this.revenueEgp,
    required this.appFeesEgp,
    required this.customerServiceFeesEgp,
    required this.dailyRevenue,
    required this.dailyMaxY,
  });

  factory RevenuesState.initial() {
    final now = RevenueMonthKey.current();
    return RevenuesState(
      loading: true,
      selectedMonth: now,
      availableMonths: [now],
      acceptedCount: 0,
      rejectedCount: 0,
      revenueEgp: 0,
      appFeesEgp: 0,
      customerServiceFeesEgp: 0,
      dailyRevenue: const [],
      dailyMaxY: 1,
    );
  }

  final bool loading;
  final RevenueMonthKey selectedMonth;
  final List<RevenueMonthKey> availableMonths;
  final int acceptedCount;
  final int rejectedCount;
  final double revenueEgp;
  final double appFeesEgp;
  final double customerServiceFeesEgp;
  final List<RevenueChartPoint> dailyRevenue;
  final double dailyMaxY;

  double get totalFeesEgp => appFeesEgp + customerServiceFeesEgp;

  RevenuesState copyWith({
    bool? loading,
    RevenueMonthKey? selectedMonth,
    List<RevenueMonthKey>? availableMonths,
    int? acceptedCount,
    int? rejectedCount,
    double? revenueEgp,
    double? appFeesEgp,
    double? customerServiceFeesEgp,
    List<RevenueChartPoint>? dailyRevenue,
    double? dailyMaxY,
  }) {
    return RevenuesState(
      loading: loading ?? this.loading,
      selectedMonth: selectedMonth ?? this.selectedMonth,
      availableMonths: availableMonths ?? this.availableMonths,
      acceptedCount: acceptedCount ?? this.acceptedCount,
      rejectedCount: rejectedCount ?? this.rejectedCount,
      revenueEgp: revenueEgp ?? this.revenueEgp,
      appFeesEgp: appFeesEgp ?? this.appFeesEgp,
      customerServiceFeesEgp:
          customerServiceFeesEgp ?? this.customerServiceFeesEgp,
      dailyRevenue: dailyRevenue ?? this.dailyRevenue,
      dailyMaxY: dailyMaxY ?? this.dailyMaxY,
    );
  }

  @override
  List<Object?> get props => [
        loading,
        selectedMonth,
        availableMonths,
        acceptedCount,
        rejectedCount,
        revenueEgp,
        appFeesEgp,
        customerServiceFeesEgp,
        dailyRevenue,
        dailyMaxY,
      ];
}

class RevenuesCubit extends Cubit<RevenuesState> {
  RevenuesCubit({
    required ProviderDashboardRepository dashboardRepository,
    required ProviderWalletRepository walletRepository,
    required String providerId,
  })  : _dashboardRepository = dashboardRepository,
        _walletRepository = walletRepository,
        _providerId = providerId,
        super(RevenuesState.initial()) {
    _dashSub = _dashboardRepository
        .watchFirestorePayload(_providerId)
        .listen(_onJobs);
    _loadFees();
  }

  final ProviderDashboardRepository _dashboardRepository;
  final ProviderWalletRepository _walletRepository;
  final String _providerId;

  StreamSubscription<DashboardFirestorePayload>? _dashSub;
  List<ProviderOrderDashboard> _jobs = const [];
  List<ProviderWalletTransaction> _fees = const [];

  /// Re-subscribe to dashboard orders and re-fetch platform fees.
  Future<void> reload() async {
    await _dashSub?.cancel();
    _dashSub = _dashboardRepository
        .watchFirestorePayload(_providerId)
        .listen(_onJobs);
    await _loadFees();
  }

  Future<void> _loadFees() async {
    try {
      _fees =
          await _walletRepository.fetchPlatformFeeTransactions(_providerId);
    } catch (_) {
      _fees = const [];
    }
    _recompute();
  }

  void _onJobs(DashboardFirestorePayload payload) {
    _jobs = payload.orders;
    _recompute();
  }

  void selectMonth(RevenueMonthKey month) {
    emit(state.copyWith(selectedMonth: month));
    _recompute(keepSelected: true);
  }

  void _recompute({bool keepSelected = false}) {
    final months = _buildAvailableMonths(_jobs, _fees);
    final selected = keepSelected && months.contains(state.selectedMonth)
        ? state.selectedMonth
        : (months.isNotEmpty ? months.first : RevenueMonthKey.current());

    final monthJobs = _jobs.where((o) {
      final at = o.deliveredAt ?? o.cancelledAt ?? o.createdAt;
      return selected.contains(at);
    }).toList();

    // Prefer createdAt for accept/reject volume; fall back to delivered/cancelled.
    final accepted = _jobs.where((o) {
      if (!o.reachedAcceptedStage || o.isCancelled) return false;
      final at = o.acceptedAt ?? o.createdAt;
      return selected.contains(at);
    }).length;

    final rejected = _jobs.where((o) {
      if (!o.isCancelled) return false;
      final at = o.deliveredAt ?? o.createdAt;
      return selected.contains(at);
    }).length;

    final delivered = monthJobs.where((o) => o.isDelivered).toList();
    final revenue =
        delivered.fold<double>(0, (a, o) => a + o.revenueEgp);

    final feesInMonth = _fees.where((t) => selected.contains(t.createdAt));
    final appFees = feesInMonth
        .where((t) => t.isAppFee)
        .fold<double>(0, (a, t) => a + t.amountEgp);
    final customerServiceFees = feesInMonth
        .where((t) => t.isCustomerServiceFee)
        .fold<double>(0, (a, t) => a + t.amountEgp);

    final daily = _dailyRevenue(selected, delivered);

    emit(
      RevenuesState(
        loading: false,
        selectedMonth: selected,
        availableMonths: months,
        acceptedCount: accepted,
        rejectedCount: rejected,
        revenueEgp: revenue,
        appFeesEgp: appFees,
        customerServiceFeesEgp: customerServiceFees,
        dailyRevenue: daily.points,
        dailyMaxY: daily.maxY,
      ),
    );
  }

  static List<RevenueMonthKey> _buildAvailableMonths(
    List<ProviderOrderDashboard> jobs,
    List<ProviderWalletTransaction> fees,
  ) {
    final set = <RevenueMonthKey>{RevenueMonthKey.current()};
    for (final o in jobs) {
      final d = o.deliveredAt ?? o.createdAt;
      if (d != null) set.add(RevenueMonthKey.fromDate(d));
    }
    for (final t in fees) {
      final d = t.createdAt;
      if (d != null) set.add(RevenueMonthKey.fromDate(d));
    }
    final now = DateTime.now();
    for (var i = 0; i < 12; i++) {
      final d = DateTime(now.year, now.month - i, 1);
      set.add(RevenueMonthKey(d.year, d.month));
    }
    final list = set.toList()
      ..sort((a, b) {
        if (a.year != b.year) return b.year.compareTo(a.year);
        return b.month.compareTo(a.month);
      });
    return list.take(12).toList();
  }

  static ({List<RevenueChartPoint> points, double maxY}) _dailyRevenue(
    RevenueMonthKey month,
    List<ProviderOrderDashboard> delivered,
  ) {
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final today = DateTime.now();
    final lastDay = month.year == today.year && month.month == today.month
        ? today.day
        : daysInMonth;

    final sums = List<double>.filled(lastDay, 0);
    for (final o in delivered) {
      final d = o.deliveredAt ?? o.createdAt;
      if (d == null) continue;
      if (d.year != month.year || d.month != month.month) continue;
      final idx = d.day - 1;
      if (idx >= 0 && idx < lastDay) {
        sums[idx] += o.revenueEgp;
      }
    }

    var maxY = 0.0;
    final points = <RevenueChartPoint>[];
    for (var i = 0; i < lastDay; i++) {
      maxY = math.max(maxY, sums[i]);
      points.add(
        RevenueChartPoint(
          x: i.toDouble(),
          y: sums[i],
          label: '${i + 1}',
        ),
      );
    }
    return (points: points, maxY: maxY > 0 ? maxY : 1);
  }

  @override
  Future<void> close() {
    _dashSub?.cancel();
    return super.close();
  }
}

extension on ProviderOrderDashboard {
  DateTime? get cancelledAt => isCancelled ? deliveredAt : null;
}
