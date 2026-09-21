import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:toukh_provider/l10n/app_strings.dart';
import 'package:toukh_provider/shared/shared.dart';

/// Shared accept / request-driver / ready actions for list cards and detail.
class ProviderOrderActionsBar extends StatelessWidget {
  const ProviderOrderActionsBar({
    super.key,
    required this.row,
    required this.tab,
    this.busy = false,
    this.compact = true,
    this.onApprove,
    this.onReview,
    this.onCancel,
    this.onRequestDelivery,
    this.onReadyForPickup,
    this.onDeliver,
    this.onShowPickupQr,
    this.onFinish,
    this.onSeeDetails,
  });

  final ProviderMasterOrderRow row;
  final ProviderOrdersTab tab;
  final bool busy;
  final bool compact;
  final VoidCallback? onApprove;
  final VoidCallback? onReview;
  final VoidCallback? onCancel;
  final VoidCallback? onRequestDelivery;
  final VoidCallback? onReadyForPickup;
  final VoidCallback? onDeliver;
  final VoidCallback? onShowPickupQr;
  final VoidCallback? onFinish;
  final VoidCallback? onSeeDetails;

  static const _compactButtonHeight = 45.0;

  double get _buttonHeight => compact ? _compactButtonHeight : 48;

  @override
  Widget build(BuildContext context) {
    if (tab == ProviderOrdersTab.incoming) {
      return Row(
        children: [
          Expanded(
            child: AppOutlinedButton(
              text: AppStrings.Orders.actionCancel.tr,
              size: AppButtonSize.small,
              height: _buttonHeight,
              status: busy ? AppButtonStatus.loading : AppButtonStatus.enabled,
              onTap: busy ? null : onCancel,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: AppFilledButton(
              text: onReview != null
                  ? AppStrings.Orders.pharmacyReviewOrder.tr
                  : AppStrings.Orders.actionApprove.tr,
              height: _buttonHeight,
              size: AppButtonSize.small,
              status: busy ? AppButtonStatus.loading : AppButtonStatus.enabled,
              onTap: busy ? null : (onReview ?? onApprove),
            ),
          ),
        ],
      );
    }

    if (tab == ProviderOrdersTab.inProgress) {
      return _InProgressActions(
        row: row,
        busy: busy,
        buttonHeight: _buttonHeight,
        onRequestDelivery: onRequestDelivery,
        onReadyForPickup: onReadyForPickup,
        onDeliver: onDeliver,
        onShowPickupQr: onShowPickupQr,
      );
    }

    if (tab == ProviderOrdersTab.outgoing &&
        !row.hasAssignedDriverEffective &&
        onFinish != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppFilledButton(
            text: AppStrings.Orders.actionFinishOrder.tr,
            height: _buttonHeight,
            size: AppButtonSize.small,
            status: busy ? AppButtonStatus.loading : AppButtonStatus.enabled,
            onTap: busy ? null : onFinish,
          ),
          if (onSeeDetails != null) ...[
            const SizedBox(height: 6),
            AppTextButton(
              text: AppStrings.Orders.seeDetails.tr,
              size: AppButtonSize.small,
              onTap: onSeeDetails,
            ),
          ],
        ],
      );
    }

    if (onSeeDetails != null) {
      return AppTextButton(
        text: AppStrings.Orders.seeDetails.tr,
        size: AppButtonSize.small,
        onTap: onSeeDetails,
      );
    }
    return const SizedBox.shrink();
  }
}

/// Stateful so the 15‑minute count-up can flip to Re-request without a
/// Firestore rebuild.
class _InProgressActions extends StatefulWidget {
  const _InProgressActions({
    required this.row,
    required this.busy,
    required this.buttonHeight,
    this.onRequestDelivery,
    this.onReadyForPickup,
    this.onDeliver,
    this.onShowPickupQr,
  });

  final ProviderMasterOrderRow row;
  final bool busy;
  final double buttonHeight;
  final VoidCallback? onRequestDelivery;
  final VoidCallback? onReadyForPickup;
  final VoidCallback? onDeliver;
  final VoidCallback? onShowPickupQr;

  @override
  State<_InProgressActions> createState() => _InProgressActionsState();
}

