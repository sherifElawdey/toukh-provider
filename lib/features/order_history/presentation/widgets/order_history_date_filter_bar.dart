import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:toukh_provider/features/order_history/cubit/order_history_cubit.dart';
import 'package:toukh_provider/l10n/app_strings.dart';
import 'package:toukh_ui/toukh_ui.dart';

class OrderHistoryDateFilterBar extends StatefulWidget {
  const OrderHistoryDateFilterBar({super.key});

  @override
  State<OrderHistoryDateFilterBar> createState() =>
      _OrderHistoryDateFilterBarState();
}

class _OrderHistoryDateFilterBarState extends State<OrderHistoryDateFilterBar> {
  DateTime? _from;
  DateTime? _to;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;
    final state = context.read<OrderHistoryCubit>().state;
    _from = state.dateFrom;
    _to = state.dateTo;
  }

  String _formatDate(DateTime? date) {
    if (date == null) return AppStrings.OrderHistory.selectDate.tr;
    final locale = Localizations.localeOf(context).toLanguageTag();
    return DateFormat.yMMMd(locale).format(date);
  }

  bool get _hasLocalDateRange => _from != null && _to != null;

  bool _hasActiveFilter() {
    final state = context.read<OrderHistoryCubit>().state;
    return state.dateFrom != null || state.dateTo != null;
  }

  Future<void> _pickDate({required bool isFrom}) async {
    final initial = isFrom ? _from : _to;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked == null || !mounted) return;
    setState(() {
      if (isFrom) {
        _from = picked;
      } else {
        _to = picked;
      }
    });
  }

  void _apply() {
    if (!_hasLocalDateRange) return;

    if (_from!.isAfter(_to!)) {
      AppSnack.show(
        context,
        message: AppStrings.OrderHistory.invalidDateRange.tr,
        state: AppSnackState.warning,
        icon: ToukhIcons.calendar,
      );
      return;
    }
    context.read<OrderHistoryCubit>().setDateRange(_from, _to);
  }

  void _clear() {
    if (!_hasActiveFilter()) {
      if (_from != null || _to != null) {
        setState(() {
          _from = null;
          _to = null;
        });
      }
      return;
    }

    setState(() {
      _from = null;
      _to = null;
    });
    context.read<OrderHistoryCubit>().clearDateRange();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final hasActiveFilter = context.select<OrderHistoryCubit, bool>(
      (c) => c.state.dateFrom != null || c.state.dateTo != null,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: _DateChip(
                label: AppStrings.OrderHistory.dateFrom.tr,
                value: _formatDate(_from),
                onTap: () => _pickDate(isFrom: true),
              ),
            ),
            const SizedBox(width: AppSizes.spaceSm),
            Expanded(
              child: _DateChip(
                label: AppStrings.OrderHistory.dateTo.tr,
                value: _formatDate(_to),
                onTap: () => _pickDate(isFrom: false),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSizes.spaceSm),
        Row(
          children: [
            Expanded(
              child: AppFilledButton(
                text: AppStrings.OrderHistory.applyFilter.tr,
                onTap: _hasLocalDateRange ? _apply : null,
                status: _hasLocalDateRange
                    ? AppButtonStatus.enabled
                    : AppButtonStatus.disabled,
              ),
            ),
            const SizedBox(width: AppSizes.spaceSm),
            AppTextButton(
              text: AppStrings.OrderHistory.clearFilter.tr,
              onTap: hasActiveFilter ? _clear : null,
              status: hasActiveFilter
                  ? AppButtonStatus.enabled
                  : AppButtonStatus.disabled,
              foregroundColor: scheme.onSurface.withValues(alpha: 0.7),
            ),
          ],
        ),
      ],
    );
  }
}

class _DateChip extends StatelessWidget {
  const _DateChip({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Material(
      color: scheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        side: BorderSide(color: AppColors.borderSubtle),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.spaceMd,
            vertical: AppSizes.spaceSm,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomText(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: scheme.onSurface.withValues(alpha: 0.55),
                ),
              ),
              const SizedBox(height: 2),
              CustomText(
                value,
                style: TextStyle(
                  fontSize: AppSizes.fontLabel,
                  fontWeight: FontWeight.w700,
                  color: scheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
