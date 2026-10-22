import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:url_launcher/url_launcher.dart';
import 'package:toukh_provider/domain/entities/company_courier.dart';
import 'package:toukh_provider/features/delivery_company/cubit/courier_profile_cubit.dart';
import 'package:toukh_provider/features/delivery_company/presentation/widgets/company_stats_widgets.dart';
import 'package:toukh_provider/features/delivery_company/presentation/widgets/company_widgets.dart';
import 'package:toukh_provider/l10n/app_strings.dart';
import 'package:toukh_ui/toukh_ui.dart';

class CourierProfileScreen extends StatelessWidget {
  const CourierProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(ToukhIcons.back),
          onPressed: () => context.pop(),
        ),
        title: CustomText(AppStrings.Company.courierProfile),
      ),
      body: BlocBuilder<CourierProfileCubit, CourierProfileState>(
        builder: (context, state) {
          if (state.loading) return const Center(child: AppLoadingMark());
          final courier = state.courier;
          if (courier == null) {
            return Padding(
              padding: AppSizes.screenPadding,
              child: CompanyEmptyNote(
                AppStrings.Company.courierNotFound,
                icon: ToukhIcons.person,
              ),
            );
          }
          final stats = state.stats;
          return ToukhRefresh(
            onRefresh: () => context.read<CourierProfileCubit>().loadStats(),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: AppSizes.screenPadding.copyWith(
                bottom: AppSizes.space3xl,
              ),
              children: [
                _Header(courier: courier),
                const SizedBox(height: AppSizes.spaceMd),
                _AccountControl(courier: courier, busy: state.busy),
                const SizedBox(height: AppSizes.spaceXl),
                if (stats == null)
                  state.statsFailed
                      ? CompanyEmptyNote(
                          AppStrings.Company.statsUnavailable,
                          icon: ToukhIcons.warning,
                        )
                      : const Padding(
                          padding: EdgeInsets.all(AppSizes.spaceXl),
                          child: Center(child: AppLoadingMark()),
                        )
                else ...[
                  CompanySectionTitle(AppStrings.Company.activeOrders),
                  const SizedBox(height: AppSizes.spaceSm),
                  if (stats.activeJobs.isEmpty)
                    CompanyEmptyNote(
                      AppStrings.Company.noActiveOrders,
                      icon: ToukhIcons.delivery,
                    )
                  else
                    for (final job in stats.activeJobs)
                      Padding(
                        padding: const EdgeInsets.only(
                          bottom: AppSizes.spaceSm,
                        ),
                        child: CourierActiveJobTile(job: job),
                      ),
                  const SizedBox(height: AppSizes.spaceXl),
                  CompanyPeriodStats(
                    today: stats.today,
                    week: stats.week,
                    month: stats.month,
                  ),
                  const SizedBox(height: AppSizes.spaceXl),
                  CompanySectionTitle(AppStrings.Company.dailyOrders),
                  const SizedBox(height: AppSizes.spaceSm),
                  CompanyOrdersBarChart(
                    points: stats.daily,
                    label: (d, locale) => DateFormat.E(locale).format(d),
                  ),
                  const SizedBox(height: AppSizes.spaceXl),
                  CompanySectionTitle(AppStrings.Company.weeklyOrders),
                  const SizedBox(height: AppSizes.spaceSm),
                  CompanyOrdersBarChart(
                    points: stats.weekly,
                    label: (d, locale) => DateFormat.Md(locale).format(d),
                  ),
                  const SizedBox(height: AppSizes.spaceXl),
                  CompanySectionTitle(AppStrings.Company.tripTypes),
                  const SizedBox(height: AppSizes.spaceSm),
                  _TripBreakdown(breakdown: stats.breakdown),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.courier});

  final CompanyCourier courier;

  Future<void> _call(BuildContext context) async {
    final digits = courier.phone.replaceAll(RegExp(r'[^\d+]'), '');
    if (digits.isEmpty) return;
    final uri = Uri(scheme: 'tel', path: digits);
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(AppSizes.spaceMd),
      decoration: ToukhCard.decoration(context),
      child: Row(
        children: [
          CourierAvatar(courier: courier, radius: 32),
          const SizedBox(width: AppSizes.spaceMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomText(
                  courier.displayName,
                  style: const TextStyle(
                    fontSize: AppSizes.fontTitle,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                CustomText(
                  [
                    courier.phone,
                    companyVehicleLabel(courier.vehicleType),
                  ].where((s) => s.isNotEmpty).join(' · '),
                  style: TextStyle(
                    fontSize: 13,
                    color: scheme.onSurface.withValues(alpha: 0.65),
                  ),
                ),
                const SizedBox(height: AppSizes.spaceXs),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: courierStatusChips(context, courier),
                ),
              ],
            ),
          ),
          if (courier.phone.isNotEmpty)
            IconButton.filledTonal(
              tooltip: AppStrings.Company.call.tr,
              icon: Icon(ToukhIcons.phone),
              onPressed: () => _call(context),
            ),
        ],
      ),
    );
  }
}

