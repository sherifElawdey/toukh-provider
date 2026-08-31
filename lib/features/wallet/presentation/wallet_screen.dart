import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:toukh_provider/core/router/app_routes.dart';
import 'package:toukh_provider/core/utils/wallet_format.dart';
import 'package:toukh_provider/core/widgets/toukh_service_logo.dart';
import 'package:toukh_provider/domain/entities/provider_wallet_transaction.dart';
import 'package:toukh_provider/features/wallet/cubit/wallet_cubit.dart';
import 'package:toukh_provider/features/wallet/presentation/wallet_earning_sheet.dart';
import 'package:toukh_provider/l10n/app_strings.dart';
import 'package:toukh_ui/toukh_ui.dart';

class WalletScreen extends StatelessWidget {
  const WalletScreen({super.key});

  void _showPayoutComingSoon(BuildContext context) {
    AppSnack.show(
      context,
      message: AppStrings.Wallet.requestPayoutComingSoon.tr,
      state: AppSnackState.alert,
      icon: ToukhIcons.wallet,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: CustomText(AppStrings.Wallet.myWallet.tr),
        leading: IconButton(
          icon: Icon(ToukhIcons.back),
          onPressed: () => context.pop(),
        ),
      ),
      body: BlocBuilder<WalletCubit, WalletState>(
        builder: (context, state) {
          return ListView(
            padding: AppSizes.screenPadding,
            children: [
              _BalanceCard(
                balance: state.balance,
                pendingEgp: state.pendingEgp,
              ),
              const SizedBox(height: AppSizes.spaceXl),
              _LastEarningSection(transaction: state.lastFeeOrEarning),
              const SizedBox(height: AppSizes.spaceXl),
              Row(
                children: [
                  Expanded(
                    child: CustomText(
                      AppStrings.Wallet.recentEarnings.tr,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                  ),
                  AppTextButton(
                    text: AppStrings.Wallet.seeAll.tr,
                    onTap: () => context.push(AppRoutes.walletTransactions),
                  ),
                ],
              ),
              const SizedBox(height: AppSizes.spaceSm),
              if (state.recent.isEmpty)
                CustomText(
                  AppStrings.Wallet.noTransactionsYet.tr,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.onSurface.withValues(alpha: 0.55),
                      ),
                )
              else
                ...state.recent.map(
                  (t) => _EarningTile(
                    transaction: t,
                    onTap: () => showWalletEarningSheet(context, t),
                  ),
                ),
              const SizedBox(height: AppSizes.space4xl),
            ],
          );
        },
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.spaceBase,
            vertical: AppSizes.spaceSm,
          ),
          child: AppFilledButton(
            text: AppStrings.Wallet.requestPayout.tr,
            icon: PhosphorIconsRegular.bank,
            color: AppColors.appColor,
            foregroundColor: AppColors.surface,
            padding: const EdgeInsets.symmetric(
              vertical: AppSizes.spaceMd,
              horizontal: AppSizes.spaceLg,
            ),
            onTap: () => _showPayoutComingSoon(context),
          ),
        ),
      ),
    );
  }
}

class _BalanceCard extends StatelessWidget {
  const _BalanceCard({
    required this.balance,
    this.pendingEgp,
  });

  final double balance;
  final double? pendingEgp;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final textDirection = isArabic ? TextDirection.rtl : TextDirection.ltr;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppSizes.radiusXl),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1A3A5C), AppColors.secondColor],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.secondColor.withValues(alpha: 0.35),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned.directional(
            end: -20,
            top: -20,
            textDirection: textDirection,
            child: Icon(
              ToukhIcons.online,
              size: 140,
              color: AppColors.appColor.withValues(alpha: 0.12),
            ),
          ),
          Positioned.directional(
            top: AppSizes.spaceMd,
            end: AppSizes.spaceMd,
            textDirection: textDirection,
            child: ToukhServiceLogo(
              size: 72,
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          Directionality(
            textDirection: textDirection,
            child: Padding(
              padding: const EdgeInsets.all(AppSizes.spaceXl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomText(
                    AppStrings.Wallet.toukhServiceWallet.tr,
                    style: t.labelLarge?.copyWith(
                      color: AppColors.surface.withValues(alpha: 0.9),
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: AppSizes.spaceXl),
                  CustomText(
                    AppStrings.Wallet.availableBalance.tr,
                    style: t.bodySmall?.copyWith(
                      color: AppColors.surface.withValues(alpha: 0.75),
                    ),
                  ),
                  const SizedBox(height: 4),
                  CustomText(
                    'EGP ${formatWalletMoney(balance)}',
                    style: t.headlineMedium?.copyWith(
                      color: AppColors.surface,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (pendingEgp != null && pendingEgp! > 0) ...[
                    const SizedBox(height: AppSizes.spaceSm),
                    CustomText(
                      '${AppStrings.Wallet.pendingBalance.tr}: EGP ${formatWalletMoney(pendingEgp!)}',
                      style: t.bodySmall?.copyWith(
                        color: AppColors.surface.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                  const SizedBox(height: AppSizes.spaceLg),
                  CustomText(
                    AppStrings.Wallet.cardMask.tr,
                    style: t.titleMedium?.copyWith(
                      color: AppColors.surface.withValues(alpha: 0.5),
                      letterSpacing: 2,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LastEarningSection extends StatelessWidget {
  const _LastEarningSection({this.transaction});

  final ProviderWalletTransaction? transaction;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSizes.spaceLg),
      decoration: BoxDecoration(
        color: AppColors.thirdColor.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomText(
            AppStrings.Wallet.lastEarning.tr,
            style: t.labelLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.onSurface.withValues(alpha: 0.55),
            ),
          ),
          const SizedBox(height: AppSizes.spaceSm),
          if (transaction == null)
            CustomText(
              AppStrings.Wallet.noEarningsYet.tr,
              style: t.bodyMedium?.copyWith(
                color: AppColors.onSurface.withValues(alpha: 0.65),
              ),
            )
          else ...[
            Row(
              children: [
                Expanded(
                  child: CustomText(
                    transaction!.title,
                    style: t.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                  ),
                ),
                CustomText(
                  transaction!.isAppFee
                      ? '-EGP ${formatWalletMoney(transaction!.amountEgp)}'
                      : '+EGP ${formatWalletMoney(transaction!.amountEgp)}',
                  style: t.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: transaction!.isAppFee
                        ? AppColors.error
                        : AppColors.success,
                  ),
                ),
              ],
            ),
            if (transaction!.detail != null &&
                transaction!.detail!.isNotEmpty) ...[
              const SizedBox(height: 4),
              CustomText(
                transaction!.detail!,
                style: t.bodySmall?.copyWith(
                  color: AppColors.onSurface.withValues(alpha: 0.65),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _EarningTile extends StatelessWidget {
  const _EarningTile({
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
          vertical: AppSizes.spaceXs,
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
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CustomText(
              '${isCredit ? '+' : '-'}EGP ${formatWalletMoney(transaction.amountEgp)}',
              style: t.labelLarge?.copyWith(
                fontWeight: FontWeight.w800,
                color: isCredit ? AppColors.success : AppColors.onSurface,
              ),
            ),
            Icon(
              ToukhIcons.chevronRight,
              color: AppColors.secondColor.withValues(alpha: 0.45),
            ),
          ],
        ),
        onTap: onTap,
      ),
    );
  }
}