class _InProgressActionsState extends State<_InProgressActions> {
  /// Set when the local count-up hits 15:00 (or model already expired).
  bool _localSearchTimedOut = false;
  DateTime? _fallbackSearchStartedAt;

  @override
  void initState() {
    super.initState();
    _syncFromRow();
  }

  @override
  void didUpdateWidget(covariant _InProgressActions oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldStart = oldWidget.row.effectiveDeliveryRequestedAt;
    final newStart = widget.row.effectiveDeliveryRequestedAt;
    final oldSearching = oldWidget.row.isSearchingForDriver;
    final newSearching = widget.row.isSearchingForDriver;
    if (oldStart != newStart ||
        oldSearching != newSearching ||
        oldWidget.row.id != widget.row.id) {
      _syncFromRow();
    }
  }

  void _syncFromRow() {
    if (widget.row.hasAssignedDriverEffective) {
      _localSearchTimedOut = false;
      _fallbackSearchStartedAt = null;
      return;
    }
    if (widget.row.isDriverSearchExpired()) {
      _localSearchTimedOut = true;
      return;
    }
    if (widget.row.isSearchingForDriver ||
        widget.row.slice.statusWire ==
            ProviderOrderStatusWire.courierRequested) {
      if (widget.row.effectiveDeliveryRequestedAt == null) {
        _fallbackSearchStartedAt ??= DateTime.now().toUtc();
      } else {
        _fallbackSearchStartedAt = null;
      }
      // Fresh search / unresolved timestamp — keep counting.
      if (!widget.row.isDriverSearchExpired()) {
        _localSearchTimedOut = false;
      }
    } else {
      _fallbackSearchStartedAt = null;
      _localSearchTimedOut = false;
    }
  }

  DateTime? get _searchStartedAt =>
      widget.row.effectiveDeliveryRequestedAt ?? _fallbackSearchStartedAt;

  bool get _showSearching {
    if (widget.row.hasAssignedDriverEffective) return false;
    if (_localSearchTimedOut) return false;
    if (widget.row.isSearchingForDriver) return true;
    return widget.row.slice.statusWire ==
            ProviderOrderStatusWire.courierRequested &&
        !_localSearchTimedOut;
  }

  bool get _showRerequest {
    if (widget.row.hasAssignedDriverEffective) return false;
    if (_showSearching) return false;
    if (_localSearchTimedOut) return true;
    return widget.row.canRequestDelivery && widget.row.showRerequestDriverLabel;
  }

  bool get _showFirstRequest {
    if (widget.row.hasAssignedDriverEffective) return false;
    if (_showSearching || _showRerequest) return false;
    return widget.row.canRequestDelivery && !widget.row.showRerequestDriverLabel;
  }

  void _onSearchTimedOut() {
    if (!mounted || _localSearchTimedOut) return;
    setState(() => _localSearchTimedOut = true);
  }