class _AccountControl extends StatelessWidget {
  const _AccountControl({required this.courier, required this.busy});

  final CompanyCourier courier;
  final bool busy;

  Future<bool> _confirm(
    BuildContext context, {
    required String title,
    required String body,
    required String action,
    bool destructive = false,
  }) async {
    final scheme = Theme.of(context).colorScheme;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: CustomText(title),
        content: CustomText(body),
        actions: [
          AppTextButton(
            text: AppStrings.Common.cancel,
            onTap: () => Navigator.pop(ctx, false),
          ),
          AppFilledButton(
            text: action,
            color: destructive ? scheme.error : null,
            foregroundColor: destructive ? scheme.onError : null,
            onTap: () => Navigator.pop(ctx, true),
          ),
        ],
      ),
    );
    return ok == true;
  }

  Future<void> _toggle(BuildContext context, bool enable) async {
    final confirmed = await _confirm(
      context,
      title: enable
          ? AppStrings.Company.enableTitle
          : AppStrings.Company.disableTitle,
      body: enable
          ? AppStrings.Company.enableBody
          : AppStrings.Company.disableBody,
      action: enable ? AppStrings.Company.enable : AppStrings.Company.disable,
      destructive: !enable,
    );
    if (!confirmed || !context.mounted) return;
    final ok = await context.read<CourierProfileCubit>().setEnabled(enable);
    if (!context.mounted) return;
    AppSnack.show(
      context,
      message:
          (ok
                  ? (enable
                        ? AppStrings.Company.courierEnabled
                        : AppStrings.Company.courierDisabled)
                  : AppStrings.Company.actionFailed)
              .tr,
      state: ok ? AppSnackState.success : AppSnackState.error,
      icon: ok ? ToukhIcons.check : ToukhIcons.error,
    );
  }

  Future<void> _remove(BuildContext context) async {
    final confirmed = await _confirm(
      context,
      title: AppStrings.Company.removeTitle,
      body: AppStrings.Company.removeBody,
      action: AppStrings.Company.remove,
      destructive: true,
    );
    if (!confirmed || !context.mounted) return;
    final ok = await context.read<CourierProfileCubit>().remove();
    if (!context.mounted) return;
    AppSnack.show(
      context,
      message:
          (ok
                  ? AppStrings.Company.courierRemoved
                  : AppStrings.Company.actionFailed)
              .tr,
      state: ok ? AppSnackState.success : AppSnackState.error,
      icon: ok ? ToukhIcons.check : ToukhIcons.error,
    );
    if (ok) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final enabled = courier.enabled;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.spaceMd,
        vertical: AppSizes.spaceSm,
      ),
      decoration: ToukhCard.decoration(context),
      child: Column(
        children: [
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: enabled,
            onChanged: busy ? null : (v) => _toggle(context, v),
            title: CustomText(
              enabled
                  ? AppStrings.Company.accountEnabled
                  : AppStrings.Company.accountDisabled,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: enabled ? null : scheme.error,
              ),
            ),
            subtitle: CustomText(
              enabled
                  ? AppStrings.Company.accountEnabledHint
                  : AppStrings.Company.accountDisabledHint,
              style: TextStyle(
                fontSize: 12,
                color: scheme.onSurface.withValues(alpha: 0.65),
              ),
            ),
          ),
          const Divider(height: 1),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: AppTextButton(
              text: AppStrings.Company.remove,
              color: scheme.error,
              onTap: busy ? null : () => _remove(context),
            ),
          ),
        ],
      ),
    );
  }
}

class _TripBreakdown extends StatelessWidget {
  const _TripBreakdown({required this.breakdown});

  final List<MapEntry<String, int>> breakdown;

  @override
  Widget build(BuildContext context) {
    if (breakdown.isEmpty) return CompanyEmptyNote(AppStrings.Company.noTrips);
    final total = breakdown.fold<int>(0, (n, e) => n + e.value);
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(AppSizes.spaceMd),
      decoration: ToukhCard.decoration(context),
      child: Column(
        children: [
          for (final e in breakdown)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  Icon(
                    companyTripTypeIcon(e.key),
                    size: 20,
                    color: AppColors.secondColor,
                  ),
                  const SizedBox(width: AppSizes.spaceSm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: CustomText(
                                companyTripTypeLabel(e.key),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            CustomText(
                              '${e.value} · ${(e.value * 100 / total).round()}%',
                              style: TextStyle(
                                fontSize: 12,
                                color: scheme.onSurfaceVariant,
                                fontFeatures: const [
                                  FontFeature.tabularFigures(),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: e.value / total,
                            minHeight: 6,
                            color: AppColors.secondColor,
                            backgroundColor: scheme.surfaceContainerHighest,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
