import 'package:toukh_provider/domain/entities/provider_home_service_request.dart';

DateTime normalizeScheduleDay(DateTime date) {
  final local = date.toLocal();
  return DateTime(local.year, local.month, local.day);
}

const schedulePastDays = 7;
const scheduleFutureDays = 7;

enum VisitTiming { upcoming, today, overdue }

int daysUntilVisit(DateTime scheduledAt, {DateTime? anchor}) {
  final today = normalizeScheduleDay(anchor ?? DateTime.now());
  final visit = normalizeScheduleDay(scheduledAt);
  return visit.difference(today).inDays;
}

bool isVisitToday(DateTime scheduledAt, {DateTime? anchor}) =>
    daysUntilVisit(scheduledAt, anchor: anchor) == 0;

bool isVisitOverdue(DateTime scheduledAt, {DateTime? anchor}) =>
    daysUntilVisit(scheduledAt, anchor: anchor) < 0;

VisitTiming visitTimingFor(DateTime scheduledAt, {DateTime? anchor}) {
  final days = daysUntilVisit(scheduledAt, anchor: anchor);
  if (days < 0) return VisitTiming.overdue;
  if (days == 0) return VisitTiming.today;
  return VisitTiming.upcoming;
}

extension HomeServiceVisitRequestX on ProviderHomeServiceRequest {
  VisitTiming? get visitTiming {
    final scheduled = scheduledAt;
    if (scheduled == null) return null;
    return visitTimingFor(scheduled);
  }

  int? get daysUntilVisitCount {
    final scheduled = scheduledAt;
    if (scheduled == null) return null;
    return daysUntilVisit(scheduled);
  }

  bool get canMarkOnMyWay =>
      statusNormalized == 'accepted' &&
      scheduledAt != null &&
      isVisitToday(scheduledAt!);

  bool get isOverdueAccepted =>
      statusNormalized == 'accepted' &&
      scheduledAt != null &&
      isVisitOverdue(scheduledAt!);

  bool get isOnTheWay => statusNormalized == 'in_progress';

  bool get isScheduledVisitJob =>
      (statusNormalized == 'accepted' || statusNormalized == 'in_progress') &&
      scheduledAt != null;
}

/// Schedule filtering helpers for [ProviderHomeServiceRequest] lists.
extension HomeServiceScheduleListX on List<ProviderHomeServiceRequest> {
  ProviderHomeServiceRequest? get activeOnMyWayRequest {
    for (final request in this) {
      if (request.isOnTheWay) return request;
    }
    return null;
  }

  bool get hasActiveOnMyWay => activeOnMyWayRequest != null;

  List<ProviderHomeServiceRequest> acceptedScheduledJobs() {
    return where((r) => r.isScheduledVisitJob).toList();
  }

  List<DateTime> scheduleDayTabs({
    DateTime? anchor,
    int pastDays = schedulePastDays,
    int days = scheduleFutureDays,
  }) {
    final today = normalizeScheduleDay(anchor ?? DateTime.now());
    final start = today.subtract(Duration(days: pastDays));
    return List.generate(pastDays + days, (i) => start.add(Duration(days: i)));
  }

  int scheduleTodayTabIndex({
    DateTime? anchor,
    int pastDays = schedulePastDays,
  }) =>
      pastDays;

  List<ProviderHomeServiceRequest> jobsForDay(DateTime day) {
    final target = normalizeScheduleDay(day);
    final jobs = acceptedScheduledJobs()
        .where(
          (r) => normalizeScheduleDay(r.scheduledAt!) == target,
        )
        .toList();
    jobs.sort((a, b) => a.scheduledAt!.compareTo(b.scheduledAt!));
    return jobs;
  }

  int jobCountForDay(DateTime day) => jobsForDay(day).length;
}
