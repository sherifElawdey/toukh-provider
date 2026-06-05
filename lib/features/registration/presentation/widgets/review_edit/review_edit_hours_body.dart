import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:toukh_provider/domain/entities/working_hours.dart';
import 'package:toukh_provider/features/registration/cubit/registration_cubit.dart';
import 'package:toukh_provider/l10n/app_strings.dart';
import 'package:toukh_ui/toukh_ui.dart';

class ReviewEditHoursBody extends StatefulWidget {
  const ReviewEditHoursBody({super.key});

  @override
  State<ReviewEditHoursBody> createState() => ReviewEditHoursBodyState();
}

class ReviewEditHoursBodyState extends State<ReviewEditHoursBody> {
  late Map<Weekday, bool> _dayOpen;
  late bool _twentyFourHours;
  late int _openFromMinutes;
  late int _openToMinutes;

  @override
  void initState() {
    super.initState();
    final wh = context.read<RegistrationCubit>().state.workingHours;
    _dayOpen = {for (final d in Weekday.values) d: wh[d]!.enabled};

    DaySchedule? template;
    for (final d in Weekday.values) {
      final s = wh[d]!;
      if (s.enabled) {
        template = s;
        break;
      }
    }
    template ??= const DaySchedule(
      enabled: true,
      twentyFourHours: false,
      openFromMinutes: 9 * 60,
      openToMinutes: 22 * 60,
    );
    _twentyFourHours = template.twentyFourHours;
    _openFromMinutes = template.openFromMinutes ?? 9 * 60;
    _openToMinutes = template.openToMinutes ?? 22 * 60;
  }

  Map<Weekday, DaySchedule> _buildResult() {
    return {
      for (final d in Weekday.values)
        d: DaySchedule(
          enabled: _dayOpen[d]!,
          twentyFourHours: _twentyFourHours,
          openFromMinutes: _twentyFourHours ? null : _openFromMinutes,
          openToMinutes: _twentyFourHours ? null : _openToMinutes,
        ),
    };
  }

  Future<void> _pickTime({required bool from}) async {
    final initial = from ? _openFromMinutes : _openToMinutes;
    final t = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: initial ~/ 60, minute: initial % 60),
    );
    if (t == null) return;
    setState(() {
      final m = t.hour * 60 + t.minute;
      if (from) {
        _openFromMinutes = m;
      } else {
        _openToMinutes = m;
      }
    });
  }

  String _fmt(int m) {
    final h = m ~/ 60;
    final mm = m % 60;
    return '${h.toString().padLeft(2, '0')}:${mm.toString().padLeft(2, '0')}';
  }

  String _weekdayLabel(Weekday d) {
    final locale = Get.locale ?? const Locale('en');
    final idx = Weekday.values.indexOf(d);
    final dt = DateTime(2024, 1, 1 + idx);
    return DateFormat.EEEE(locale.toLanguageTag()).format(dt);
  }

  bool save(BuildContext context) {
    if (!_dayOpen.values.any((v) => v)) {
      AppSnack.show(
        context,
        message: AppStrings.Registration.hoursSelectOneDay.tr,
        state: AppSnackState.warning,
        icon: PhosphorIconsRegular.calendarX,
      );
      return false;
    }
    if (!_twentyFourHours && _openFromMinutes >= _openToMinutes) {
      AppSnack.show(
        context,
        message: AppStrings.Registration.hoursEndAfterStart.tr,
        state: AppSnackState.warning,
        icon: ToukhIcons.clock,
      );
      return false;
    }
    context.read<RegistrationCubit>().setWorkingHours(_buildResult());
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final hasDay = _dayOpen.values.any((v) => v);

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
            for (final d in Weekday.values)
              FilterChip(
                label: Text(_weekdayLabel(d)),
                selected: _dayOpen[d]!,
                showCheckmark: false,
                onSelected: (v) => setState(() => _dayOpen[d] = v),
              ),
          ],
        ),
        SizedBox(height: AppSizes.spaceXl),
        Text(
          AppStrings.Registration.hoursForAllDays.tr,
          style: TextStyle(
            fontSize: AppSizes.fontTitle,
            fontWeight: FontWeight.w700,
            color: scheme.onSurface,
          ),
        ),
        SizedBox(height: AppSizes.spaceMd),
        Opacity(
          opacity: hasDay ? 1 : 0.45,
          child: IgnorePointer(
            ignoring: !hasDay,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSizes.spaceMd),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: CustomText(AppStrings.Registration.hoursOpen24h.tr),
                      value: _twentyFourHours,
                      onChanged: hasDay
                          ? (v) => setState(() => _twentyFourHours = v)
                          : null,
                    ),
                    if (!_twentyFourHours) ...[
                      SizedBox(height: AppSizes.spaceSm),
                      Row(
                        children: [
                          Expanded(
                            child: AppOutlinedButton(
                              text: _fmt(_openFromMinutes),
                              status: hasDay
                                  ? AppButtonStatus.enabled
                                  : AppButtonStatus.disabled,
                              onTap: () => _pickTime(from: true),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: AppOutlinedButton(
                              text: _fmt(_openToMinutes),
                              status: hasDay
                                  ? AppButtonStatus.enabled
                                  : AppButtonStatus.disabled,
                              onTap: () => _pickTime(from: false),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
