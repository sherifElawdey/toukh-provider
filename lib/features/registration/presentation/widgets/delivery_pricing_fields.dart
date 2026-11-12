import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:toukh_provider/domain/entities/delivery_config.dart';
import 'package:toukh_provider/l10n/app_strings.dart';
import 'package:toukh_ui/toukh_ui.dart';

/// A store's delivery choices. Stores never type in a fee: paid delivery is
/// priced by Havit ([DeliveryPricingMode.app]).
class DeliveryChoice {
  const DeliveryChoice({
    this.offers = false,
    this.free = false,
    this.ownAccount = false,
  });

  /// Reads saved configs, older ones included. A store that delivered from
  /// its account without "offers delivery" was charged nothing, so it reads
  /// as free own delivery.
  factory DeliveryChoice.fromConfig(DeliveryConfig? c) {
    if (c == null) return const DeliveryChoice();
    final offers = c.offersDelivery || c.manageFromAccount;
    return DeliveryChoice(
      offers: offers,
      free: offers && (c.isFree || !c.offersDelivery),
      ownAccount: offers && c.manageFromAccount,
    );
  }

  /// Store delivers its orders (otherwise Havit couriers do).
  final bool offers;

  /// Customer pays no delivery fee; otherwise Havit pricing applies.
  final bool free;

  /// Store delivers from this account; otherwise it assigns couriers.
  final bool ownAccount;

  DeliveryChoice copyWith({bool? offers, bool? free, bool? ownAccount}) {
    return DeliveryChoice(
      offers: offers ?? this.offers,
      free: free ?? this.free,
      ownAccount: ownAccount ?? this.ownAccount,
    );
  }

  DeliveryConfig toConfig({int? avgPrepMinutes}) {
    return DeliveryConfig(
      offersDelivery: offers,
      isFree: offers && free,
      manageFromAccount: offers && ownAccount,
      pricingMode: offers && !free ? DeliveryPricingMode.app : null,
      avgPrepMinutes: avgPrepMinutes,
    );
  }
}

