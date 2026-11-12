import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:toukh_provider/domain/entities/driver_day_stats.dart';
import 'package:toukh_provider/domain/entities/provider_driver_link_request.dart';
import 'package:toukh_provider/domain/entities/provider_linked_driver.dart';
import 'package:toukh_provider/features/drivers/cubit/manage_drivers_cubit.dart';
import 'package:toukh_provider/l10n/app_strings.dart';
import 'package:toukh_ui/toukh_ui.dart';

class ManageDriversScreen extends StatefulWidget {
  const ManageDriversScreen({super.key});

  @override
  State<ManageDriversScreen> createState() => _ManageDriversScreenState();
}

enum _DriversTab { drivers, requests }

class _ManageDriversScreenState extends State<ManageDriversScreen> {
  _DriversTab _tab = _DriversTab.drivers;

  /// Opens on Requests the first time data arrives with requests waiting.
  bool _tabPicked = false;

  Future<void> _refresh(BuildContext context) async {
    context.read<ManageDriversCubit>().retry();
    await Future<void>.delayed(const Duration(milliseconds: 450));
  }

  void _copyCode(BuildContext context, String providerId) {
    Clipboard.setData(ClipboardData(text: providerId));
    AppSnack.show(
      context,
      message: AppStrings.Drivers.codeCopied.tr,
      state: AppSnackState.success,
      icon: ToukhIcons.check,
    );
  }

  String _vehicleLabel(String wire) {
    switch (wire) {
      case 'motorcycle':
        return AppStrings.Drivers.vehicleMotorcycle.tr;
      case 'bicycle':
        return AppStrings.Drivers.vehicleBicycle.tr;
      case 'tuk_tuk':
        return AppStrings.Drivers.vehicleTukTuk.tr;
      default:
        return wire;
    }
  }

