import 'package:toukh_provider/domain/entities/working_hours.dart';
import 'package:toukh_ui/toukh_ui.dart';

/// Half-open Cairo window `[start, end)` for the revenue card's current shift.
typedef BusinessDayWindow = ({DateTime start, DateTime end});

/// The shift that owns [now] for revenue, in Cairo wall-clock time.
///
/// [now] is any instant (device local or UTC). An empty [workingHours] map
/// keeps the Cairo calendar day. A closed day with no overnight tail still
/// in progress is an empty window.
BusinessDayWindow providerBusinessDayWindow({
  DateTime? now,
  required Map<Weekday, DaySchedule> workingHours,
}) {
  final window = toukhBusinessDayWindow(
    toukhCairoNow(now),
    toukhWeekFromSchedules(workingHours),
  );
  return (start: window.start, end: window.end);
}

Map<String, ToukhDayHours> toukhWeekFromSchedules(
  Map<Weekday, DaySchedule> workingHours,
) {
  return {
    for (final entry in workingHours.entries)
      entry.key.name: ToukhDayHours(
        enabled: entry.value.enabled,
        twentyFourHours: entry.value.twentyFourHours,
        openFromMinutes: entry.value.openFromMinutes,
        openToMinutes: entry.value.openToMinutes,
        overnight: entry.value.overnight,
      ),
  };
}
