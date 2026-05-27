import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:toukh_provider/di/service_locator.dart';
import 'package:toukh_provider/domain/services/order_qr_service.dart';
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
    if (_loading) return const Center(child: AppLoadingMark());
    if (_token == null) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const CustomText(
          'Pickup QR — show to courier',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: AppSizes.spaceMd),
        Center(
          child: QrImageView(
            data: _token!,
            size: 200,
            backgroundColor: Colors.white,
          ),
        ),
      ],
    );
  }
}
