import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
    if (kind == ServiceType.homeService) {
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
        titleSpacing: AppSizes.spaceSm,
        title: Row(
          children: [
            ToukhServiceLogo(
              size: 36,
              borderRadius: BorderRadius.circular(10),
            ),
            SizedBox(width: AppSizes.spaceSm),
            Expanded(
              child: CustomText(
                AppStrings.Registration.kindTitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: AppSizes.fontTitle,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
      body: Padding(
        padding: AppSizes.screenPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            CustomText(
              AppStrings.Registration.kindSubtitle,
              style: TextStyle(
                fontSize: AppSizes.fontBody,
                color: scheme.onSurface.withValues(alpha: 0.72),
              ),
            ),
            SizedBox(height: AppSizes.spaceLg),
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: AppSizes.spaceMd,
                  crossAxisSpacing: AppSizes.spaceMd,
                  childAspectRatio: 0.95,
                ),
                itemCount: _kRegistrationKindOrder.length,
                itemBuilder: (context, index) {
                  final kind = _kRegistrationKindOrder[index];
                  return _KindCard(
                    selected: draft.kind == kind,
                    title: _kindLabelKey(kind),
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
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.spaceSm,
            vertical: AppSizes.spaceMd,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 36, color: AppColors.secondColor),
              SizedBox(height: AppSizes.spaceSm),
              CustomText(
                title,
                textAlign: TextAlign.center,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: AppSizes.fontBody,
                  fontWeight: FontWeight.w700,
                  height: 1.25,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
