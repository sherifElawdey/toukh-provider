import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:toukh_provider/core/widgets/toukh_service_logo.dart';
import 'package:toukh_provider/core/router/app_routes.dart';
import 'package:toukh_provider/domain/entities/provider_kind.dart';
import 'package:toukh_provider/features/registration/cubit/registration_cubit.dart';
import 'package:toukh_provider/l10n/app_strings.dart';
import 'package:toukh_ui/toukh_ui.dart';

/// Order tuned for registration UX (not enum declaration order).
const List<ServiceType> _kRegistrationKindOrder = [
  ServiceType.restaurant,
  ServiceType.supermarket,
  ServiceType.grocery,
  ServiceType.pharmacy,
  ServiceType.homeService,
  ServiceType.homeBrands,
];

String _kindLabelKey(ServiceType t) {
  switch (t) {
    case ServiceType.restaurant:
      return AppStrings.Registration.kindRestaurant;
    case ServiceType.homeService:
      return AppStrings.Registration.kindHomeService;
    case ServiceType.supermarket:
      return AppStrings.Registration.kindSupermarket;
    case ServiceType.grocery:
      return AppStrings.Registration.kindGrocery;
    case ServiceType.homeBrands:
      return AppStrings.Registration.kindHomeBrands;
    case ServiceType.pharmacy:
      return AppStrings.Registration.kindPharmacy;
  }
}

IconData _kindIcon(ServiceType t) {
  switch (t) {
    case ServiceType.restaurant:
      return Icons.restaurant_outlined;
    case ServiceType.homeService:
      return Icons.home_repair_service_outlined;
    case ServiceType.supermarket:
      return Icons.storefront_outlined;
    case ServiceType.grocery:
      return Icons.local_grocery_store_outlined;
    case ServiceType.homeBrands:
      return Icons.branding_watermark_outlined;
    case ServiceType.pharmacy:
      return Icons.local_pharmacy_outlined;
  }
}

class RegisterKindScreen extends StatelessWidget {
  const RegisterKindScreen({super.key});

  void _onSelectKind(BuildContext context, ServiceType kind) {
    final cubit = context.read<RegistrationCubit>();
    cubit.selectKindForRegistration(kind);
    if (kind == ServiceType.homeService || kind == ServiceType.restaurant) {
      context.push(AppRoutes.registerCategory);
    } else {
      context.push(AppRoutes.registerCredentials);
    }
  }

  @override
  Widget build(BuildContext context) {
    final draft = context.watch<RegistrationCubit>().state;
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
        title: CustomText(AppStrings.Registration.kindTitle),
      ),
      body: Padding(
        padding: AppSizes.screenPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: ToukhServiceLogo(
                size: 56,
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            SizedBox(height: AppSizes.spaceMd),
            CustomText(
              AppStrings.Registration.kindSubtitle.tr,
              style: TextStyle(
                fontSize: AppSizes.fontBody,
                color: scheme.onSurface.withValues(alpha: 0.72),
              ),
            ),
            SizedBox(height: AppSizes.spaceXl),
            Expanded(
              child: ListView.separated(
                itemCount: _kRegistrationKindOrder.length,
                separatorBuilder: (_, _) => SizedBox(height: AppSizes.spaceMd),
                itemBuilder: (context, index) {
                  final kind = _kRegistrationKindOrder[index];
                  return _KindCard(
                    selected: draft.kind == kind,
                    title: _kindLabelKey(kind).tr,
                    icon: _kindIcon(kind),
                    onTap: () => _onSelectKind(context, kind),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _KindCard extends StatelessWidget {
  const _KindCard({
    required this.selected,
    required this.title,
    required this.icon,
    required this.onTap,
  });

  final bool selected;
  final String title;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: selected
          ? AppColors.thirdColor.withValues(alpha: 0.35)
          : scheme.surfaceContainerHighest.withValues(alpha: 0.45),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        side: BorderSide(
          color: selected ? AppColors.secondColor : Colors.transparent,
          width: 2,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.spaceBase),
          child: Row(
            children: [
              Icon(icon, size: 40, color: AppColors.secondColor),
              SizedBox(width: AppSizes.spaceMd),
              Expanded(
                child: CustomText(
                  title,
                  style: const TextStyle(
                    fontSize: AppSizes.fontTitle,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const Icon(Icons.chevron_right_rounded),
            ],
          ),
        ),
      ),
    );
  }
}
