import 'package:equatable/equatable.dart';

/// One courier's orders for this store since midnight (device time).
class DriverDayStats extends Equatable {
  const DriverDayStats({
    this.delivered = 0,
    this.active = 0,
    this.cancelled = 0,
  });

  static const empty = DriverDayStats();

  /// Handed to the customer today.
  final int delivered;

  /// Assigned and not finished yet.
  final int active;

  /// Cancelled today after a courier was assigned.
  final int cancelled;

  int get total => delivered + active + cancelled;

  DriverDayStats add({int delivered = 0, int active = 0, int cancelled = 0}) =>
      DriverDayStats(
        delivered: this.delivered + delivered,
        active: this.active + active,
        cancelled: this.cancelled + cancelled,
      );

  @override
  List<Object?> get props => [delivered, active, cancelled];
}
