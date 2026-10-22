import 'package:equatable/equatable.dart';

/// Totals for a period, as returned by the company stats callables.
class CourierPeriodSummary extends Equatable {
  const CourierPeriodSummary({
    this.orders = 0,
    this.cancelled = 0,
    this.earningsEgp = 0,
    this.distanceMeters = 0,
  });

  final int orders;
  final int cancelled;
  final double earningsEgp;
  final double distanceMeters;

  double get distanceKm => distanceMeters / 1000;

  factory CourierPeriodSummary.fromMap(Object? raw) {
    final m = _map(raw);
    return CourierPeriodSummary(
      orders: _int(m['orders']),
      cancelled: _int(m['cancelled']),
      earningsEgp: _double(m['earningsEgp']),
      distanceMeters: _double(m['distanceMeters']),
    );
  }

  @override
  List<Object?> get props => [orders, cancelled, earningsEgp, distanceMeters];
}

/// One bar in the daily / weekly charts.
class CourierStatsPoint extends Equatable {
  const CourierStatsPoint({required this.date, required this.summary});

  /// Cairo calendar day (daily) or first day of the week (weekly).
  final DateTime date;
  final CourierPeriodSummary summary;

  static CourierStatsPoint? tryParse(Object? raw, String dateKey) {
    final m = _map(raw);
    final date = DateTime.tryParse('${m[dateKey] ?? ''}');
    if (date == null) return null;
    return CourierStatsPoint(
      date: date,
      summary: CourierPeriodSummary.fromMap(m),
    );
  }

  @override
  List<Object?> get props => [date, summary];
}

/// A delivery or ride the courier is handling right now.
class CourierActiveJob extends Equatable {
  const CourierActiveJob({
    required this.id,
    required this.orderId,
    required this.isRide,
    required this.status,
    this.pickupLabel,
    this.dropoffLabel,
    this.feeEgp = 0,
    this.startedAt,
    this.courierId,
    this.courierName,
  });

  final String id;
  final String orderId;
  final bool isRide;
  final String status;
  final String? pickupLabel;
  final String? dropoffLabel;
  final double feeEgp;
  final DateTime? startedAt;

  /// Set on fleet-wide lists.
  final String? courierId;
  final String? courierName;

  factory CourierActiveJob.fromMap(
    Object? raw, {
    String? courierId,
    String? courierName,
  }) {
    final m = _map(raw);
    return CourierActiveJob(
      id: '${m['id'] ?? ''}',
      orderId: '${m['orderId'] ?? m['id'] ?? ''}',
      isRide: m['type'] == 'ride',
      status: '${m['status'] ?? ''}',
      pickupLabel: _str(m['pickupLabel']),
      dropoffLabel: _str(m['dropoffLabel']),
      feeEgp: _double(m['feeEgp']),
      startedAt: DateTime.tryParse('${m['startedAt'] ?? ''}')?.toLocal(),
      courierId: courierId,
      courierName: courierName,
    );
  }

  @override
  List<Object?> get props => [
    id,
    orderId,
    isRide,
    status,
    pickupLabel,
    dropoffLabel,
    feeEgp,
    startedAt,
    courierId,
    courierName,
  ];
}

/// Detailed numbers for one courier (`getCompanyCourierStats`).
class CourierStats extends Equatable {
  const CourierStats({
    required this.today,
    required this.week,
    required this.month,
    required this.daily,
    required this.weekly,
    required this.breakdown,
    required this.activeJobs,
  });

  final CourierPeriodSummary today;
  final CourierPeriodSummary week;
  final CourierPeriodSummary month;
  final List<CourierStatsPoint> daily;
  final List<CourierStatsPoint> weekly;

  /// Completed trips over 30 days by type (`restaurants`, `ride`, …),
  /// largest first.
  final List<MapEntry<String, int>> breakdown;
  final List<CourierActiveJob> activeJobs;

  factory CourierStats.fromMap(Map<String, dynamic> m) {
    final breakdown =
        _map(m['breakdown']).entries
            .map((e) => MapEntry(e.key, _int(e.value)))
            .where((e) => e.value > 0)
            .toList()
          ..sort((a, b) => b.value.compareTo(a.value));
    return CourierStats(
      today: CourierPeriodSummary.fromMap(m['today']),
      week: CourierPeriodSummary.fromMap(m['week']),
      month: CourierPeriodSummary.fromMap(m['month']),
      daily: _list(m['daily'])
          .map((e) => CourierStatsPoint.tryParse(e, 'day'))
          .whereType<CourierStatsPoint>()
          .toList(),
      weekly: _list(m['weekly'])
          .map((e) => CourierStatsPoint.tryParse(e, 'weekStart'))
          .whereType<CourierStatsPoint>()
          .toList(),
      breakdown: breakdown,
      activeJobs: _list(m['activeJobs']).map(CourierActiveJob.fromMap).toList(),
    );
  }

  @override
  List<Object?> get props => [
    today,
    week,
    month,
    daily,
    weekly,
    breakdown,
    activeJobs,
  ];
}

/// Today's numbers for the whole fleet (`getCompanyFleetOverview`).
class FleetOverview extends Equatable {
  const FleetOverview({
    required this.totals,
    required this.todayByCourier,
    required this.activeJobs,
  });

  static const empty = FleetOverview(
    totals: CourierPeriodSummary(),
    todayByCourier: {},
    activeJobs: [],
  );

  final CourierPeriodSummary totals;
  final Map<String, CourierPeriodSummary> todayByCourier;
  final List<CourierActiveJob> activeJobs;

