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
  });

  final String masterOrderId;
  final String providerId;

  @override
  State<PickupQrTile> createState() => _PickupQrTileState();
}

class _PickupQrTileState extends State<PickupQrTile> {
  String? _token;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final token = await getIt<OrderQrService>().fetchPickupToken(
        masterOrderId: widget.masterOrderId,
        providerId: widget.providerId,
      );
      if (mounted) setState(() => _token = token);
    } catch (_) {
      // ignore
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const OrderDetailSurfaceCard(
        child: Center(child: AppLoadingMark()),
      );
    }
    if (_token == null) return const SizedBox.shrink();

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
            AppStrings.Orders.detailPickupQrHint.tr,
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
