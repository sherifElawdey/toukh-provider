import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:toukh_provider/core/firebase/app_firebase_errors.dart';
import 'package:toukh_provider/di/service_locator.dart';
import 'package:toukh_provider/domain/repositories/provider_home_service_requests_repository.dart';
import 'package:toukh_provider/l10n/app_strings.dart';
import 'package:toukh_ui/toukh_ui.dart';

Future<bool?> showHomeServiceCancelRequestSheet(
  BuildContext context, {
  required String requestId,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (ctx) => _ReasonSheet(
      title: AppStrings.HomeServiceRequests.actionsCancelRequest.tr,
      reasonLabel: AppStrings.HomeServiceRequests.cancelReasonLabel.tr,
      hint: AppStrings.HomeServiceRequests.cancelPenaltyHint.tr,
      onSubmit: (reason) async {
        await getIt<ProviderHomeServiceRequestsRepository>().cancelRequest(
          requestId: requestId,
          reason: reason,
        );
      },
    ),
  );
}

class _ReasonSheet extends StatefulWidget {
  const _ReasonSheet({
    required this.title,
    required this.reasonLabel,
    required this.onSubmit,
    this.hint,
  });

  final String title;
  final String reasonLabel;
  final String? hint;
  final Future<void> Function(String reason) onSubmit;

  @override
  State<_ReasonSheet> createState() => _ReasonSheetState();
}

class _ReasonSheetState extends State<_ReasonSheet> {
  final _reason = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final reason = _reason.text.trim();
    if (reason.isEmpty) {
      AppSnack.show(
        context,
        message: widget.reasonLabel,
        state: AppSnackState.warning,
      );
      return;
    }
    setState(() => _sending = true);
    try {
      await widget.onSubmit(reason);
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
            widget.title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          if (widget.hint != null) ...[
            const SizedBox(height: AppSizes.spaceSm),
            CustomText(
              widget.hint!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    height: 1.35,
                  ),
            ),
          ],
          const SizedBox(height: AppSizes.spaceMd),
          TextField(
            controller: _reason,
            maxLines: 3,
            decoration: InputDecoration(labelText: widget.reasonLabel),
          ),
          const SizedBox(height: AppSizes.spaceLg),
          AppFilledButton(
            text: widget.title,
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