  factory FleetOverview.fromMap(Map<String, dynamic> m) {
    final today = <String, CourierPeriodSummary>{};
    final jobs = <CourierActiveJob>[];
    _map(m['couriers']).forEach((id, raw) {
      final c = _map(raw);
      today[id] = CourierPeriodSummary.fromMap(c['today']);
      final name = _str(c['name']);
      for (final j in _list(c['activeJobs'])) {
        jobs.add(CourierActiveJob.fromMap(j, courierId: id, courierName: name));
      }
    });
    jobs.sort(
      (a, b) =>
          (b.startedAt ?? DateTime(0)).compareTo(a.startedAt ?? DateTime(0)),
    );
    return FleetOverview(
      totals: CourierPeriodSummary.fromMap(m['totals']),
      todayByCourier: today,
      activeJobs: jobs,
    );
  }

  @override
  List<Object?> get props => [totals, todayByCourier, activeJobs];
}

/// One job of a company courier (`getCompanyOrders`): live or finished.
class CompanyOrder extends Equatable {
  const CompanyOrder({
    required this.id,
    required this.orderId,
    required this.isRide,
    required this.status,
    required this.active,
    required this.cancelled,
    this.pickupLabel,
    this.dropoffLabel,
    this.feeEgp = 0,
    this.distanceMeters = 0,
    this.at,
    this.courierId,
    this.courierName,
  });

  final String id;
  final String orderId;
  final bool isRide;

  /// Wire status: live (`assigned`, `picked_up`, …) or terminal
  /// (`delivered`, `completed`, `cancelled`).
  final String status;
  final bool active;
  final bool cancelled;
  final String? pickupLabel;
  final String? dropoffLabel;
  final double feeEgp;
  final double distanceMeters;

  /// Start time for live jobs, finish time for the rest.
  final DateTime? at;
  final String? courierId;
  final String? courierName;

  bool get delivered => !active && !cancelled;

  factory CompanyOrder.fromMap(Object? raw) {
    final m = _map(raw);
    final cancelled = m['cancelled'] == true;
    return CompanyOrder(
      id: '${m['id'] ?? ''}',
      orderId: '${m['orderId'] ?? m['id'] ?? ''}',
      isRide: m['type'] == 'ride',
      status: '${m['status'] ?? ''}',
      active: m['active'] == true,
      cancelled: cancelled,
      pickupLabel: _str(m['pickupLabel']),
      dropoffLabel: _str(m['dropoffLabel']),
      feeEgp: _double(m['feeEgp']),
      distanceMeters: _double(m['distanceMeters']),
      at: DateTime.tryParse('${m['at'] ?? ''}')?.toLocal(),
      courierId: _str(m['courierId']),
      courierName: _str(m['courierName']),
    );
  }

  @override
  List<Object?> get props => [
    id,
    orderId,
    isRide,
    status,
    active,
    cancelled,
    pickupLabel,
    dropoffLabel,
    feeEgp,
    distanceMeters,
    at,
    courierId,
    courierName,
  ];
}

/// One courier's share of the fleet earnings.
class CompanyCourierEarnings extends Equatable {
  const CompanyCourierEarnings({
    required this.courierId,
    required this.name,
    required this.today,
    required this.week,
    required this.month,
  });

  final String courierId;
  final String name;
  final CourierPeriodSummary today;
  final CourierPeriodSummary week;
  final CourierPeriodSummary month;

  factory CompanyCourierEarnings.fromMap(Object? raw) {
    final m = _map(raw);
    return CompanyCourierEarnings(
      courierId: '${m['courierId'] ?? ''}',
      name: _str(m['name']) ?? '—',
      today: CourierPeriodSummary.fromMap(m['today']),
      week: CourierPeriodSummary.fromMap(m['week']),
      month: CourierPeriodSummary.fromMap(m['month']),
    );
  }

  @override
  List<Object?> get props => [courierId, name, today, week, month];
}

/// Fleet earnings report (`getCompanyEarnings`). Money is held in each
/// courier's own wallet; this is reporting only.
class CompanyEarnings extends Equatable {
  const CompanyEarnings({
    required this.today,
    required this.week,
    required this.month,
    required this.daily,
    required this.couriers,
  });

  final CourierPeriodSummary today;
  final CourierPeriodSummary week;
  final CourierPeriodSummary month;
  final List<CourierStatsPoint> daily;

  /// Highest 30-day earnings first.
  final List<CompanyCourierEarnings> couriers;

  factory CompanyEarnings.fromMap(Map<String, dynamic> m) {
    return CompanyEarnings(
      today: CourierPeriodSummary.fromMap(m['today']),
      week: CourierPeriodSummary.fromMap(m['week']),
      month: CourierPeriodSummary.fromMap(m['month']),
      daily: _list(m['daily'])
          .map((e) => CourierStatsPoint.tryParse(e, 'day'))
          .whereType<CourierStatsPoint>()
          .toList(),
      couriers: _list(
        m['couriers'],
      ).map(CompanyCourierEarnings.fromMap).toList(),
    );
  }

  @override
  List<Object?> get props => [today, week, month, daily, couriers];
}

Map<String, dynamic> _map(Object? raw) =>
    raw is Map ? raw.map((k, v) => MapEntry('$k', v)) : const {};

List<Object?> _list(Object? raw) => raw is List ? raw : const [];

int _int(Object? v) => v is num ? v.toInt() : int.tryParse('$v') ?? 0;

double _double(Object? v) =>
    v is num ? v.toDouble() : double.tryParse('$v') ?? 0;

String? _str(Object? v) => v is String && v.trim().isNotEmpty ? v.trim() : null;
