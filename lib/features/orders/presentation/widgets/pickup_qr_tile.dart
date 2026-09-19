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

/// Shows a pickup verification QR for the driver to scan.
class PickupQrTile extends StatefulWidget {
  const PickupQrTile({
    super.key,
    required this.masterOrderId,
    required this.providerId,
    this.driverId,
  });

  final String masterOrderId;
  final String providerId;
  final String? driverId;

  @override
  State<PickupQrTile> createState() => _PickupQrTileState();
}

class _PickupQrTileState extends State<PickupQrTile> {
  String? _token;
  bool _loading = true;
  String? _error;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _load();
    _refreshTimer = Timer.periodic(const Duration(minutes: 4), (_) => _load());
  }

  @override
  void didUpdateWidget(covariant PickupQrTile oldWidget) {
    super.didUpdateWidget(oldWidget);
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
    try {
      final token = await getIt<OrderQrService>().fetchPickupToken(
        masterOrderId: widget.masterOrderId,
        providerId: widget.providerId,
        driverId: widget.driverId,
      );
      if (!mounted) return;
      setState(() {
        _token = token;
        _loading = false;
        if (token == null || token.isEmpty) {
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
    if (_loading && (_token == null || _token!.isEmpty)) {
      return const OrderDetailSurfaceCard(
        child: Center(child: AppLoadingMark()),
      );
    }
    if (_error != null && (_token == null || _token!.isEmpty)) {
      return OrderDetailSurfaceCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            OrderDetailSectionTitle(
              label: AppStrings.Orders.detailPickupQrTitle.tr,
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
    if (_token == null || _token!.isEmpty) return const SizedBox.shrink();

    return OrderDetailSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          OrderDetailSectionTitle(
            label: AppStrings.Orders.detailPickupQrTitle.tr,
            icon: ToukhIcons.qrCode,
          ),
          const SizedBox(height: AppSizes.spaceXs),
          CustomText(
            AppStrings.Orders.detailPickupQrDriverScanHint.tr,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.onSurface.withValues(alpha: 0.6),
                ),
          ),
          const SizedBox(height: AppSizes.spaceLg),
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
        ],
      ),
    );
  }
}
