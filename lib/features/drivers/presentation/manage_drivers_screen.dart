import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:toukh_provider/domain/entities/provider_driver_link_request.dart';
import 'package:toukh_provider/domain/entities/provider_linked_driver.dart';
import 'package:toukh_provider/features/drivers/cubit/manage_drivers_cubit.dart';
import 'package:toukh_provider/l10n/app_strings.dart';
import 'package:toukh_ui/toukh_ui.dart';

class ManageDriversScreen extends StatelessWidget {
  const ManageDriversScreen({super.key});

  void _copyProviderId(BuildContext context, String providerId) {
    Clipboard.setData(ClipboardData(text: providerId));
    AppSnack.show(
      context,
      message: AppStrings.Settings.copied.tr,
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
            prev.error != next.error && next.error != null,
        listener: (context, state) {
          if (state.error == null) return;
          AppSnack.show(
            context,
            message: AppStrings.Drivers.actionFailed.tr,
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

          return ListView(
            padding: AppSizes.screenPadding,
            children: [
              _ProviderIdCard(
                providerId: state.providerId,
                onCopy: () => _copyProviderId(context, state.providerId),
              ),
              const SizedBox(height: AppSizes.spaceXl),
              _SectionTitle(label: AppStrings.Drivers.pendingRequests.tr),
              const SizedBox(height: AppSizes.spaceSm),
              if (state.pendingRequests.isEmpty)
                _EmptySection(message: AppStrings.Drivers.noPendingRequests.tr)
              else
                ...state.pendingRequests.map(
                  (r) => Padding(
                    padding: const EdgeInsets.only(bottom: AppSizes.spaceSm),
                    child: _PendingRequestCard(
                      request: r,
                      vehicleLabel: _vehicleLabel(r.vehicleType),
                      dateFmt: dateFmt,
                      busy: state.actionInProgress == r.uid,
                      anyBusy: state.actionInProgress != null,
                      onAccept: () async {
                        final ok = await context
                            .read<ManageDriversCubit>()
                            .acceptRequest(r.uid);
                        if (ok && context.mounted) {
                          AppSnack.show(
                            context,
                            message: AppStrings.Drivers.requestAccepted.tr,
                            state: AppSnackState.success,
                            icon: ToukhIcons.check,
                          );
                        }
                      },
                      onReject: () async {
                        final ok = await context
                            .read<ManageDriversCubit>()
                            .rejectRequest(r.uid);
                        if (ok && context.mounted) {
                          AppSnack.show(
                            context,
                            message: AppStrings.Drivers.requestRejected.tr,
                            state: AppSnackState.alert,
                            icon: ToukhIcons.info,
                          );
                        }
                      },
                    ),
                  ),
                ),
              const SizedBox(height: AppSizes.spaceXl),
              _SectionTitle(label: AppStrings.Drivers.linkedDrivers.tr),
              const SizedBox(height: AppSizes.spaceSm),
              if (state.linkedDrivers.isEmpty)
                _EmptySection(message: AppStrings.Drivers.noLinkedDrivers.tr)
              else
                ...state.linkedDrivers.map(
                  (d) => Padding(
                    padding: const EdgeInsets.only(bottom: AppSizes.spaceSm),
                    child: _LinkedDriverCard(
                      driver: d,
                      vehicleLabel: _vehicleLabel(d.vehicleType),
                    ),
                  ),
                ),
              const SizedBox(height: AppSizes.space2xl),
            ],
          );
        },
      ),
    );
  }
}

class _ProviderIdCard extends StatelessWidget {
  const _ProviderIdCard({
    required this.providerId,
    required this.onCopy,
  });

  final String providerId;
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
          CustomText(
            AppStrings.Settings.providerId.tr,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: scheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: AppSizes.spaceSm),
          Row(
            children: [
              Expanded(
                child: SelectableText(
                  providerId,
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: scheme.onSurface,
                  ),
                ),
              ),
              IconButton(
                tooltip: AppStrings.Settings.copyProviderId.tr,
                onPressed: onCopy,
                icon: Icon(
                  PhosphorIconsRegular.copy,
                  color: AppColors.appColor,
                ),
              ),
            ],
          ),
          CustomText(
            AppStrings.Settings.copyProviderIdHint.tr,
            style: TextStyle(
              fontSize: 12,
              color: scheme.onSurface.withValues(alpha: 0.55),
              height: 1.35,
            ),
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
                CircleAvatar(
                  backgroundImage: request.profilePhotoUrl != null
                      ? NetworkImage(request.profilePhotoUrl!)
                      : null,
                  backgroundColor: scheme.primary.withValues(alpha: 0.15),
                  foregroundColor: scheme.primary,
                  child: request.profilePhotoUrl == null
                      ? CustomText(
                          initial,
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        )
                      : null,
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
                          dateFmt.format(request.submittedAt!),
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
    required this.vehicleLabel,
  });

  final ProviderLinkedDriver driver;
  final String vehicleLabel;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final initial = driver.displayName.trim().isNotEmpty
        ? driver.displayName.trim()[0].toUpperCase()
        : '?';
    final onlineLabel = driver.online
        ? AppStrings.Drivers.online.tr
        : AppStrings.Drivers.offline.tr;

    return Card(
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
          backgroundImage: driver.profilePhotoUrl != null
              ? NetworkImage(driver.profilePhotoUrl!)
              : null,
          backgroundColor: scheme.primary.withValues(alpha: 0.15),
          foregroundColor: scheme.primary,
          child: driver.profilePhotoUrl == null
              ? CustomText(
                  initial,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                )
              : null,
        ),
        title: CustomText(
          driver.displayName,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        subtitle: CustomText(
          '${driver.phone} · $vehicleLabel',
          style: TextStyle(
            fontSize: 12,
            color: scheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.spaceSm,
            vertical: 4,
          ),
          decoration: BoxDecoration(
            color: (driver.online ? AppColors.success : scheme.outline)
                .withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(AppSizes.radiusSm),
          ),
          child: CustomText(
            onlineLabel,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: driver.online ? AppColors.success : scheme.onSurface.withValues(alpha: 0.55),
            ),
          ),
        ),
      ),
    );
  }
}
