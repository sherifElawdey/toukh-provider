import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:toukh_provider/domain/entities/working_hours.dart';
import 'package:toukh_provider/l10n/app_strings.dart';
import 'package:toukh_ui/toukh_ui.dart';

/// Working-day chips, the 24-hour switch, and per-day times.
class WorkingHoursForm extends StatefulWidget {
  const WorkingHoursForm({
    super.key,
    required this.initial,
  });

  final Map<Weekday, DaySchedule> initial;

  @override
  WorkingHoursFormState createState() => WorkingHoursFormState();
}

class WorkingHoursFormState extends State<WorkingHoursForm> {
  late Map<Weekday, bool> _dayOpen;
  late bool _twentyFourHours;
  late Map<Weekday, _DayTimes> _times;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    _dayOpen = {
      for (final day in Weekday.values) day: initial[day]?.enabled ?? false,
    };
    final enabled = Weekday.values.where((day) => _dayOpen[day]!);
    _twentyFourHours =
        enabled.isNotEmpty && enabled.every((day) => initial[day]!.twentyFourHours);
    _times = {
      for (final day in Weekday.values) day: _DayTimes.fromSchedule(initial[day]),
    };
  }

  /// Saved schedules, or null when the form shows a validation message.
  Map<Weekday, DaySchedule>? validate() {
    if (!_dayOpen.values.any((open) => open)) {
      _warn(
        AppStrings.Registration.hoursSelectOneDay.tr,
        PhosphorIconsRegular.calendarX,
      );
      return null;
    }
    if (!_twentyFourHours) {
      for (final day in Weekday.values) {
        if (!_dayOpen[day]!) continue;
        final times = _times[day]!;
        if (!times.overnight && times.openFrom >= times.openTo) {
          _warn(AppStrings.Registration.hoursEndAfterStart.tr, ToukhIcons.clock);
          return null;
        }
        if (times.overnight && times.openFrom <= times.openTo) {
          _warn(
            AppStrings.Registration.hoursOvernightEarlier.tr,
            ToukhIcons.clock,
          );
          return null;
        }
      }
    }
    return {
      for (final day in Weekday.values)
        day: DaySchedule(
          enabled: _dayOpen[day]!,
          twentyFourHours: _twentyFourHours,
          openFromMinutes: _twentyFourHours ? null : _times[day]!.openFrom,
          openToMinutes: _twentyFourHours ? null : _times[day]!.openTo,
          overnight: _twentyFourHours ? false : _times[day]!.overnight,
        ),
    };
  }

  void _warn(String message, IconData icon) {
    AppSnack.show(
      context,
      message: message,
      state: AppSnackState.warning,
      icon: icon,
    );
  }

  Future<void> _pickTime(Weekday day, {required bool from}) async {
    final times = _times[day]!;
    final initial = from ? times.openFrom : times.openTo;
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: initial ~/ 60, minute: initial % 60),
    );
    if (picked == null) return;
    setState(() {
      final minutes = picked.hour * 60 + picked.minute;
      _times[day] = from
          ? times.copyWith(openFrom: minutes)
          : times.copyWith(openTo: minutes);
    });
  }

  String _fmt(int minutes) {
    final hour = minutes ~/ 60;
    final minute = minutes % 60;
    return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
  }

  String _clock(int minutes) {
    final locale = Get.locale?.toLanguageTag();
    final clock = DateTime(2024, 1, 1, minutes ~/ 60, minutes % 60);
    return DateFormat.jm(locale).format(clock);
  }

  String _weekdayLabel(Weekday day) {
    final locale = Get.locale ?? const Locale('en');
    final index = Weekday.values.indexOf(day);
    return DateFormat.EEEE(locale.toLanguageTag()).format(DateTime(2024, 1, 1 + index));
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final hasDay = _dayOpen.values.any((open) => open);
    final selected = Weekday.values.where((day) => _dayOpen[day]!).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          AppStrings.Registration.hoursWorkingDays.tr,
          style: TextStyle(
            fontSize: AppSizes.fontTitle,
            fontWeight: FontWeight.w700,
            color: scheme.onSurface,
          ),
        ),
        SizedBox(height: AppSizes.spaceXs),
        Text(
          AppStrings.Registration.hoursWorkingDaysHint.tr,
          style: TextStyle(
            fontSize: AppSizes.fontBody,
            color: scheme.onSurface.withValues(alpha: 0.72),
            height: 1.4,
          ),
        ),
        SizedBox(height: AppSizes.spaceMd),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final day in Weekday.values)
              FilterChip(
                label: Text(_weekdayLabel(day)),
                selected: _dayOpen[day]!,
                showCheckmark: false,
                onSelected: (open) => setState(() => _dayOpen[day] = open),
              ),
          ],
        ),
        SizedBox(height: AppSizes.spaceXl),
        Opacity(
          opacity: hasDay ? 1 : 0.45,
          child: IgnorePointer(
            ignoring: !hasDay,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSizes.spaceMd),
                child: SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: CustomText(AppStrings.Registration.hoursOpen24h.tr),
                  value: _twentyFourHours,
                  onChanged: hasDay
                      ? (value) => setState(() => _twentyFourHours = value)
                      : null,
                ),
              ),
            ),
          ),
        ),
        if (hasDay && !_twentyFourHours) ...[
          for (final day in selected) ...[
            SizedBox(height: AppSizes.spaceMd),
            Text(
              _weekdayLabel(day),
              style: TextStyle(
                fontSize: AppSizes.fontTitle,
                fontWeight: FontWeight.w700,
                color: scheme.onSurface,
              ),
            ),
            SizedBox(height: AppSizes.spaceSm),
            Row(
              children: [
                Expanded(
                  child: AppOutlinedButton(
                    text: _fmt(_times[day]!.openFrom),
                    onTap: () => _pickTime(day, from: true),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: AppOutlinedButton(
                    text: _fmt(_times[day]!.openTo),
                    onTap: () => _pickTime(day, from: false),
                  ),
                ),
              ],
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: CustomText(AppStrings.Registration.hoursOvernight.tr),
              value: _times[day]!.overnight,
              onChanged: (value) => setState(() {
                _times[day] = _times[day]!.copyWith(overnight: value);
              }),
            ),
            if (_times[day]!.overnight)
              Text(
                AppStrings.Registration.hoursClosesNextDay.trParams({
                  'time': _clock(_times[day]!.openTo),
                }),
                style: TextStyle(
                  fontSize: AppSizes.fontBody,
                  color: scheme.onSurface.withValues(alpha: 0.72),
                ),
              ),
          ],
        ],
      ],
    );
  }
}

