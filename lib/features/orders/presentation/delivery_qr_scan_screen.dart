import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:toukh_provider/l10n/app_strings.dart';
import 'package:toukh_ui/toukh_ui.dart';

/// Scans a customer delivery QR and returns the raw payload.
class DeliveryQrScanScreen extends StatefulWidget {
  const DeliveryQrScanScreen({super.key});

  @override
  State<DeliveryQrScanScreen> createState() => _DeliveryQrScanScreenState();
}

class _DeliveryQrScanScreenState extends State<DeliveryQrScanScreen> {
  bool _handled = false;

  void _onDetect(BarcodeCapture capture) {
    if (_handled) return;
    final raw = capture.barcodes.firstOrNull?.rawValue;
    if (raw == null || raw.isEmpty) return;
    _handled = true;
    Navigator.pop(context, raw);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: CustomText(AppStrings.Orders.scanDeliveryQr),
      ),
      body: MobileScanner(onDetect: _onDetect),
    );
  }
}
