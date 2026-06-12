import 'package:fl_chart/fl_chart.dart';
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
              _LastEarningSection(transaction: state.lastEarning),
              const SizedBox(height: AppSizes.spaceXl),
              CustomText(
                AppStrings.Wallet.earningsOverview.tr,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: AppSizes.spaceSm),
              _ChartPeriodSelector(
                period: state.chartPeriod,
                onChanged: (p) => context.read<WalletCubit>().setChartPeriod(p),
              ),
              const SizedBox(height: AppSizes.spaceMd),
              _EarningsChart(
                loading: state.chartLoading,
                points: state.chartPoints,
                maxY: state.chartMaxY,
                period: state.chartPeriod,
              ),
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
                  '+EGP ${formatWalletMoney(transaction!.amountEgp)}',
                  style: t.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.success,
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

class _ChartPeriodSelector extends StatelessWidget {
  const _ChartPeriodSelector({
    required this.period,
    required this.onChanged,
  });

  final WalletChartPeriod period;
  final ValueChanged<WalletChartPeriod> onChanged;

  int get _index => switch (period) {
        WalletChartPeriod.week => 0,
        WalletChartPeriod.month => 1,
        WalletChartPeriod.year => 2,
      };

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final labels = [
      AppStrings.Wallet.week.tr,
      AppStrings.Wallet.month.tr,
      AppStrings.Wallet.year.tr,
    ];
    const values = [
      WalletChartPeriod.week,
      WalletChartPeriod.month,
      WalletChartPeriod.year,
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final segmentW = constraints.maxWidth / 3;
        return Container(
          height: 48,
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHighest.withValues(alpha: 0.42),
            borderRadius: BorderRadius.circular(AppSizes.radiusLg),
            border: Border.all(color: AppColors.borderSubtle),
          ),
          child: Stack(
            children: [
              AnimatedPositionedDirectional(
                duration: const Duration(milliseconds: 240),
                curve: Curves.easeOutCubic,
                start: _index * segmentW + 4,
                top: 4,
                width: segmentW - 8,
                height: 40,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: AppColors.appColor,
                    borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                  ),
                ),
              ),
              Row(
                children: List.generate(3, (i) {
                  final selected = _index == i;
                  return Expanded(
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => onChanged(values[i]),
                        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                        child: Center(
                          child: CustomText(
                            labels[i],
                            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: selected
                                      ? AppColors.surface
                                      : (isDark
                                          ? Colors.grey.shade400
                                          : AppColors.onSurface.withValues(
                                              alpha: 0.58,
                                            )),
                                ),
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _EarningsChart extends StatelessWidget {
  const _EarningsChart({
    required this.loading,
    required this.points,
    required this.maxY,
    required this.period,
  });

  final bool loading;
  final List<WalletChartPoint> points;
  final double maxY;
  final WalletChartPeriod period;

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const SizedBox(
        height: 200,
        child: Center(child: AppLoadingMark()),
      );
    }
    final total = points.fold<double>(0, (a, b) => a + b.y);
    if (points.isEmpty || total == 0) {
      return Container(
        height: 200,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Theme.of(context)
              .colorScheme
              .surfaceContainerHighest
              .withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppSizes.radiusLg),
          border: Border.all(color: AppColors.borderSubtle),
        ),
        child: CustomText(
          AppStrings.Wallet.noEarningsInPeriod.tr,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.onSurface.withValues(alpha: 0.55),
              ),
        ),
      );
    }

    final spots = points.map((e) => FlSpot(e.x, e.y)).toList();
    return Container(
      height: 220,
      padding: const EdgeInsets.only(right: 12, top: 16, left: 4, bottom: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: LineChart(
        LineChartData(
          minX: spots.first.x,
          maxX: spots.last.x,
          minY: 0,
          maxY: maxY * 1.15,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (_) => FlLine(
              color: AppColors.borderSubtle.withValues(alpha: 0.5),
              strokeWidth: 1,
            ),
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 36,
                getTitlesWidget: (v, _) => CustomText(
                  v >= 1000 ? '${(v / 1000).toStringAsFixed(1)}k' : v.toInt().toString(),
                  style: TextStyle(
                    fontSize: 10,
                    color: AppColors.onSurface.withValues(alpha: 0.45),
                  ),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: period == WalletChartPeriod.month && points.length > 10
                    ? (points.length / 5).ceilToDouble()
                    : 1,
                getTitlesWidget: (v, _) {
                  final i = v.round();
                  if (i < 0 || i >= points.length) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: CustomText(
                      points[i].label,
                      style: TextStyle(
                        fontSize: 10,
                        color: AppColors.onSurface.withValues(alpha: 0.55),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: AppColors.appColor,
              barWidth: 3,
              dotData: const FlDotData(show: true),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.appColor.withValues(alpha: 0.25),
                    AppColors.appColor.withValues(alpha: 0),
                  ],
                ),
              ),
            ),
          ],
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipItems: (touched) => touched.map((s) {
                return LineTooltipItem(
                  'EGP ${formatWalletMoney(s.y)}',
                  const TextStyle(
                    color: AppColors.surface,
                    fontWeight: FontWeight.w700,
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        duration: Duration.zero,
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
