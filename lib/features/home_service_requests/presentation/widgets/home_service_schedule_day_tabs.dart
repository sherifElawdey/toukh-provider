import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:toukh_provider/features/home_service_requests/cubit/home_service_schedule_helpers.dart';
import 'package:toukh_provider/l10n/app_strings.dart';
import 'package:toukh_ui/toukh_ui.dart';

class HomeServiceScheduleDayTabs extends StatefulWidget {
  const HomeServiceScheduleDayTabs({
    super.key,
    required this.days,
    required this.selectedIndex,
    required this.centerOnIndex,
    required this.jobCountForDay,
    required this.onSelected,
  });

  final List<DateTime> days;
  final int selectedIndex;
  final int centerOnIndex;
  final int Function(DateTime day) jobCountForDay;
  final ValueChanged<int> onSelected;

  @override
  State<HomeServiceScheduleDayTabs> createState() =>
      _HomeServiceScheduleDayTabsState();
}

class _HomeServiceScheduleDayTabsState extends State<HomeServiceScheduleDayTabs> {
  final _pillKeys = <GlobalKey>[];
  bool _wasTickerEnabled = false;

  @override
  void initState() {
    super.initState();
    _ensureKeys(widget.days.length);
    _centerOnOpen();
  }

  @override
  void didUpdateWidget(HomeServiceScheduleDayTabs oldWidget) {
    super.didUpdateWidget(oldWidget);
    _ensureKeys(widget.days.length);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final tickerEnabled = TickerMode.valuesOf(context).enabled;
    if (tickerEnabled && !_wasTickerEnabled) {
      _centerOnOpen();
    }
    _wasTickerEnabled = tickerEnabled;
  }

  void _ensureKeys(int count) {
    while (_pillKeys.length < count) {
      _pillKeys.add(GlobalKey());
    }
  }

  void _centerOnOpen() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final index = widget.centerOnIndex;
      if (index < 0 || index >= _pillKeys.length) return;
      final pillContext = _pillKeys[index].currentContext;
      if (pillContext == null) return;
      Scrollable.ensureVisible(
        pillContext,
        alignment: 0.5,
        duration: Duration.zero,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final today = normalizeScheduleDay(DateTime.now());
    final tomorrow = today.add(const Duration(days: 1));

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: AppSizes.screenHorizontal.copyWith(
        top: AppSizes.spaceSm,
        bottom: AppSizes.spaceSm,
      ),
      child: Row(
        children: [
          for (var i = 0; i < widget.days.length; i++) ...[
            if (i > 0) const SizedBox(width: AppSizes.spaceSm),
            _DayPill(
              key: _pillKeys[i],
              label: _dayLabel(widget.days[i], today, tomorrow),
              count: widget.jobCountForDay(widget.days[i]),
              selected: widget.selectedIndex == i,
              isToday: normalizeScheduleDay(widget.days[i]) == today,
              scheme: scheme,
              onTap: () => widget.onSelected(i),
            ),
          ],
        ],
      ),
    );
  }

  String _dayLabel(DateTime day, DateTime today, DateTime tomorrow) {
    final normalized = normalizeScheduleDay(day);
    if (normalized == today) {
      return AppStrings.HomeServiceSchedule.today.tr;
    }
    if (normalized == tomorrow) {
      return AppStrings.HomeServiceSchedule.tomorrow.tr;
    }
    return DateFormat.E().add_MMMd().format(normalized);
  }
}

class _DayPill extends StatelessWidget {
  const _DayPill({
    super.key,
    required this.label,
    required this.count,
    required this.selected,
    required this.isToday,
    required this.scheme,
    required this.onTap,
  });

  final String label;
  final int count;
  final bool selected;
  final bool isToday;
  final ColorScheme scheme;
  final VoidCallback onTap;

  Color get _backgroundColor {
    if (selected) {
      return isToday ? AppColors.secondColor : AppColors.appColor;
    }
    if (isToday) {
      return AppColors.appColor.withValues(alpha: 0.12);
    }
    return scheme.surfaceContainerHighest.withValues(alpha: 0.45);
  }

  Color get _borderColor {
    if (selected) {
      return isToday ? AppColors.secondColor : AppColors.appColor;
    }
    if (isToday) {
      return AppColors.appColor;
    }
    return scheme.outline.withValues(alpha: 0.28);
  }

  double get _borderWidth => isToday && !selected ? 1.75 : 1;

  Color get _labelColor {
    if (selected) {
      return AppColors.surface;
    }
    if (isToday) {
      return AppColors.secondColor;
    }
    return scheme.onSurface.withValues(alpha: 0.72);
  }

  Color get _badgeBackground {
    if (selected) {
      return Colors.white.withValues(alpha: 0.22);
    }
    if (isToday) {
      return AppColors.secondColor.withValues(alpha: 0.14);
    }
    return AppColors.appColor.withValues(alpha: 0.14);
  }

  Color get _badgeTextColor {
    if (selected) {
      return AppColors.surface;
    }
    if (isToday) {
      return AppColors.secondColor;
    }
    return AppColors.appColor;
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSizes.radiusFull),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: EdgeInsets.symmetric(
            horizontal: isToday ? AppSizes.spaceLg + 2 : AppSizes.spaceLg,
            vertical: isToday ? AppSizes.spaceSm + 4 : AppSizes.spaceSm + 2,
          ),
          decoration: BoxDecoration(
            color: _backgroundColor,
            borderRadius: BorderRadius.circular(AppSizes.radiusFull),
            border: Border.all(
              color: _borderColor,
              width: _borderWidth,
            ),
            boxShadow: isToday && !selected
                ? [
                    BoxShadow(
                      color: AppColors.appColor.withValues(alpha: 0.18),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isToday && !selected) ...[
                Container(
                  width: 7,
                  height: 7,
                  margin: const EdgeInsets.only(right: 8),
                  decoration: const BoxDecoration(
                    color: AppColors.appColor,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
              CustomText(
                label,
                style: TextStyle(
                  fontSize: isToday ? AppSizes.fontLabel + 1 : AppSizes.fontLabel,
                  fontWeight: isToday || selected ? FontWeight.w800 : FontWeight.w600,
                  color: _labelColor,
                ),
              ),
              if (count > 0) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: _badgeBackground,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: CustomText(
                    '$count',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: _badgeTextColor,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
