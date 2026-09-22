import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:toukh_provider/di/service_locator.dart';
import 'package:toukh_provider/domain/services/order_qr_service.dart';
import 'package:toukh_provider/features/orders/presentation/widgets/order_detail/order_detail_section_title.dart';
import 'package:toukh_provider/features/orders/presentation/widgets/order_detail/order_detail_surface_card.dart';
import 'package:toukh_provider/l10n/app_strings.dart';
import 'package:toukh_ui/toukh_ui.dart';

/// Shows pickup OTP + QR for the driver to confirm store handoff.
class PickupQrTile extends StatefulWidget {
  const PickupQrTile({
    super.key,
    required this.masterOrderId,
    required this.providerId,
    this.driverId,
    this.pickupCode,
  });

  final String masterOrderId;
  final String providerId;
  final String? driverId;
  /// Known pickup OTP from the master order; backfilled via CF when empty.
  final String? pickupCode;

  @override
  State<PickupQrTile> createState() => _PickupQrTileState();
}

class _PickupQrTileState extends State<PickupQrTile> {
  String? _token;
  String? _pickupCode;
  bool _loading = true;
  String? _error;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _pickupCode = widget.pickupCode?.trim();
    _load();
    _refreshTimer = Timer.periodic(const Duration(minutes: 4), (_) => _load());
  }

  @override
  void didUpdateWidget(covariant PickupQrTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    final nextCode = widget.pickupCode?.trim();
    if (nextCode != null &&
        nextCode.isNotEmpty &&
        nextCode != _pickupCode) {
      _pickupCode = nextCode;
    }
    if (oldWidget.driverId != widget.driverId ||
        oldWidget.masterOrderId != widget.masterOrderId) {
      _load();
    }
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    final qr = getIt<OrderQrService>();
    try {
      final results = await Future.wait([
        qr.fetchPickupToken(
          masterOrderId: widget.masterOrderId,
          providerId: widget.providerId,
          driverId: widget.driverId,
        ),
        () async {
          final existing = _pickupCode?.trim();
          if (existing != null && existing.isNotEmpty) return existing;
          final fromProp = widget.pickupCode?.trim();
          if (fromProp != null && fromProp.isNotEmpty) return fromProp;
          return qr.ensurePickupCode(widget.masterOrderId);
        }(),
      ]);
      if (!mounted) return;
      final token = results[0];
      final code = results[1];
      setState(() {
        _token = token;
        if (code != null && code.isNotEmpty) _pickupCode = code;
        _loading = false;
        if ((token == null || token.isEmpty) &&
            (_pickupCode == null || _pickupCode!.isEmpty)) {
          _error = AppStrings.Common.error.tr;
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = AppStrings.Common.error.tr;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final code = _pickupCode?.trim();
    final hasOtp = code != null && code.isNotEmpty;

    if (_loading && (_token == null || _token!.isEmpty) && !hasOtp) {
      return const OrderDetailSurfaceCard(
        child: Center(child: AppLoadingMark()),
      );
    }
    if (_error != null &&
        (_token == null || _token!.isEmpty) &&
        !hasOtp) {
      return OrderDetailSurfaceCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            OrderDetailSectionTitle(
              label: AppStrings.Orders.detailPickupHandoffTitle.tr,
              icon: ToukhIcons.qrCode,
            ),
            const SizedBox(height: AppSizes.spaceMd),
            CustomText(_error!),
            const SizedBox(height: AppSizes.spaceSm),
            AppTextButton(
              text: AppStrings.Common.retry,
              onTap: _load,
            ),
          ],
        ),
      );
    }

    final hasQr = _token != null && _token!.isNotEmpty;
    if (!hasOtp && !hasQr) return const SizedBox.shrink();

    return OrderDetailSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          OrderDetailSectionTitle(
            label: AppStrings.Orders.detailPickupHandoffTitle.tr,
            icon: ToukhIcons.qrCode,
          ),
          const SizedBox(height: AppSizes.spaceXs),
          CustomText(
            AppStrings.Orders.detailPickupHandoffHint.tr,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.onSurface.withValues(alpha: 0.6),
                ),
          ),
          if (hasOtp) ...[
            const SizedBox(height: AppSizes.spaceLg),
            CustomText(
              AppStrings.Orders.detailPickupOtpOption.tr,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: AppSizes.spaceSm),
            Text(
              code,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w800,
                letterSpacing: 8,
                color: scheme.onSurface,
              ),
            ),
            const SizedBox(height: AppSizes.spaceXs),
            CustomText(
              AppStrings.Orders.detailPickupOtpHint.tr,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.onSurface.withValues(alpha: 0.6),
                  ),
              textAlign: TextAlign.center,
            ),
          ],
          if (hasQr) ...[
            const SizedBox(height: AppSizes.spaceLg),
            CustomText(
              AppStrings.Orders.detailPickupQrOption.tr,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: AppSizes.spaceXs),
            CustomText(
              AppStrings.Orders.detailPickupQrDriverScanHint.tr,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.onSurface.withValues(alpha: 0.6),
                  ),
            ),
            const SizedBox(height: AppSizes.spaceMd),
            Center(
              child: Container(
                padding: const EdgeInsets.all(AppSizes.spaceMd),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                  border: Border.all(color: AppColors.borderSubtle),
                ),
                child: QrImageView(
                  data: _token!,
                  size: 200,
                  backgroundColor: Colors.white,
                ),
              ),
            ),
          ] else if (_loading) ...[
            const SizedBox(height: AppSizes.spaceMd),
            const Center(child: AppLoadingMark()),
          ],
        ],
      ),
    );
  }
}
