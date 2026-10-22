import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart' show DateFormat, NumberFormat;
import 'package:toukh_provider/domain/entities/company_courier.dart';
import 'package:toukh_provider/core/router/app_routes.dart';
import 'package:toukh_provider/domain/entities/company_courier_stats.dart';
import 'package:toukh_provider/domain/entities/delivery_company.dart';
import 'package:toukh_provider/l10n/app_strings.dart';
import 'package:toukh_ui/toukh_ui.dart';

// ---------------------------------------------------------------- formatting

String companyKm(double meters) {
  final km = meters / 1000;
  final v = km >= 100 ? km.toStringAsFixed(0) : km.toStringAsFixed(1);
  return AppStrings.Company.kmValue.trParams({'value': v});
}

String companyEgp(double egp) {
  final v = NumberFormat.decimalPattern('en').format(egp.round());
  return AppStrings.Company.egpValue.trParams({'value': v});
}

String companyVehicleLabel(String wire) {
  switch (wire) {
    case 'motorcycle':
      return AppStrings.Drivers.vehicleMotorcycle.tr;
    case 'bicycle':
      return AppStrings.Drivers.vehicleBicycle.tr;
    case 'tuk_tuk':
    case 'tuktuk':
      return AppStrings.Drivers.vehicleTukTuk.tr;
    case 'car':
      return AppStrings.Company.vehicleCar.tr;
    default:
      return wire;
  }
}

String companyTripTypeLabel(String kind) {
  switch (kind) {
    case 'restaurants':
      return AppStrings.Company.tripRestaurants.tr;
    case 'grocery':
      return AppStrings.Company.tripGrocery.tr;
    case 'supermarket':
      return AppStrings.Company.tripSupermarket.tr;
    case 'pharmacy':
      return AppStrings.Company.tripPharmacy.tr;
    case 'explore':
      return AppStrings.Company.tripExplore.tr;
    case 'multi_stop':
      return AppStrings.Company.tripMultiStop.tr;
    case 'ride':
      return AppStrings.Company.tripRide.tr;
    default:
      return AppStrings.Company.tripOther.tr;
  }
}

IconData companyTripTypeIcon(String kind) {
  switch (kind) {
    case 'restaurants':
      return ToukhIcons.restaurant;
    case 'grocery':
    case 'supermarket':
      return ToukhIcons.cart;
    case 'pharmacy':
      return PhosphorIconsRegular.firstAid;
    case 'multi_stop':
      return PhosphorIconsRegular.path;
    case 'ride':
      return PhosphorIconsRegular.car;
    default:
      return ToukhIcons.delivery;
  }
}

String companyJobStatusLabel(String status) {
  switch (status) {
    case 'delivered':
      return AppStrings.Company.jobDelivered.tr;
    case 'completed':
      return AppStrings.Company.jobCompleted.tr;
    case 'cancelled':
    case 'canceled':
      return AppStrings.Company.jobCancelled.tr;
    case 'assigned':
    case 'accepted':
    case 'en_route_pickup':
      return AppStrings.Company.jobAssigned.tr;
    case 'partially_picked':
    case 'picked_up':
      return AppStrings.Company.jobPickedUp.tr;
    case 'on_the_way':
      return AppStrings.Company.jobOnTheWay.tr;
    default:
      return AppStrings.Company.jobInProgress.tr;
  }
}

// ------------------------------------------------------------------ widgets

class CompanySectionTitle extends StatelessWidget {
  const CompanySectionTitle(this.label, {super.key, this.trailing});

  final String label;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: CustomText(
            label,
            style: const TextStyle(
              fontSize: AppSizes.fontTitle,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        ?trailing,
      ],
    );
  }
}

class CompanyEmptyNote extends StatelessWidget {
  const CompanyEmptyNote(this.message, {super.key, this.icon});

