import 'package:equatable/equatable.dart';

/// How the customer-facing service fee is calculated.
enum CustomerServiceFeeMode {
  percent,
  fixed;

  String get wireValue => switch (this) {
        CustomerServiceFeeMode.percent => 'percent',
        CustomerServiceFeeMode.fixed => 'fixed',
      };

  static CustomerServiceFeeMode fromWire(String? raw) {
    switch (raw?.trim().toLowerCase()) {
      case 'fixed':
      case 'amount':
      case 'const':
        return CustomerServiceFeeMode.fixed;
      case 'percent':
      case 'percentage':
      default:
        return CustomerServiceFeeMode.percent;
    }
  }
}

/// Customer service fee on checkout (`appSettings/global.customerServiceFee`).
///
/// Percent applies to items [subtotalEgp] (ex-delivery). Fixed is a flat EGP
/// amount added to the customer total and later deducted from providers.
class CustomerServiceFeeSettings extends Equatable {
  const CustomerServiceFeeSettings({
    this.enabled = false,
    this.mode = CustomerServiceFeeMode.percent,
    this.percent = 0,
    this.amountEgp = 0,
    this.settingsVersion = 1,
  });

  static const defaults = CustomerServiceFeeSettings();

  final bool enabled;
  final CustomerServiceFeeMode mode;
  final double percent;
  final double amountEgp;
  final int settingsVersion;

  factory CustomerServiceFeeSettings.fromMap(Map<String, dynamic>? data) {
    if (data == null) return defaults;
    return CustomerServiceFeeSettings(
      enabled: data['enabled'] as bool? ?? false,
      mode: CustomerServiceFeeMode.fromWire(data['mode'] as String?),
      percent: (data['percent'] as num?)?.toDouble() ?? 0,
      amountEgp: (data['amountEgp'] as num?)?.toDouble() ?? 0,
      settingsVersion: (data['settingsVersion'] as num?)?.toInt() ?? 1,
    );
  }

  Map<String, dynamic> toMap() => {
        'enabled': enabled,
        'mode': mode.wireValue,
        'percent': percent.clamp(0, 100),
        'amountEgp': amountEgp < 0 ? 0 : amountEgp,
        'settingsVersion': settingsVersion,
      };

  /// Fee charged to the customer for this cart subtotal (items only).
  double compute({required double subtotalEgp}) {
    if (!enabled) return 0;
    final sub = subtotalEgp.isFinite && subtotalEgp > 0 ? subtotalEgp : 0.0;
    if (mode == CustomerServiceFeeMode.fixed) {
      final a = amountEgp.isFinite && amountEgp > 0 ? amountEgp : 0.0;
      return _round2(a);
    }
    final p = percent.clamp(0, 100);
    if (p <= 0 || sub <= 0) return 0;
    return _round2(sub * p / 100);
  }

  Map<String, dynamic> snapshot() => {
        'enabled': enabled,
        'mode': mode.wireValue,
        'percent': percent.clamp(0, 100),
        'amountEgp': amountEgp < 0 ? 0 : amountEgp,
      };

  CustomerServiceFeeSettings copyWith({
    bool? enabled,
    CustomerServiceFeeMode? mode,
    double? percent,
    double? amountEgp,
    int? settingsVersion,
  }) {
    return CustomerServiceFeeSettings(
      enabled: enabled ?? this.enabled,
      mode: mode ?? this.mode,
      percent: percent ?? this.percent,
      amountEgp: amountEgp ?? this.amountEgp,
      settingsVersion: settingsVersion ?? this.settingsVersion,
    );
  }

  static double _round2(double v) => (v * 100).round() / 100;

  @override
  List<Object?> get props =>
      [enabled, mode, percent, amountEgp, settingsVersion];
}
