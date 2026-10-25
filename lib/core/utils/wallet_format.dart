import 'package:toukh_provider/domain/entities/provider_wallet_transaction.dart';
import 'package:get/get.dart';
import 'package:toukh_provider/l10n/app_strings.dart';

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
      return transaction.source == ProviderWalletTxSource.homeService
          ? AppStrings.Wallet.kindServiceEarning.tr
          : AppStrings.Wallet.kindOrderEarning.tr;
    case ProviderWalletTxKind.payout:
      return AppStrings.Wallet.kindPayout.tr;
    case ProviderWalletTxKind.adjustment:
      return AppStrings.Wallet.kindAdjustment.tr;
    case ProviderWalletTxKind.appFee:
      return AppStrings.Wallet.kindAppFee.tr;
    case ProviderWalletTxKind.customerServiceFee:
      return AppStrings.Wallet.kindCustomerServiceFee.tr;
  }
}