/// Compact hours line for review and profile. Mixed days are listed separately.
String summarizeWorkingHours(Map<Weekday, DaySchedule> hours) {
  final openDays = [
    for (final day in Weekday.all)
      if (hours[day]?.enabled == true) day,
  ];
  if (openDays.isEmpty) return '—';
  if (openDays.every((day) => hours[day]!.twentyFourHours)) {
    return '${AppStrings.Registration.hoursOpen24h.tr} · ${openDays.length}';
  }

  String fmt(int minutes) {
    final hour = minutes ~/ 60;
    final minute = minutes % 60;
    return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
  }

  String one(DaySchedule schedule) {
    final range =
        '${fmt(schedule.openFromMinutes ?? 0)}–${fmt(schedule.openToMinutes ?? 0)}';
    return schedule.overnight ? '$range +1' : range;
  }

  final first = one(hours[openDays.first]!);
  if (openDays.every((day) => one(hours[day]!) == first)) {
    return '${openDays.length} · $first';
  }

  final locale = Get.locale?.toLanguageTag();
  return openDays.map((day) {
    final index = Weekday.values.indexOf(day);
    final label = DateFormat.E(locale).format(DateTime(2024, 1, 1 + index));
    return '$label ${one(hours[day]!)}';
  }).join(' · ');
}

class _DayTimes {
  const _DayTimes({
    required this.openFrom,
    required this.openTo,
    required this.overnight,
  });

  factory _DayTimes.fromSchedule(DaySchedule? schedule) {
    return _DayTimes(
      openFrom: schedule?.openFromMinutes ?? 9 * 60,
      openTo: schedule?.openToMinutes ?? 22 * 60,
      overnight: schedule?.overnight ?? false,
    );
  }

  final int openFrom;
  final int openTo;
  final bool overnight;

  _DayTimes copyWith({
    int? openFrom,
    int? openTo,
    bool? overnight,
  }) {
    return _DayTimes(
      openFrom: openFrom ?? this.openFrom,
      openTo: openTo ?? this.openTo,
      overnight: overnight ?? this.overnight,
    );
  }
}
