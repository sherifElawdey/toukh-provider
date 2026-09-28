import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:toukh_provider/core/firebase/app_firebase_errors.dart';
import 'package:toukh_provider/data/services/customer_home_service_quote_notify_service.dart';
import 'package:toukh_provider/di/service_locator.dart';
import 'package:toukh_provider/domain/entities/provider_home_service_request.dart';
import 'package:toukh_provider/features/home_service_requests/cubit/provider_home_service_requests_cubit.dart';
import 'package:toukh_provider/l10n/app_strings.dart';
import 'package:toukh_ui/toukh_ui.dart';

Future<bool?> showHomeServiceDateChangeSheet(
  BuildContext context, {
  required ProviderHomeServiceRequest request,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (ctx) => _DateChangeSheet(request: request),
  );
}

class _DateChangeSheet extends StatefulWidget {
  const _DateChangeSheet({required this.request});

  final ProviderHomeServiceRequest request;

  @override
  State<_DateChangeSheet> createState() => _DateChangeSheetState();
}

class _DateChangeSheetState extends State<_DateChangeSheet> {
  final _reason = TextEditingController();
  DateTime? _proposedAt;
  bool _sending = false;

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _proposedAt ?? now,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: now.add(const Duration(days: 365)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_proposedAt ?? now),
    );
    if (time == null || !mounted) return;
    setState(() {
      _proposedAt = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  Future<void> _send() async {
    final when = _proposedAt;
    final reason = _reason.text.trim();
    if (when == null) {
      AppSnack.show(
        context,
        message: AppStrings.HomeServiceRequests.dateChangePickDate.tr,
        state: AppSnackState.warning,
      );
      return;
    }
    if (reason.isEmpty) {
      AppSnack.show(
        context,
        message: AppStrings.HomeServiceRequests.dateChangeReason.tr,
        state: AppSnackState.warning,
      );
      return;
    }
    setState(() => _sending = true);
    try {
      await context.read<ProviderHomeServiceRequestsCubit>().proposeDateChange(
            requestId: widget.request.id,
            proposedAt: when,
            reason: reason,
          );
      await getIt<CustomerHomeServiceQuoteNotifyService>().notifyDateChange(
        requestId: widget.request.id,
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      AppSnack.show(
        context,
        message: appFirebaseError(e),
        state: AppSnackState.error,
      );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final label = _proposedAt == null
        ? AppStrings.HomeServiceRequests.dateChangePickDate.tr
        : DateFormat.yMMMd().add_jm().format(_proposedAt!.toLocal());
    return Padding(
      padding: EdgeInsets.only(
        left: AppSizes.spaceXl,
        right: AppSizes.spaceXl,
        top: AppSizes.spaceSm,
        bottom: MediaQuery.viewInsetsOf(context).bottom + AppSizes.spaceXl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CustomText(
            AppStrings.HomeServiceRequests.dateChangeTitle.tr,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: AppSizes.spaceMd),
          AppOutlinedButton(text: label, onTap: _sending ? null : _pickDate),
          const SizedBox(height: AppSizes.spaceMd),
          TextField(
            controller: _reason,
            maxLines: 3,
            decoration: InputDecoration(
              labelText: AppStrings.HomeServiceRequests.dateChangeReason.tr,
            ),
          ),
          const SizedBox(height: AppSizes.spaceLg),
          AppFilledButton(
            text: AppStrings.HomeServiceRequests.dateChangeSend.tr,
            onTap: _sending ? null : _send,
            status: _sending
                ? AppButtonStatus.loading
                : AppButtonStatus.enabled,
          ),
        ],
      ),
    );
  }
}