  @override
  Widget build(BuildContext context) {
    final buttons = <Widget>[];

    if (_showSearching) {
      buttons.add(
        DriverSearchStatusPanel(
          searchStartedAt: _searchStartedAt,
          onTimedOut: _onSearchTimedOut,
        ),
      );
    }

    if (_showRerequest) {
      buttons.add(
        AppFilledButton(
          text: AppStrings.Orders.actionRerequestDriver.tr,
          height: widget.buttonHeight,
          size: AppButtonSize.small,
          status:
              widget.busy ? AppButtonStatus.loading : AppButtonStatus.enabled,
          onTap: widget.busy ? null : widget.onRequestDelivery,
        ),
      );
    } else if (_showFirstRequest) {
      buttons.add(
        AppFilledButton(
          text: AppStrings.Orders.actionRequestDelivery.tr,
          height: widget.buttonHeight,
          size: AppButtonSize.small,
          status:
              widget.busy ? AppButtonStatus.loading : AppButtonStatus.enabled,
          onTap: widget.busy ? null : widget.onRequestDelivery,
        ),
      );
    }

    if (widget.row.canMarkReadyForPickup) {
      buttons.add(
        AppFilledButton(
          text: AppStrings.Orders.actionReadyForPickup.tr,
          height: widget.buttonHeight,
          size: AppButtonSize.small,
          status:
              widget.busy ? AppButtonStatus.loading : AppButtonStatus.enabled,
          onTap: widget.busy ? null : widget.onReadyForPickup,
        ),
      );
    }
    if (widget.row.isAwaitingStoreDriverAccept) {
      buttons.add(
        Material(
          color: AppColors.warning.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.spaceMd,
              vertical: AppSizes.spaceSm,
            ),
            child: CustomText(
              AppStrings.Orders.awaitingDriverApproval.tr,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: AppSizes.fontCaption,
                color: AppColors.warning,
              ),
            ),
          ),
        ),
      );
      if (widget.onDeliver != null) {
        buttons.add(
          AppOutlinedButton(
            text: AppStrings.Orders.actionChangeDriver.tr,
            height: widget.buttonHeight,
            size: AppButtonSize.small,
            status: widget.busy
                ? AppButtonStatus.loading
                : AppButtonStatus.enabled,
            onTap: widget.busy ? null : widget.onDeliver,
          ),
        );
      }
    } else if (widget.row.canStoreDeliver) {
      buttons.add(
        AppFilledButton(
          text: AppStrings.Orders.actionDeliver.tr,
          height: widget.buttonHeight,
          size: AppButtonSize.small,
          status:
              widget.busy ? AppButtonStatus.loading : AppButtonStatus.enabled,
          onTap: widget.busy ? null : widget.onDeliver,
        ),
      );
    }
    if (widget.row.canShowPickupQr) {
      buttons.add(
        AppFilledButton(
          text: AppStrings.Orders.actionShowPickupQr.tr,
          height: widget.buttonHeight,
          size: AppButtonSize.small,
          status:
              widget.busy ? AppButtonStatus.loading : AppButtonStatus.enabled,
          onTap: widget.busy ? null : widget.onShowPickupQr,
        ),
      );
    }
    if (buttons.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < buttons.length; i++) ...[
          if (i > 0) const SizedBox(height: 6),
          buttons[i],
        ],
      ],
    );
  }
}

/// Live count-up while looking for a courier (00:00 → 15:00).
class DriverSearchStatusPanel extends StatefulWidget {
  const DriverSearchStatusPanel({
    super.key,
    required this.searchStartedAt,
    this.onTimedOut,
  });

  final DateTime? searchStartedAt;
  final VoidCallback? onTimedOut;

  @override
  State<DriverSearchStatusPanel> createState() =>
      _DriverSearchStatusPanelState();
}

class _DriverSearchStatusPanelState extends State<DriverSearchStatusPanel> {
  Timer? _timer;
  Duration _elapsed = Duration.zero;
  late DateTime _startedAt;
  bool _timedOutNotified = false;

  @override
  void initState() {
    super.initState();
    _startedAt = (widget.searchStartedAt ?? DateTime.now()).toUtc();
    _tick();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  @override
  void didUpdateWidget(covariant DriverSearchStatusPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    final next = widget.searchStartedAt;
    if (next != null && next.toUtc() != _startedAt) {
      _startedAt = next.toUtc();
      _timedOutNotified = false;
      _tick();
    }
  }

  void _tick() {
    if (!mounted) return;
    final diff = DateTime.now().toUtc().difference(_startedAt);
    final elapsed = diff.isNegative ? Duration.zero : diff;
    setState(() => _elapsed = elapsed);
    if (!_timedOutNotified && elapsed >= kDriverSearchTimeout) {
      _timedOutNotified = true;
      widget.onTimedOut?.call();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _formatCountUp(Duration d) {
    final total = d.inSeconds.clamp(0, kDriverSearchTimeout.inSeconds);
    final m = (total ~/ 60).toString().padLeft(2, '0');
    final s = (total % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final display = _formatCountUp(_elapsed);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.appColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.appColor,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomText(
                  AppStrings.Orders.searchingForDriver.tr,
                  style: t.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
                CustomText(
                  AppStrings.Orders.searchingForDriverTimer.trParams({
                    'elapsed': display,
                  }),
                  style: t.bodySmall?.copyWith(
                    color: AppColors.onSurface.withValues(alpha: 0.65),
                  ),
                ),
              ],
            ),
          ),
          CustomText(
            display,
            style: t.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}
