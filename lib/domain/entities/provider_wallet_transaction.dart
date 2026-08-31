import 'package:equatable/equatable.dart';
import 'package:toukh_ui/toukh_ui.dart';

enum ProviderWalletTxDirection { debit, credit }

enum ProviderWalletTxKind { orderEarning, payout, adjustment, appFee }

enum ProviderWalletTxSource { order, manual, homeService }

class ProviderWalletTransaction extends Equatable {
  const ProviderWalletTransaction({
    required this.id,
    required this.amountEgp,
    required this.direction,
    required this.kind,
    required this.source,
    required this.title,
    this.detail,
    this.orderId,
    this.orderDetails,
    this.balanceBefore,
    this.balanceAfter,
    this.lastTransactionId,
    required this.createdAt,
  });

  final String id;
  final double amountEgp;
  final ProviderWalletTxDirection direction;
  final ProviderWalletTxKind kind;
  final ProviderWalletTxSource source;
  final String title;
  final String? detail;
  final String? orderId;
  final Map<String, dynamic>? orderDetails;
  final double? balanceBefore;
  final double? balanceAfter;
  final String? lastTransactionId;
  final DateTime? createdAt;

  bool get isEarning =>
      direction == ProviderWalletTxDirection.credit &&
      kind == ProviderWalletTxKind.orderEarning;

  bool get isAppFee => kind == ProviderWalletTxKind.appFee;

  static Map<String, dynamic>? _nestedMap(dynamic v) {
    if (v == null) return null;
    if (v is Map<String, dynamic>) return Map<String, dynamic>.from(v);
    if (v is Map) {
      return Map<String, dynamic>.from(
        v.map((k, val) => MapEntry(k.toString(), val)),
      );
    }
    return null;
  }

  static double? _num(dynamic v) => v is num ? v.toDouble() : null;

  static ProviderWalletTxDirection _directionFrom(String? s) =>
      s == 'debit' ? ProviderWalletTxDirection.debit : ProviderWalletTxDirection.credit;

  static ProviderWalletTxKind _kindFrom(String? s) {
    switch (s) {
      case 'payout':
        return ProviderWalletTxKind.payout;
      case 'adjustment':
        return ProviderWalletTxKind.adjustment;
      case 'app_fee':
        return ProviderWalletTxKind.appFee;
      case 'order_earning':
      default:
        return ProviderWalletTxKind.orderEarning;
    }
  }

  static ProviderWalletTxSource _sourceFrom(String? s) {
    switch (s) {
      case 'manual':
        return ProviderWalletTxSource.manual;
      case 'home_service':
        return ProviderWalletTxSource.homeService;
      case 'order':
      default:
        return ProviderWalletTxSource.order;
    }
  }

  factory ProviderWalletTransaction.fromFirestore(
    String id,
    Map<String, dynamic> data,
  ) {
    final created = ToukhFirestoreTimestamps.toDateTime(data['createdAt']);

    final amt = data['amountEgp'];
    final amount = amt is num ? amt.toDouble() : 0.0;
    final lastId = data['lastTransactionId'];

    return ProviderWalletTransaction(
      id: id,
      amountEgp: amount,
      direction: _directionFrom(data['direction'] as String?),
      kind: _kindFrom(data['kind'] as String?),
      source: _sourceFrom(data['source'] as String?),
      title: data['title'] as String? ?? '',
      detail: data['detail'] as String?,
      orderId: data['orderId'] as String?,
      orderDetails: _nestedMap(data['orderDetails']),
      balanceBefore: _num(data['balanceBefore']),
      balanceAfter: _num(data['balanceAfter']),
      lastTransactionId: lastId is String && lastId.trim().isNotEmpty
          ? lastId.trim()
          : null,
      createdAt: created,
    );
  }

  @override
  List<Object?> get props => [
        id,
        amountEgp,
        direction,
        kind,
        source,
        title,
        detail,
        orderId,
        orderDetails,
        balanceBefore,
        balanceAfter,
        lastTransactionId,
        createdAt,
      ];
}

class ProviderWalletSummary extends Equatable {
  const ProviderWalletSummary({
    required this.balanceEgp,
    this.pendingEgp,
  });

  final double balanceEgp;
  final double? pendingEgp;

  @override
  List<Object?> get props => [balanceEgp, pendingEgp];
}
