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
    this.overnight = false,
  });

  final bool enabled;
  final bool twentyFourHours;
  final int? openFromMinutes;
  final int? openToMinutes;

  /// When true, [openToMinutes] is on the next calendar day.
  final bool overnight;

  DaySchedule copyWith({
    bool? enabled,
    bool? twentyFourHours,
    int? openFromMinutes,
    int? openToMinutes,
    bool? overnight,
  }) {
    return DaySchedule(
      enabled: enabled ?? this.enabled,
      twentyFourHours: twentyFourHours ?? this.twentyFourHours,
      openFromMinutes: openFromMinutes ?? this.openFromMinutes,
      openToMinutes: openToMinutes ?? this.openToMinutes,
      overnight: overnight ?? this.overnight,
    );
  }

  Map<String, dynamic> toMap() => {
    'enabled': enabled,
    'twentyFourHours': twentyFourHours,
    if (!twentyFourHours) ...{
      'openFromMinutes': openFromMinutes,
      'openToMinutes': openToMinutes,
      'overnight': overnight,
    },
  };

  static DaySchedule fromMap(Map<String, dynamic> m) {
    final from = _minutes(m['openFromMinutes']);
    final to = _minutes(m['openToMinutes']);
    final overnightRaw = m['overnight'];
    final overnight = overnightRaw is bool
        ? overnightRaw
        : (from != null && to != null && from > to);
    return DaySchedule(
      enabled: m['enabled'] as bool? ?? false,
      twentyFourHours: m['twentyFourHours'] as bool? ?? false,
      openFromMinutes: from,
      openToMinutes: to,
      overnight: overnight,
    );
  }

  @override
  List<Object?> get props => [
    enabled,
    twentyFourHours,
    openFromMinutes,
    openToMinutes,
    overnight,
  ];
}

int? _minutes(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return null;
}
