import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:toukh_provider/features/orders/presentation/widgets/order_detail/order_detail_section_title.dart';
import 'package:toukh_provider/features/orders/presentation/widgets/order_detail/order_detail_surface_card.dart';
import 'package:toukh_provider/l10n/app_strings.dart';
import 'package:toukh_ui/toukh_ui.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:toukh_provider/di/service_locator.dart';
import 'package:toukh_provider/features/auth/cubit/auth_cubit.dart';

/// Shared client contact + address payload for order detail screens.
class ClientDetailsViewData {
  const ClientDetailsViewData({
    required this.name,
    this.phone,
    this.photoUrl,
    this.addressTitle,
    this.addressFormatted,
    this.lat = 0,
    this.lng = 0,
    this.canView = true,
    this.hiddenMessage,
    this.nameOnly = false,
    this.whatsAppMessage,
  });

  final String name;
  final String? phone;
  final String? photoUrl;
  final String? addressTitle;
  final String? addressFormatted;
  final double lat;
  final double lng;
  final bool canView;
  final String? hiddenMessage;
  final bool nameOnly;

  /// Prefilled WhatsApp text (order status + what happens next).
  final String Function()? whatsAppMessage;

  bool get hasCoords => lat != 0 || lng != 0;

  factory ClientDetailsViewData.fromOrderRow(ProviderMasterOrderRow row) {
    final address = providerDisplayDeliveryAddress(row.master, row.slice);
    final phone = row.slice.customerPhone?.trim().isNotEmpty == true
        ? row.slice.customerPhone!.trim()
        : row.master.customerPhone?.trim();

    return ClientDetailsViewData(
      name: providerDisplayCustomerName(
        row.master,
        row.slice,
        genericLabel: AppStrings.Orders.detailCustomer.tr,
      ),
      phone: phone,
      photoUrl: providerDisplayCustomerPhotoUrl(row.master, row.slice),
      addressTitle: address.label?.trim(),
      addressFormatted: address.formattedAddress?.trim(),
      lat: address.lat,
      lng: address.lng,
      canView: row.canViewCustomerContact,
      hiddenMessage: AppStrings.Orders.pharmacyCustomerContactHidden.tr,
      whatsAppMessage: () => customerWhatsAppMessage(row),
    );
  }
}

/// "Hello …, this is [store] about your order #…": status + next step.
String customerWhatsAppMessage(ProviderMasterOrderRow row) {
  final auth = getIt<AuthCubit>().state;
  final store = row.slice.providerName?.trim().isNotEmpty == true
      ? row.slice.providerName!.trim()
      : (auth is Authenticated ? auth.profile.name : '');
  final name = row.slice.customerName?.trim().isNotEmpty == true
      ? row.slice.customerName!.trim()
      : (row.master.customerName?.trim() ?? '');
  final action = switch (row.slice.statusWire) {
    'pending' || 'placed' => AppStrings.Orders.waActionPending,
    'accepted' || 'preparing' => AppStrings.Orders.waActionPreparing,
    'ready_for_pickup' => AppStrings.Orders.waActionReady,
    'picked_up' || 'out_for_delivery' => AppStrings.Orders.waActionOnTheWay,
    'delivered' || 'completed' => AppStrings.Orders.waActionDelivered,
    'cancelled' => AppStrings.Orders.waActionCancelled,
    _ => AppStrings.Orders.waActionDefault,
  };
  final statusKey = row.isAwaitingStoreDriverAccept
      ? AppStrings.Orders.awaitingDriverApproval
      : ToukhStatusKeys.provider(row.slice.statusWire);
  return ToukhContactLinks.arabic(AppStrings.Orders.waCustomerMessage, {
    'name': name,
    'store': store,
    'order': ToukhContactLinks.orderRef(row.master.id),
    'status': ToukhContactLinks.arabic(statusKey),
    'action': ToukhContactLinks.arabic(action),
  });
}

/// Shared client details card used by all provider order-detail screens.
class ClientDetailsCard extends StatelessWidget {
  const ClientDetailsCard({super.key, required this.data});

