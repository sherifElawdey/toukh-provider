import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:toukh_ui/toukh_ui.dart';
import 'package:toukh_provider/domain/entities/provider_kind.dart';
import 'package:toukh_provider/domain/entities/provider_profile.dart';
import 'package:toukh_provider/domain/entities/shop_category.dart';

/// Hero profile card for provider settings.
class SettingsProfileHeaderCard extends StatelessWidget {
  const SettingsProfileHeaderCard({
    super.key,
    required this.profile,
    required this.onTap,
  });

  final ProviderProfile profile;
  final VoidCallback onTap;

  String _phoneLine() {
    final p = profile.phone.trim();
    if (p.isEmpty) return '—';
    final digits = p.replaceAll(RegExp(r'\D'), '');
    if (digits.length == 11 && digits.startsWith('0')) {
      return '+20 ${digits.substring(1)}';
    }
    if (digits.length == 10) {
      return '+20 $digits';
    }
    return p;
  }

  String _subtitle() {
    final t = profile.serviceType;
    if (t == ServiceType.restaurant && profile.shopCategory != null) {
      switch (profile.shopCategory!) {
        case ShopCategory.pharmacy:
          return 'registration.shop_pharmacy'.tr;
        case ShopCategory.supermarket:
          return 'registration.shop_supermarket'.tr;
        case ShopCategory.fruitVeg:
          return 'registration.shop_fruit_veg'.tr;
        case ShopCategory.restaurant:
          return 'registration.shop_restaurant'.tr;
      }
    }
    if (t == ServiceType.homeService && profile.serviceCategoryId != null) {
      return profile.serviceCategoryId!;
    }
    switch (t) {
      case ServiceType.restaurant:
        return 'registration.kind_restaurant'.tr;
      case ServiceType.homeService:
        return 'registration.kind_home_service'.tr;
      case ServiceType.supermarket:
        return 'registration.kind_supermarket'.tr;
      case ServiceType.grocery:
        return 'registration.kind_grocery'.tr;
      case ServiceType.pharmacy:
        return 'registration.kind_pharmacy'.tr;
      case ServiceType.homeBrands:
        return 'registration.kind_home_brands'.tr;
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final url = profile.brandImageUrl;

    return Material(
      elevation: 0,
      color: AppColors.appColor.withValues(alpha: 0.2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.spaceLg),
          child: Row(
            children: [
              ClipOval(
                child: Container(
                  width: 64,
                  height: 64,
                  color: AppColors.thirdColor.withValues(alpha: 0.6),
                  child: url != null && url.isNotEmpty
                      ? Image.network(
                          url,
                          width: 64,
                          height: 64,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Icon(
                            Icons.storefront_rounded,
                            color: scheme.onSurface.withValues(alpha: 0.45),
                          ),
                        )
                      : Icon(
                          Icons.storefront_rounded,
                          color: scheme.onSurface.withValues(alpha: 0.45),
                        ),
                ),
              ),
              SizedBox(width: AppSizes.spaceMd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomText(
                      profile.name.trim().isEmpty ? '—' : profile.name.trim(),
                      style: TextStyle(
                        fontSize: AppSizes.fontTitle,
                        fontWeight: FontWeight.w700,
                        color: scheme.onSurface,
                      ),
                    ),
                    SizedBox(height: AppSizes.spaceXs),
                    CustomText(
                      _phoneLine(),
                      style: TextStyle(
                        fontSize: AppSizes.fontLabel,
                        color: scheme.onSurface.withValues(alpha: 0.62),
                      ),
                    ),
                    SizedBox(height: AppSizes.spaceXs),
                    CustomText(
                      _subtitle(),
                      style: TextStyle(
                        fontSize: AppSizes.fontLabel,
                        fontWeight: FontWeight.w600,
                        color: AppColors.secondColor,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: scheme.onSurface.withValues(alpha: 0.45),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
