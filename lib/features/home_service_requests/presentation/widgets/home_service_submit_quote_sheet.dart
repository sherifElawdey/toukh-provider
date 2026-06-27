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

Future<bool?> showHomeServiceSubmitQuoteSheet(
  BuildContext context, {
  required ProviderHomeServiceRequest request,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (ctx) => BlocProvider.value(
      value: getIt<ProviderHomeServiceRequestsCubit>(),
      child: _HomeServiceSubmitQuoteSheet(request: request),
    ),
  );
}

class _HomeServiceSubmitQuoteSheet extends StatefulWidget {
  const _HomeServiceSubmitQuoteSheet({required this.request});

  final ProviderHomeServiceRequest request;

  @override
  State<_HomeServiceSubmitQuoteSheet> createState() =>
      _HomeServiceSubmitQuoteSheetState();
}

class _HomeServiceSubmitQuoteSheetState
    extends State<_HomeServiceSubmitQuoteSheet> {
  late final TextEditingController _price;
  DateTime? _scheduledAt;
  bool _useClientPrice = true;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    final client = widget.request.clientPriceEgp ?? 0;
    _price = TextEditingController(
      text: client > 0 ? client.round().toString() : '0',
    );
  }

  @override
  void dispose() {
    _price.dispose();
    super.dispose();
  }

  double? _parsedPrice() {
    return double.tryParse(_price.text.replaceAll(',', '').trim());
  }

  void _syncClientPrice() {
    final client = widget.request.clientPriceEgp ?? 0;
    _price.text = client.round().toString();
  }

  Future<void> _pickDateTime() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _scheduledAt ?? now,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: now.add(const Duration(days: 365)),
    );
    if (!mounted || date == null) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_scheduledAt ?? now),
    );
    if (!mounted || time == null) return;
    setState(() {
      _scheduledAt = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  Future<void> _submit() async {
    final price = _parsedPrice();
    if (price == null || price < 0) {
      AppSnack.show(
        context,
        message: AppStrings.HomeServiceRequests.quoteInvalidPrice.tr,
        state: AppSnackState.warning,
        icon: ToukhIcons.warning,
      );
      return;
    }
    final scheduled = _scheduledAt;
    if (scheduled == null) {
      AppSnack.show(
        context,
        message: AppStrings.HomeServiceRequests.quoteVisitDateRequired.tr,
        state: AppSnackState.warning,
        icon: ToukhIcons.clock,
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      await context.read<ProviderHomeServiceRequestsCubit>().submitQuote(
            requestId: widget.request.id,
            quotedPriceEgp: price,
            scheduledAt: scheduled,
          );
      await getIt<CustomerHomeServiceQuoteNotifyService>().notifyQuote(
        requestId: widget.request.id,
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
      AppSnack.show(
        context,
        message: AppStrings.HomeServiceRequests.quoteSent.tr,
        state: AppSnackState.success,
        icon: ToukhIcons.success,
      );
    } catch (e) {
      if (!mounted) return;
      AppSnack.show(
        context,
        message: appFirebaseError(e),
        state: AppSnackState.error,
        icon: ToukhIcons.error,
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final clientPrice = widget.request.clientPriceEgp;
    final locale = Localizations.localeOf(context).toString();
    final scheduledLabel = _scheduledAt == null
        ? AppStrings.HomeServiceRequests.quotePickVisitDate.tr
        : DateFormat.yMMMd().add_jm().format(_scheduledAt!.toLocal());

    return Padding(
      padding: EdgeInsets.only(
        left: AppSizes.spaceXl,
        right: AppSizes.spaceXl,
        top: AppSizes.spaceSm,
        bottom: MediaQuery.paddingOf(context).bottom + AppSizes.spaceXl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CustomText(
            AppStrings.HomeServiceRequests.quoteSheetTitle.tr,
            style: TextStyle(
              fontSize: AppSizes.fontTitle,
              fontWeight: FontWeight.w800,
              color: scheme.onSurface,
            ),
          ),
          const SizedBox(height: AppSizes.spaceMd),
          if (clientPrice != null && clientPrice > 0) ...[
            CustomText(
              AppStrings.HomeServiceRequests.quoteClientPriceLabel.trParams({
                'price': NumberFormat.decimalPattern(locale)
                    .format(clientPrice.round()),
              }),
              style: TextStyle(
                color: scheme.onSurface.withValues(alpha: 0.72),
                fontSize: AppSizes.fontBody,
              ),
            ),
            const SizedBox(height: AppSizes.spaceSm),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: CustomText(
                AppStrings.HomeServiceRequests.quoteUseClientPrice.tr,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              value: _useClientPrice,
              onChanged: (v) {
                setState(() {
                  _useClientPrice = v;
                  if (v) _syncClientPrice();
                });
              },
            ),
          ],
          TextField(
            controller: _price,
            enabled: !_useClientPrice,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: AppStrings.HomeServiceRequests.quotePriceLabel.tr,
              suffixText: 'EGP',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSizes.radiusMd),
              ),
            ),
            onChanged: (_) {
              if (_useClientPrice) {
                setState(() => _useClientPrice = false);
              }
            },
          ),
          const SizedBox(height: AppSizes.spaceMd),
          OutlinedButton.icon(
            onPressed: _submitting ? null : _pickDateTime,
            icon: Icon(ToukhIcons.calendar),
            label: CustomText(scheduledLabel),
          ),
          const SizedBox(height: AppSizes.spaceLg),
          AppFilledButton(
            text: AppStrings.HomeServiceRequests.quoteSendToClient,
            onTap: _submitting ? null : _submit,
            status: _submitting
                ? AppButtonStatus.disabled
                : AppButtonStatus.enabled,
          ),
        ],
      ),
    );
  }
}