  final ClientDetailsViewData data;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return OrderDetailSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          OrderDetailSectionTitle(
            label: AppStrings.Orders.detailClient.tr,
            icon: PhosphorIconsRegular.userCircle,
          ),
          const SizedBox(height: AppSizes.spaceMd),
          if (!data.canView)
            CustomText(
              data.hiddenMessage ??
                  AppStrings.Orders.pharmacyCustomerContactHidden.tr,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurface.withValues(alpha: 0.75),
                  ),
            )
          else
            _ClientDetailsBody(data: data),
        ],
      ),
    );
  }
}

/// Store / pharmacy order detail adapter.
class OrderDetailClientDetailsCard extends StatelessWidget {
  const OrderDetailClientDetailsCard({super.key, required this.row});

  final ProviderMasterOrderRow row;

  @override
  Widget build(BuildContext context) {
    final finished = row.slice.isDelivered || row.slice.isTerminal;
    final data = ClientDetailsViewData.fromOrderRow(row);
    return ClientDetailsCard(
      data: finished
          ? ClientDetailsViewData(name: data.name, nameOnly: true)
          : data,
    );
  }
}

class _ClientDetailsBody extends StatelessWidget {
  const _ClientDetailsBody({required this.data});

  final ClientDetailsViewData data;

  Future<void> _openMap(BuildContext context) async {
    if (!data.hasCoords) {
      AppSnack.show(
        context,
        message: AppStrings.Orders.mapUnavailable.tr,
        state: AppSnackState.error,
        icon: ToukhIcons.error,
      );
      return;
    }

    final uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=${data.lat},${data.lng}',
    );
    if (!await canLaunchUrl(uri)) {
      if (!context.mounted) return;
      AppSnack.show(
        context,
        message: AppStrings.Orders.mapUnavailable.tr,
        state: AppSnackState.error,
        icon: ToukhIcons.error,
      );
      return;
    }
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final photoUrl = data.photoUrl?.trim();
    final hasPhoto = photoUrl != null && photoUrl.isNotEmpty;
    final phone = data.phone?.trim();
    final addressTitle = data.addressTitle?.trim();
    final addressLine = data.addressFormatted?.trim();

    if (data.nameOnly) {
      return CustomText(
        data.name,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            ToukhProfileAvatar(
              imageUrl: hasPhoto ? photoUrl : null,
              size: 56,
              backgroundColor: AppColors.appColor.withValues(alpha: 0.14),
            ),
            const SizedBox(width: AppSizes.spaceMd),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomText(
                    data.name,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  if (phone != null && phone.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          ToukhIcons.phone,
                          size: 16,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: AppSizes.spaceSm),
                        Expanded(
                          child: CustomText(
                            ToukhContactLinks.localPhone(phone),
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: scheme.onSurface
                                      .withValues(alpha: 0.75),
                                ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            if (phone != null && phone.isNotEmpty)
              ToukhContactActions(
                phone: phone,
                whatsAppMessage: data.whatsAppMessage,
                callTooltip: AppStrings.Orders.callCustomer.tr,
                whatsAppTooltip: AppStrings.Orders.whatsAppCustomer.tr,
              ),
          ],
        ),
        const SizedBox(height: AppSizes.spaceMd),
        Container(
          padding: const EdgeInsets.all(AppSizes.spaceMd),
          decoration: BoxDecoration(
            color: AppColors.thirdColor.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(ToukhIcons.location, color: Theme.of(context).colorScheme.primary, size: 22),
              const SizedBox(width: AppSizes.spaceMd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomText(
                      (addressTitle != null && addressTitle.isNotEmpty)
                          ? addressTitle
                          : AppStrings.Orders.detailDropoff.tr,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 4),
                    CustomText(
                      (addressLine != null && addressLine.isNotEmpty)
                          ? addressLine
                          : AppStrings.Orders.noAddress.tr,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.65),
                          ),
                    ),
                    if (data.hasCoords) ...[
                      const SizedBox(height: 2),
                      CustomText(
                        '${data.lat.toStringAsFixed(5)}, ${data.lng.toStringAsFixed(5)}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: scheme.onSurface.withValues(alpha: 0.5),
                              fontSize: 11,
                            ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        if (data.hasCoords) ...[
          const SizedBox(height: AppSizes.spaceSm),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: TextButton.icon(
              onPressed: () => _openMap(context),
              icon: Icon(
                ToukhIcons.location,
                size: 18,
                color: Theme.of(context).colorScheme.primary,
              ),
              label: CustomText(
                AppStrings.Orders.viewOnMap.tr,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppColors.appColor,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
