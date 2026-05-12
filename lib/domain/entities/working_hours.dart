import 'package:equatable/equatable.dart';

enum Weekday {
  mon,
  tue,
  wed,
  thu,
  fri,
  sat,
  sun;

  String get wireValue => name;

  static Weekday? tryParse(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    for (final v in Weekday.values) {
      if (v.name == raw) return v;
    }
    return null;
  }

  static List<Weekday> get all => Weekday.values;
}

/// Minutes from midnight for open/close (0–1440).
class DaySchedule extends Equatable {
  const DaySchedule({
    required this.enabled,
    required this.twentyFourHours,
    this.openFromMinutes,
    this.openToMinutes,
  });

  final bool enabled;
  final bool twentyFourHours;
  final int? openFromMinutes;
  final int? openToMinutes;

  DaySchedule copyWith({
    bool? enabled,
    bool? twentyFourHours,
    int? openFromMinutes,
    int? openToMinutes,
  }) {
    return DaySchedule(
      enabled: enabled ?? this.enabled,
      twentyFourHours: twentyFourHours ?? this.twentyFourHours,
      openFromMinutes: openFromMinutes ?? this.openFromMinutes,
      openToMinutes: openToMinutes ?? this.openToMinutes,
    );
  }

  Map<String, dynamic> toMap() => {
        'enabled': enabled,
        'twentyFourHours': twentyFourHours,
        if (!twentyFourHours) ...{
          'openFromMinutes': openFromMinutes,
          'openToMinutes': openToMinutes,
        },
      };

  static DaySchedule fromMap(Map<String, dynamic> m) {
    return DaySchedule(
      enabled: m['enabled'] as bool? ?? false,
      twentyFourHours: m['twentyFourHours'] as bool? ?? false,
      openFromMinutes: m['openFromMinutes'] as int?,
      openToMinutes: m['openToMinutes'] as int?,
    );
  }

  @override
  List<Object?> get props =>
      [enabled, twentyFourHours, openFromMinutes, openToMinutes];
}