  Future<void> _confirmRemoveDriver(
    BuildContext context, {
    required String driverId,
  }) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: CustomText(AppStrings.Drivers.removeConfirmTitle),
        content: CustomText(
          AppStrings.Drivers.removeConfirmBody.tr,
          style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(
                color: Theme.of(ctx)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.8),
              ),
        ),
        actions: [
          AppTextButton(
            text: AppStrings.Common.cancel,
            onTap: () => Navigator.pop(ctx, false),
          ),
          AppFilledButton(
            text: AppStrings.Drivers.remove,
            color: Theme.of(ctx).colorScheme.error,
            foregroundColor: Theme.of(ctx).colorScheme.onError,
            onTap: () => Navigator.pop(ctx, true),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    final removed = await context
        .read<ManageDriversCubit>()
        .removeLinkedDriver(driverId: driverId);
    if (removed && context.mounted) {
      AppSnack.show(
        context,
        message: AppStrings.Drivers.driverRemoved.tr,
        state: AppSnackState.success,
        icon: ToukhIcons.check,
      );
    }
  }

  Future<void> _accept(BuildContext context, String driverId) async {
    final ok = await context.read<ManageDriversCubit>().acceptRequest(driverId);
    if (ok && context.mounted) {
      AppSnack.show(
        context,
        message: AppStrings.Drivers.requestAccepted.tr,
        state: AppSnackState.success,
        icon: ToukhIcons.check,
      );
    }
  }

  Future<void> _reject(BuildContext context, String driverId) async {
    final ok = await context.read<ManageDriversCubit>().rejectRequest(driverId);
    if (ok && context.mounted) {
      AppSnack.show(
        context,
        message: AppStrings.Drivers.requestRejected.tr,
        state: AppSnackState.alert,
        icon: ToukhIcons.info,
      );
    }
  }

  List<Widget> _driversTab(BuildContext context, ManageDriversState state) {
    if (state.linkedDrivers.isEmpty) {
      return [_EmptySection(message: AppStrings.Drivers.noLinkedDrivers.tr)];
    }
    // Busiest couriers today first, then by name.
    final drivers = [...state.linkedDrivers]..sort((a, b) {
        final byOrders =
            state.statsFor(b.uid).total.compareTo(state.statsFor(a.uid).total);
        return byOrders != 0
            ? byOrders
            : a.displayName.compareTo(b.displayName);
      });
    return [
      for (final d in drivers)
        Padding(
          padding: const EdgeInsets.only(bottom: AppSizes.spaceSm),
          child: _LinkedDriverCard(
            driver: d,
            stats: state.statsFor(d.uid),
            vehicleLabel: _vehicleLabel(d.vehicleType),
            busy: state.actionInProgress == d.uid,
            onRemove: () => _confirmRemoveDriver(context, driverId: d.uid),
          ),
        ),
    ];
  }

  List<Widget> _requestsTab(
    BuildContext context,
    ManageDriversState state,
    DateFormat dateFmt,
  ) {
    if (state.pendingRequests.isEmpty) {
      return [_EmptySection(message: AppStrings.Drivers.noPendingRequests.tr)];
    }
    return [
      for (final r in state.pendingRequests)
        Padding(
          padding: const EdgeInsets.only(bottom: AppSizes.spaceSm),
          child: _PendingRequestCard(
            request: r,
            vehicleLabel: _vehicleLabel(r.vehicleType),
            dateFmt: dateFmt,
            busy: state.actionInProgress == r.uid,
            anyBusy: state.actionInProgress != null,
            onAccept: () => _accept(context, r.uid),
            onReject: () => _reject(context, r.uid),
          ),
        ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: CustomText(AppStrings.Settings.manageDrivers.tr),
        leading: IconButton(
          icon: Icon(ToukhIcons.back),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: BlocConsumer<ManageDriversCubit, ManageDriversState>(
        listenWhen: (prev, next) =>
            (prev.error != next.error && next.error != null) ||
            (prev.loading && !next.loading),
        listener: (context, state) {
          if (!_tabPicked && !state.loading) {
            _tabPicked = true;
            if (state.pendingRequests.isNotEmpty) {
              setState(() => _tab = _DriversTab.requests);
            }
          }
          if (state.error == null) return;
          AppSnack.show(
            context,
            message: (state.error == ManageDriversCubit.removeBusyError
                    ? AppStrings.Drivers.removeBusy
                    : AppStrings.Drivers.actionFailed)
                .tr,
            state: AppSnackState.error,
            icon: ToukhIcons.error,
          );
        },
        builder: (context, state) {
          if (state.loading &&
              state.pendingRequests.isEmpty &&
              state.linkedDrivers.isEmpty) {
            return const Center(child: AppLoadingMark());
          }

          final locale = Localizations.localeOf(context).toLanguageTag();
          final dateFmt = DateFormat.yMMMd(locale);

          final content = ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: AppSizes.screenPadding.copyWith(top: AppSizes.spaceLg),
            children: [
              _InviteCodeCard(
                code: state.providerId,
                onCopy: () => _copyCode(context, state.providerId),
              ),
              const SizedBox(height: AppSizes.spaceLg),
              _TodaySummary(state: state),
              const SizedBox(height: AppSizes.spaceXl),
              _TabSwitch(
                selected: _tab,
                driversCount: state.linkedDrivers.length,
                requestsCount: state.pendingRequests.length,
                onChanged: (t) => setState(() => _tab = t),
              ),
              const SizedBox(height: AppSizes.spaceMd),
              ...switch (_tab) {
                _DriversTab.drivers => _driversTab(context, state),
                _DriversTab.requests => _requestsTab(context, state, dateFmt),
              },
              const SizedBox(height: AppSizes.space2xl),
            ],
          );
          return ToukhRefresh(
            onRefresh: () => _refresh(context),
            child: content,
          );
        },
      ),
    );
  }
}

class _InviteCodeCard extends StatelessWidget {
  const _InviteCodeCard({required this.code, required this.onCopy});

  final String code;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(AppSizes.spaceLg),
      decoration: BoxDecoration(
        color: AppColors.thirdColor.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(PhosphorIconsRegular.ticket, color: scheme.primary),
              const SizedBox(width: AppSizes.spaceSm),
              Expanded(
                child: CustomText(
                  AppStrings.Drivers.inviteCode.tr,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.spaceMd),
          Container(
            padding: const EdgeInsetsDirectional.only(
              start: AppSizes.spaceMd,
              end: AppSizes.spaceXs,
            ),
            decoration: BoxDecoration(
              color: scheme.surface,
              borderRadius: BorderRadius.circular(AppSizes.radiusMd),
              border: Border.all(color: AppColors.borderSubtle),
            ),
            child: Row(
              children: [
                Expanded(
                  child: SelectableText(
                    code,
                    textDirection: TextDirection.ltr,
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: scheme.onSurface,
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed: onCopy,
                  icon: Icon(PhosphorIconsRegular.copy, size: 18),
                  label: CustomText(
                    AppStrings.Drivers.copyCode.tr,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSizes.spaceSm),
          CustomText(
            AppStrings.Drivers.inviteHint.tr,
            style: TextStyle(
              fontSize: 12,
              color: scheme.onSurface.withValues(alpha: 0.6),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _TodaySummary extends StatelessWidget {
  const _TodaySummary({required this.state});

  final ManageDriversState state;

  @override
  Widget build(BuildContext context) {
    final team = state.teamToday;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SectionTitle(label: AppStrings.Drivers.todayActivity.tr),
        const SizedBox(height: AppSizes.spaceSm),
        Row(
          children: [
            Expanded(
              child: _StatTile(
                icon: ToukhIcons.delivery,
                label: AppStrings.Drivers.statDrivers.tr,
                value: state.linkedDrivers.length,
              ),
            ),
            const SizedBox(width: AppSizes.spaceSm),
            Expanded(
              child: _StatTile(
                icon: PhosphorIconsRegular.wifiHigh,
                label: AppStrings.Drivers.statOnline.tr,
                value: state.onlineCount,
                color: AppColors.success,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSizes.spaceSm),
        Row(
          children: [
            Expanded(
              child: _StatTile(
                icon: PhosphorIconsRegular.package,
                label: AppStrings.Drivers.statOrdersToday.tr,
                value: team.total,
              ),
            ),
            const SizedBox(width: AppSizes.spaceSm),
            Expanded(
              child: _StatTile(
                icon: PhosphorIconsRegular.checkCircle,
                label: AppStrings.Drivers.statDelivered.tr,
                value: team.delivered,
                color: AppColors.success,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.icon,
    required this.label,
    required this.value,
    this.color,
  });

  final IconData icon;
  final String label;
  final int value;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tint = color ?? scheme.primary;
    return Container(
      padding: const EdgeInsets.all(AppSizes.spaceMd),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: tint.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 18, color: tint),
          ),
          const SizedBox(width: AppSizes.spaceSm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$value',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                CustomText(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    color: scheme.onSurface.withValues(alpha: 0.6),
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

class _TabSwitch extends StatelessWidget {
  const _TabSwitch({
    required this.selected,
    required this.driversCount,
    required this.requestsCount,
    required this.onChanged,
  });

  final _DriversTab selected;
  final int driversCount;
  final int requestsCount;
  final ValueChanged<_DriversTab> onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    Widget tab(_DriversTab t, String label, {bool alert = false}) {
      final on = t == selected;
      return Expanded(
        child: GestureDetector(
          onTap: () => onChanged(t),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(vertical: AppSizes.spaceSm),
            decoration: BoxDecoration(
              color: on ? scheme.primary : Colors.transparent,
              borderRadius: BorderRadius.circular(AppSizes.radiusMd),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: CustomText(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: on
                          ? scheme.onPrimary
                          : scheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                ),
                if (alert) ...[
                  const SizedBox(width: 6),
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: on ? scheme.onPrimary : AppColors.error,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Row(
        children: [
          tab(
            _DriversTab.drivers,
            AppStrings.Drivers.tabDrivers.trParams({'count': '$driversCount'}),
          ),
          tab(
            _DriversTab.requests,
            AppStrings.Drivers.tabRequests
                .trParams({'count': '$requestsCount'}),
            alert: requestsCount > 0,
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return CustomText(
      label,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
          ),
    );
  }
}

class _EmptySection extends StatelessWidget {
  const _EmptySection({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSizes.spaceLg),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: CustomText(
        message,
        style: TextStyle(
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.55),
        ),
      ),
    );
  }
}

class _PendingRequestCard extends StatelessWidget {
  const _PendingRequestCard({
    required this.request,
    required this.vehicleLabel,
    required this.dateFmt,
    required this.busy,
    required this.anyBusy,
    required this.onAccept,
    required this.onReject,
  });

  final ProviderDriverLinkRequest request;
  final String vehicleLabel;
  final DateFormat dateFmt;
  final bool busy;
  final bool anyBusy;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final initial = request.displayName.trim().isNotEmpty
        ? request.displayName.trim()[0].toUpperCase()
        : '?';

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        side: BorderSide(color: AppColors.borderSubtle),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.spaceLg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipOval(
                  child: SizedBox(
                    width: 40,
                    height: 40,
                    child: request.profilePhotoUrl != null
                        ? HavitNetworkImage(
                            imageUrl: request.profilePhotoUrl!,
                            fit: BoxFit.cover,
                          )
                        : ColoredBox(
                            color: scheme.primary.withValues(alpha: 0.15),
                            child: Center(
                              child: CustomText(
                                initial,
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  color: scheme.primary,
                                ),
                              ),
                            ),
                          ),
                  ),
                ),
                const SizedBox(width: AppSizes.spaceMd),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CustomText(
                        request.displayName,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 4),
                      CustomText(
                        request.phone,
                        style: TextStyle(
                          fontSize: 13,
                          color: scheme.onSurface.withValues(alpha: 0.65),
                        ),
                      ),
                      const SizedBox(height: 4),
                      CustomText(
                        vehicleLabel,
                        style: TextStyle(
                          fontSize: 12,
                          color: scheme.onSurface.withValues(alpha: 0.55),
                        ),
                      ),
                      if (request.submittedAt != null) ...[
                        const SizedBox(height: 4),
                        CustomText(
                          AppStrings.Drivers.requestedOn.trParams(
                            {'date': dateFmt.format(request.submittedAt!)},
                          ),
                          style: TextStyle(
                            fontSize: 12,
                            color: scheme.onSurface.withValues(alpha: 0.48),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSizes.spaceMd),
            Row(
              children: [
                Expanded(
                  child: AppOutlinedButton(
                    text: AppStrings.Drivers.reject.tr,
                    onTap: anyBusy && !busy ? null : onReject,
                  ),
                ),
                const SizedBox(width: AppSizes.spaceSm),
                Expanded(
                  child: busy
                      ? const Center(child: AppLoadingMark())
                      : AppFilledButton(
                          text: AppStrings.Drivers.accept.tr,
                          onTap: anyBusy ? null : onAccept,
                        ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _LinkedDriverCard extends StatelessWidget {
  const _LinkedDriverCard({
    required this.driver,
    required this.stats,
    required this.vehicleLabel,
    required this.onRemove,
    this.busy = false,
  });

  final ProviderLinkedDriver driver;
  final DriverDayStats stats;
  final String vehicleLabel;
  final VoidCallback onRemove;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final initial = driver.displayName.trim().isNotEmpty
        ? driver.displayName.trim()[0].toUpperCase()
        : '?';

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        side: BorderSide(color: AppColors.borderSubtle),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.spaceLg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    ClipOval(
                      child: SizedBox(
                        width: 44,
                        height: 44,
                        child: driver.profilePhotoUrl != null
                            ? HavitNetworkImage(
                                imageUrl: driver.profilePhotoUrl!,
                                fit: BoxFit.cover,
                              )
                            : ColoredBox(
                                color: scheme.primary.withValues(alpha: 0.15),
                                child: Center(
                                  child: CustomText(
                                    initial,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      color: scheme.primary,
                                    ),
                                  ),
                                ),
                              ),
                      ),
                    ),
                    PositionedDirectional(
                      end: -1,
                      bottom: -1,
                      child: Container(
                        width: 13,
                        height: 13,
                        decoration: BoxDecoration(
                          color: driver.online
                              ? AppColors.success
                              : scheme.outline,
                          shape: BoxShape.circle,
                          border: Border.all(color: scheme.surface, width: 2),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: AppSizes.spaceMd),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CustomText(
                        driver.displayName,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${driver.phone} · $vehicleLabel',
                        style: TextStyle(
                          fontSize: 12,
                          color: scheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                      const SizedBox(height: AppSizes.spaceXs),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          _Pill(
                            label: (driver.online
                                    ? AppStrings.Drivers.online
                                    : AppStrings.Drivers.offline)
                                .tr,
                            color: driver.online
                                ? AppColors.success
                                : scheme.onSurface.withValues(alpha: 0.55),
                          ),
                          if (driver.isBusy)
                            _Pill(
                              label: AppStrings.Drivers.onDelivery.tr,
                              color: scheme.primary,
                            ),
                          if (driver.status != 'active')
                            // Store accepted; the account is still with admins.
                            _Pill(
                              label: AppStrings.Drivers.accountUnderReview.tr,
                              color: AppColors.warning,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (busy)
                  const Padding(
                    padding: EdgeInsets.all(AppSizes.spaceSm),
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                else
                  IconButton(
                    tooltip: AppStrings.Drivers.remove.tr,
                    onPressed: onRemove,
                    icon: Icon(Icons.link_off, color: scheme.error),
                  ),
              ],
            ),
            const SizedBox(height: AppSizes.spaceMd),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.spaceMd,
                vertical: AppSizes.spaceSm,
              ),
              decoration: BoxDecoration(
                color: AppColors.thirdColor.withValues(alpha: 0.28),
                borderRadius: BorderRadius.circular(AppSizes.radiusMd),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomText(
                    AppStrings.Drivers.ordersToday
                        .trParams({'count': '${stats.total}'}),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: AppSizes.spaceXs),
                  Row(
                    children: [
                      _MiniStat(
                        label: AppStrings.Drivers.statDelivered.tr,
                        value: stats.delivered,
                        color: AppColors.success,
                      ),
                      _MiniStat(
                        label: AppStrings.Drivers.statActive.tr,
                        value: stats.active,
                        color: scheme.primary,
                      ),
                      _MiniStat(
                        label: AppStrings.Drivers.statCancelled.tr,
                        value: stats.cancelled,
                        color: AppColors.error,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$value',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: value == 0
                  ? Theme.of(context).colorScheme.onSurface.withValues(
                        alpha: 0.4,
                      )
                  : color,
            ),
          ),
          CustomText(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11,
              color:
                  Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.spaceSm,
        vertical: 3,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(AppSizes.radiusSm),
      ),
      child: CustomText(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}
