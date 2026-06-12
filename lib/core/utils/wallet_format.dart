import 'package:toukh_provider/domain/entities/provider_wallet_transaction.dart';

String formatWalletMoney(double value) {
  if (value % 1 == 0) return value.toStringAsFixed(0);
  return value.toStringAsFixed(2);
}

String walletEarningLabel(ProviderWalletTransaction transaction) {
  if (transaction.detail != null && transaction.detail!.trim().isNotEmpty) {
    return transaction.detail!.trim();
  }
  switch (transaction.kind) {
    case ProviderWalletTxKind.orderEarning:
      return 'Order earning';
    case ProviderWalletTxKind.payout:
      return 'Payout';
    case ProviderWalletTxKind.adjustment:
      return 'Adjustment';
  }
}
