import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:toukh_provider/core/utils/wallet_format.dart';
import 'package:toukh_provider/domain/entities/provider_wallet_transaction.dart';
import 'package:toukh_provider/l10n/app_strings.dart';
import 'package:toukh_ui/toukh_ui.dart';

Future<void> showWalletEarningSheet(
  BuildContext context,
  ProviderWalletTransaction transaction,
) async {
  final scheme = Theme.of(context).colorScheme;
  final bottom = MediaQuery.paddingOf(context).bottom + AppSizes.spaceLg;
  final maxH = MediaQuery.sizeOf(context).height * 0.85;
  final dateStr = transaction.createdAt != null
      ? DateFormat.yMMMd().add_jm().format(transaction.createdAt!.toLocal())
      : '—';
  final isCredit = transaction.direction == ProviderWalletTxDirection.credit;

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: scheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppSizes.radiusXl)),
    ),
    builder: (ctx) {
      return ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxH),
        child: SingleChildScrollView(
          padding: EdgeInsets.only(
            left: AppSizes.spaceXl,
            right: AppSizes.spaceXl,
            top: AppSizes.spaceSm,
            bottom: bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              CustomText(
                isCredit
                    ? AppStrings.Wallet.earningCredit.tr
                    : AppStrings.Wallet.earningDebit.tr,
                style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: AppSizes.spaceLg),
              _sheetRow(
                ctx,
                AppStrings.Wallet.amount.tr,
                '${isCredit ? '+' : '-'}EGP ${formatWalletMoney(transaction.amountEgp)}',
                emphasize: true,
              ),
              _sheetRow(ctx, AppStrings.Wallet.date.tr, dateStr),
              _sheetRow(ctx, AppStrings.Wallet.title.tr, transaction.title),
              if (transaction.detail != null && transaction.detail!.isNotEmpty)
                _sheetRow(ctx, AppStrings.Wallet.details.tr, transaction.detail!),
              _sheetRow(
                ctx,
                AppStrings.Wallet.type.tr,
                walletEarningLabel(transaction),
              ),
              if (transaction.orderId != null && transaction.orderId!.isNotEmpty)
                _sheetRow(
                  ctx,
                  AppStrings.Wallet.walletEarningOrderId.tr,
                  transaction.orderId!,
                ),
              if (transaction.orderDetails != null &&
                  transaction.orderDetails!.isNotEmpty) ...[
                const SizedBox(height: AppSizes.spaceSm),
                _OrderDetailSection(details: transaction.orderDetails!),
              ],
              const SizedBox(height: AppSizes.spaceMd),
            ],
          ),
        ),
      );
    },
  );
}

Widget _sheetRow(
  BuildContext context,
  String label,
  String value, {
  bool emphasize = false,
}) {
  final t = Theme.of(context).textTheme;
  return Padding(
    padding: const EdgeInsets.only(bottom: AppSizes.spaceSm),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 110,
          child: CustomText(
            label,
            style: t.bodySmall?.copyWith(
              color: AppColors.onSurface.withValues(alpha: 0.55),
            ),
          ),
        ),
        Expanded(
          child: CustomText(
            value,
            style: (emphasize ? t.titleMedium : t.bodyMedium)?.copyWith(
              fontWeight: emphasize ? FontWeight.w800 : FontWeight.w500,
            ),
          ),
        ),
      ],
    ),
  );
}

class _OrderDetailSection extends StatelessWidget {
  const _OrderDetailSection({required this.details});

  final Map<String, dynamic> details;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final lines = details['lineItems'];
    final lineList = lines is List ? lines : const [];
    final total = details['totalEgp'];
    final totalStr = total is num ? formatWalletMoney(total.toDouble()) : '—';

    return Container(
      padding: const EdgeInsets.all(AppSizes.spaceMd),
      decoration: BoxDecoration(
        color: AppColors.thirdColor.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CustomText(
            AppStrings.Wallet.walletEarningOrder.tr,
            style: t.titleSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: AppSizes.spaceSm),
          for (final raw in lineList)
            if (raw is Map) ...[
              _lineRow(context, Map<String, dynamic>.from(raw)),
              const SizedBox(height: 4),
            ],
          const Divider(height: AppSizes.spaceLg),
          Row(
            children: [
              Expanded(
                child: CustomText(
                  AppStrings.Wallet.total.tr,
                  style: t.labelLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              CustomText(
                'EGP $totalStr',
                style: t.labelLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _lineRow(BuildContext context, Map<String, dynamic> line) {
    final name = line['itemName'] as String? ?? 'Item';
    final qty = line['quantity'];
    final qtyStr = qty is num ? qty.toString() : '1';
    final lineTotal = line['lineTotalEgp'];
    final priceStr =
        lineTotal is num ? formatWalletMoney(lineTotal.toDouble()) : '—';
    return Row(
      children: [
        Expanded(
          child: CustomText(
            '$name × $qtyStr',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
        CustomText(
          'EGP $priceStr',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
      ],
    );
  }
}