/// Delivery setup: does the store deliver, and if so, is it free or priced
/// by Havit, and does it deliver from this account or through couriers.
class DeliveryOptionsFields extends StatelessWidget {
  const DeliveryOptionsFields({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final DeliveryChoice value;
  final ValueChanged<DeliveryChoice> onChanged;

  @override
  Widget build(BuildContext context) {
    final noteStyle = TextStyle(
      fontSize: AppSizes.fontCaption,
      height: 1.45,
      color: AppColors.muted(context),
    );
    final headingStyle = TextStyle(
      fontSize: AppSizes.fontCaption,
      fontWeight: FontWeight.w700,
      color: AppColors.muted(context),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          activeThumbColor: AppColors.secondColor,
          title: CustomText(
            AppStrings.Registration.deliveryOffers,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          value: value.offers,
          onChanged: (v) => onChanged(value.copyWith(offers: v)),
        ),
        if (!value.offers)
          _InfoNote(text: AppStrings.Registration.deliveryHavitFeeNote)
        else ...[
          SizedBox(height: AppSizes.spaceSm),
          CustomText(AppStrings.Registration.deliveryFeeTitle, style: headingStyle),
          SizedBox(height: AppSizes.spaceSm),
          _OptionTile(
            icon: PhosphorIconsDuotone.gift,
            title: AppStrings.Registration.reviewDeliveryFree,
            subtitle: AppStrings.Registration.deliveryFreeHint,
            selected: value.free,
            onTap: () => onChanged(value.copyWith(free: true)),
          ),
          SizedBox(height: AppSizes.spaceSm),
          _OptionTile(
            icon: PhosphorIconsDuotone.calculator,
            title: AppStrings.Registration.deliveryAppPricing,
            subtitle: AppStrings.Registration.deliveryAppPricingHint,
            selected: !value.free,
            onTap: () => onChanged(value.copyWith(free: false)),
          ),
          SizedBox(height: AppSizes.spaceLg),
          CustomText(AppStrings.Registration.deliveryByTitle, style: headingStyle),
          SizedBox(height: AppSizes.spaceSm),
          _OptionTile(
            icon: PhosphorIconsDuotone.storefront,
            title: AppStrings.Registration.deliveryManageFromAccount,
            subtitle: AppStrings.Registration.deliveryManageFromAccountHint,
            selected: value.ownAccount,
            onTap: () => onChanged(value.copyWith(ownAccount: true)),
          ),
          SizedBox(height: AppSizes.spaceSm),
          _OptionTile(
            icon: PhosphorIconsDuotone.moped,
            title: AppStrings.Registration.deliveryByCouriers,
            subtitle: AppStrings.Registration.deliveryByCouriersHint,
            selected: !value.ownAccount,
            onTap: () => onChanged(value.copyWith(ownAccount: false)),
          ),
          if (!value.free) ...[
            SizedBox(height: AppSizes.spaceSm),
            CustomText(AppStrings.Registration.deliveryAppPricingNote, style: noteStyle),
          ],
        ],
      ],
    );
  }
}

class _InfoNote extends StatelessWidget {
  const _InfoNote({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: AppSizes.spaceSm),
      padding: const EdgeInsets.all(AppSizes.spaceMd),
      decoration: BoxDecoration(
        color: AppColors.tint(context, AppColors.secondColor),
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(PhosphorIconsRegular.info, size: 18, color: AppColors.secondColor),
          SizedBox(width: AppSizes.spaceSm),
          Expanded(
            child: CustomText(
              text,
              style: TextStyle(
                fontSize: AppSizes.fontCaption,
                height: 1.45,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// One selectable answer in a single-choice group.
class _OptionTile extends StatelessWidget {
  const _OptionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final accent = AppColors.secondColor;
    final radius = BorderRadius.circular(AppSizes.radiusMd);
    return Semantics(
      selected: selected,
      button: true,
      child: Material(
        color: selected ? AppColors.tint(context, accent) : Colors.transparent,
        borderRadius: radius,
        child: InkWell(
          borderRadius: radius,
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(AppSizes.spaceMd),
            decoration: BoxDecoration(
              borderRadius: radius,
              border: Border.all(
                color: selected ? accent : scheme.outlineVariant,
                width: selected ? 1.5 : 1,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, size: 22, color: selected ? accent : AppColors.muted(context)),
                SizedBox(width: AppSizes.spaceMd),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CustomText(
                        title,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      SizedBox(height: AppSizes.spaceXs),
                      CustomText(
                        subtitle,
                        style: TextStyle(
                          fontSize: AppSizes.fontCaption,
                          height: 1.45,
                          color: AppColors.muted(context),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: AppSizes.spaceSm),
                Icon(
                  selected
                      ? PhosphorIconsFill.checkCircle
                      : PhosphorIconsRegular.circle,
                  size: 20,
                  color: selected ? accent : scheme.outline,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Text for a fee, or empty when unset.
String deliveryFeeText(double? v) {
  if (v == null || v <= 0) return '';
  return v == v.roundToDouble() ? v.toInt().toString() : v.toString();
}

/// One line describing a saved delivery config, older fee-based ones
/// included (until the store saves its delivery choices again).
String deliveryConfigSummary(DeliveryConfig c) {
  final choice = DeliveryChoice.fromConfig(c);
  if (!choice.offers) return AppStrings.Registration.reviewDeliveryNone.tr;
  final by = choice.ownAccount
      ? AppStrings.Registration.deliveryManageFromAccount.tr
      : AppStrings.Registration.deliveryByCouriers.tr;
  final String fee;
  if (choice.free) {
    fee = AppStrings.Registration.reviewDeliveryFree.tr;
  } else if (c.pricingMode == null || c.pricingMode == DeliveryPricingMode.app) {
    fee = AppStrings.Registration.deliveryAppPricing.tr;
  } else if (c.pricingMode == DeliveryPricingMode.byRegion) {
    String f(double? v) => deliveryFeeText(v).isEmpty ? '—' : deliveryFeeText(v);
    fee = AppStrings.Registration.reviewDeliveryByRegion.trParams({
      'inner': f(c.innerCityFeeEgp),
      'outer': f(c.outerCityFeeEgp),
    });
  } else {
    final price = deliveryFeeText(c.priceEgp);
    fee = AppStrings.Registration.reviewDeliveryPaid.trParams({
      'price': price.isEmpty ? '—' : price,
      'mode': c.pricingMode == DeliveryPricingMode.perKm
          ? AppStrings.Registration.deliveryModePerKm.tr
          : AppStrings.Registration.deliveryModeFixed.tr,
    });
  }
  return '$fee · $by';
}