  final String message;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSizes.spaceLg),
      decoration: ToukhCard.decoration(context),
      child: Column(
        children: [
          Icon(
            icon ?? ToukhIcons.info,
            color: scheme.onSurface.withValues(alpha: 0.4),
          ),
          SizedBox(height: AppSizes.spaceSm),
          CustomText(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(color: scheme.onSurface.withValues(alpha: 0.65)),
          ),
        ],
      ),
    );
  }
}

/// Compact number tile used in grids.
class CompanyStatTile extends StatelessWidget {
  const CompanyStatTile({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(AppSizes.spaceMd),
      decoration: ToukhCard.decoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ToukhIconWell(
            icon: icon,
            color: color ?? AppColors.secondColor,
            size: 32,
            iconSize: 17,
          ),
          const SizedBox(height: AppSizes.spaceSm),
          CustomText(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: scheme.onSurface,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          CustomText(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

/// Grid that keeps tiles readable from phone to desktop widths.
class CompanyStatGrid extends StatelessWidget {
  const CompanyStatGrid({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 900
            ? 6
            : constraints.maxWidth >= 560
            ? 3
            : 2;
        return GridView.count(
          crossAxisCount: columns,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: AppSizes.spaceSm,
          crossAxisSpacing: AppSizes.spaceSm,
          childAspectRatio: 1.45,
          children: children,
        );
      },
    );
  }
}

class CourierAvatar extends StatelessWidget {
  const CourierAvatar({super.key, required this.courier, this.radius = 24});

  final CompanyCourier courier;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final url = courier.profilePhotoUrl;
    final dotColor = courier.online ? AppColors.success : scheme.outline;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        CircleAvatar(
          radius: radius,
          backgroundColor: scheme.surfaceContainerHighest,
          backgroundImage: url != null ? NetworkImage(url) : null,
          child: url == null
              ? Icon(ToukhIcons.person, color: AppColors.secondColor)
              : null,
        ),
        PositionedDirectional(
          end: -1,
          bottom: -1,
          child: Container(
            width: radius * 0.55,
            height: radius * 0.55,
            decoration: BoxDecoration(
              color: dotColor,
              shape: BoxShape.circle,
              border: Border.all(color: scheme.surface, width: 2),
            ),
          ),
        ),
      ],
    );
  }
}

class CompanyChip extends StatelessWidget {
  const CompanyChip({super.key, required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppSizes.radiusFull),
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

/// Online / busy / disabled / awaiting admin chips for a courier.
List<Widget> courierStatusChips(BuildContext context, CompanyCourier c) {
  final scheme = Theme.of(context).colorScheme;
  return [
    if (!c.enabled)
      CompanyChip(label: AppStrings.Company.disabled.tr, color: scheme.error)
    else if (!c.isPlatformActive)
      CompanyChip(
        label: AppStrings.Company.awaitingAdmin.tr,
        color: AppColors.warning,
      )
    else
      CompanyChip(
        label: c.online
            ? AppStrings.Drivers.online.tr
            : AppStrings.Drivers.offline.tr,
        color: c.online ? AppColors.success : scheme.outline,
      ),
    if (c.isBusy)
      CompanyChip(
        label: AppStrings.Company.busy.tr,
        color: AppColors.secondColor,
      ),
  ];
}

class CourierActiveJobTile extends StatelessWidget {
  const CourierActiveJobTile({super.key, required this.job, this.onTap});

  final CourierActiveJob job;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final muted = scheme.onSurface.withValues(alpha: 0.65);
    final time = job.startedAt == null
        ? null
        : DateFormat.jm(
            Localizations.localeOf(context).toLanguageTag(),
          ).format(job.startedAt!);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        child: Container(
          padding: const EdgeInsets.all(AppSizes.spaceMd),
          decoration: ToukhCard.decoration(context),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ToukhIconWell(
                icon: job.isRide
                    ? PhosphorIconsRegular.car
                    : ToukhIcons.delivery,
                color: AppColors.secondColor,
                size: 36,
                iconSize: 18,
              ),
              SizedBox(width: AppSizes.spaceMd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: CustomText(
                            job.courierName ??
                                (job.isRide
                                    ? AppStrings.Company.jobRide.tr
                                    : AppStrings.Company.jobDelivery.tr),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                        CompanyChip(
                          label: companyJobStatusLabel(job.status),
                          color: AppColors.secondColor,
                        ),
                      ],
                    ),
                    SizedBox(height: AppSizes.spaceXs),
                    CompanyJobLine(
                      icon: ToukhIcons.store,
                      text: job.pickupLabel ?? '—',
                      color: muted,
                    ),
                    CompanyJobLine(
                      icon: ToukhIcons.location,
                      text: job.dropoffLabel ?? '—',
                      color: muted,
                    ),
                    if (job.feeEgp > 0 || time != null) ...[
                      SizedBox(height: AppSizes.spaceXs),
                      CustomText(
                        [
                          if (job.feeEgp > 0) companyEgp(job.feeEgp),
                          ?time,
                        ].join(' · '),
                        style: TextStyle(fontSize: 12, color: muted),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CompanyJobLine extends StatelessWidget {
  const CompanyJobLine({
    super.key,
    required this.icon,
    required this.text,
    required this.color,
  });

  final IconData icon;
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Row(
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Expanded(
            child: CustomText(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 13, color: color),
            ),
          ),
        ],
      ),
    );
  }
}

/// Company ID with copy / share: couriers enter it to join.
class CompanyIdCard extends StatelessWidget {
  const CompanyIdCard({super.key, required this.company});

  final DeliveryCompany company;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(AppSizes.spaceMd),
      decoration: BoxDecoration(
        color: AppColors.secondColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        border: Border.all(
          color: AppColors.secondColor.withValues(alpha: 0.25),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomText(
            AppStrings.Company.idTitle,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: AppSizes.spaceXs),
          CustomText(
            AppStrings.Company.idHint,
            style: TextStyle(
              fontSize: AppSizes.fontCaption,
              color: scheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: AppSizes.spaceSm),
          SelectableText(
            company.uid,
            style: const TextStyle(
              fontFamily: 'monospace',
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: AppSizes.spaceSm),
          Wrap(
            spacing: AppSizes.spaceSm,
            runSpacing: AppSizes.spaceSm,
            children: [
              AppOutlinedButton(
                text: AppStrings.Company.copyId.tr,
                icon: ToukhIcons.copy,
                onTap: () {
                  Clipboard.setData(ClipboardData(text: company.uid));
                  AppSnack.show(
                    context,
                    message: AppStrings.Settings.copied.tr,
                    state: AppSnackState.success,
                    icon: ToukhIcons.check,
                  );
                },
              ),
              AppOutlinedButton(
                text: AppStrings.Company.shareId.tr,
                icon: PhosphorIconsRegular.shareNetwork,
                onTap: () => Share.share(
                  AppStrings.Company.shareIdMessage.trParams({
                    'name': company.companyName,
                    'id': company.uid,
                  }),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class CompanyCourierTile extends StatelessWidget {
  const CompanyCourierTile({
    super.key,
    required this.courier,
    this.ordersToday,
  });

  final CompanyCourier courier;
  final int? ordersToday;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        onTap: () => context.push(AppRoutes.companyCourierPath(courier.uid)),
        child: Container(
          padding: const EdgeInsets.all(AppSizes.spaceMd),
          decoration: ToukhCard.decoration(context),
          child: Row(
            children: [
              CourierAvatar(courier: courier),
              const SizedBox(width: AppSizes.spaceMd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomText(
                      courier.displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 2),
                    CustomText(
                      [
                        companyVehicleLabel(courier.vehicleType),
                        if (ordersToday != null)
                          AppStrings.Company.ordersTodayCount.trParams({
                            'count': '$ordersToday',
                          }),
                      ].join(' · '),
                      style: TextStyle(
                        fontSize: 12,
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
              Icon(
                Directionality.of(context) == TextDirection.rtl
                    ? PhosphorIconsRegular.caretLeft
                    : ToukhIcons.chevronRight,
                color: scheme.onSurface.withValues(alpha: 0.4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
