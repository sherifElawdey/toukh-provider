import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:toukh_provider/core/utils/wallet_format.dart';
import 'package:toukh_provider/domain/entities/provider_wallet_transaction.dart';
import 'package:toukh_provider/features/wallet/cubit/wallet_cubit.dart';
import 'package:toukh_provider/features/wallet/presentation/wallet_earning_sheet.dart';
import 'package:toukh_provider/l10n/app_strings.dart';
import 'package:toukh_ui/toukh_ui.dart';

class WalletTransactionsScreen extends StatefulWidget {
  const WalletTransactionsScreen({super.key});

  @override
  State<WalletTransactionsScreen> createState() =>
      _WalletTransactionsScreenState();
}

class _WalletTransactionsScreenState extends State<WalletTransactionsScreen> {
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
  }

  void _onScroll() {
    if (!_scroll.hasClients) return;
    final max = _scroll.position.maxScrollExtent;
    if (max <= 0) return;
    if (_scroll.offset >= max - 200) {
      context.read<WalletHistoryCubit>().loadMore();
    }
  }

  @override
  void dispose() {
    _scroll.removeListener(_onScroll);
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: CustomText(AppStrings.Wallet.allTransactions.tr),
        leading: IconButton(
          icon: Icon(ToukhIcons.back),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: BlocBuilder<WalletHistoryCubit, WalletHistoryState>(
        builder: (context, state) {
          if (state.loading && state.items.isEmpty) {
            return const Center(child: AppLoadingMark());
          }
          if (state.error != null && state.items.isEmpty) {
            return Center(
              child: Padding(
                padding: AppSizes.screenPadding,
                child: CustomText(state.error!),
              ),
            );
          }
          if (state.items.isEmpty) {
            return Center(
              child: CustomText(
                AppStrings.Wallet.noTransactionsYet.tr,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppColors.onSurface.withValues(alpha: 0.55),
                    ),
              ),
            );
          }
          return ListView.builder(
            controller: _scroll,
            padding: AppSizes.screenPadding,
            itemCount: state.items.length + (state.loadingMore ? 1 : 0),
            itemBuilder: (context, i) {
              if (i >= state.items.length) {
                return const Padding(
                  padding: EdgeInsets.all(AppSizes.spaceLg),
                  child: Center(child: AppLoadingMark()),
                );
              }
              final tx = state.items[i];
              return _TxListRow(
                transaction: tx,
                onTap: () => showWalletEarningSheet(context, tx),
              );
            },
          );
        },
      ),
    );
  }
}

class _TxListRow extends StatelessWidget {
  const _TxListRow({
    required this.transaction,
    required this.onTap,
  });

  final ProviderWalletTransaction transaction;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isCredit = transaction.direction == ProviderWalletTxDirection.credit;
    final t = Theme.of(context).textTheme;
    return Card(
      margin: const EdgeInsets.only(bottom: AppSizes.spaceSm),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        side: BorderSide(color: AppColors.borderSubtle),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSizes.spaceLg,
          vertical: AppSizes.spaceSm,
        ),
        leading: CircleAvatar(
          backgroundColor: isCredit
              ? AppColors.success.withValues(alpha: 0.15)
              : AppColors.appColor.withValues(alpha: 0.12),
          child: Icon(
            isCredit ? ToukhIcons.add : ToukhIcons.ordersSelected,
            color: isCredit ? AppColors.success : AppColors.appColor,
          ),
        ),
        title: CustomText(
          transaction.title,
          style: t.titleSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
        subtitle: CustomText(
          walletEarningLabel(transaction),
          style: t.bodySmall?.copyWith(
            color: AppColors.onSurface.withValues(alpha: 0.55),
          ),
        ),
        trailing: CustomText(
          '${isCredit ? '+' : '-'}EGP ${formatWalletMoney(transaction.amountEgp)}',
          style: t.labelLarge?.copyWith(
            fontWeight: FontWeight.w800,
            color: isCredit ? AppColors.success : AppColors.onSurface,
          ),
        ),
        onTap: onTap,
      ),
    );
  }
}
