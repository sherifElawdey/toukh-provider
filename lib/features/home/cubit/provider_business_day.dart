import 'package:toukh_provider/domain/entities/working_hours.dart';

/// Half-open local window `[start, end)` for the revenue card's current day.
typedef BusinessDayWindow = ({DateTime start, DateTime end});

/// The day that owns [now] for revenue, from the provider's working hours.
///
/// A 24-hour day is local midnight to the next midnight. A timed shift runs
/// from open to close, including overnight when close is earlier than open.
/// An empty [workingHours] map keeps the calendar day. A closed day with no
/// overnight tail still in progress is an empty window.
BusinessDayWindow providerBusinessDayWindow({
  required DateTime now,
  required Map<Weekday, DaySchedule> workingHours,
}) {
  final today = DateTime(now.year, now.month, now.day);
  if (workingHours.isEmpty) return _calendarDay(today);

  final yesterday = today.subtract(const Duration(days: 1));
  final yesterdayWindow = _windowForDay(yesterday, workingHours);
  if (yesterdayWindow != null && _contains(yesterdayWindow, now)) {
    return yesterdayWindow;
  }

  final todayWindow = _windowForDay(today, workingHours);
  if (todayWindow != null) return todayWindow;

  return (start: now, end: now);
}

BusinessDayWindow _calendarDay(DateTime day) {
  final start = DateTime(day.year, day.month, day.day);
  return (start: start, end: start.add(const Duration(days: 1)));
}

Weekday _weekdayOf(DateTime day) => Weekday.values[day.weekday - 1];

BusinessDayWindow? _windowForDay(
  DateTime day,
  Map<Weekday, DaySchedule> workingHours,
) {
  final schedule = workingHours[_weekdayOf(day)];
  if (schedule == null || !schedule.enabled) return null;
  if (schedule.twentyFourHours) return _calendarDay(day);

  final from = schedule.openFromMinutes;
  final to = schedule.openToMinutes;
  if (from == null || to == null) return null;
  if (from == to) return _calendarDay(day);

  final start = DateTime(
    day.year,
    day.month,
    day.day,
  ).add(Duration(minutes: from));
  final endDay = from < to ? day : day.add(const Duration(days: 1));
  final end = DateTime(
    endDay.year,
    endDay.month,
    endDay.day,
  ).add(Duration(minutes: to));
  return (start: start, end: end);
}

bool _contains(BusinessDayWindow window, DateTime instant) {
  return !instant.isBefore(window.start) && instant.isBefore(window.end);
}
