import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:toukh_provider/core/router/app_routes.dart';
import 'package:toukh_provider/domain/entities/provider_kind.dart';
import 'package:toukh_provider/features/registration/cubit/registration_cubit.dart';
import 'package:toukh_provider/features/registration/presentation/widgets/register_kind_card.dart';
import 'package:toukh_provider/features/registration/presentation/widgets/registration_step_layout.dart';
import 'package:toukh_provider/features/shell/provider_web_layout.dart';
import 'package:toukh_provider/l10n/app_strings.dart';
import 'package:toukh_ui/toukh_ui.dart';

/// Order tuned for registration UX (not enum declaration order).
const List<ServiceType> _kRegistrationKindOrder = [
  ServiceType.restaurant,
  ServiceType.supermarket,
  ServiceType.grocery,
  ServiceType.pharmacy,
  ServiceType.otherShops,
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
    case ServiceType.otherShops:
      return AppStrings.Registration.kindOtherShops;
  }
}

IconData _kindIcon(ServiceType t) {
  switch (t) {
    case ServiceType.restaurant:
      return PhosphorIconsDuotone.forkKnife;
    case ServiceType.homeService:
      return PhosphorIconsDuotone.wrench;
    case ServiceType.supermarket:
      return PhosphorIconsDuotone.shoppingCart;
    case ServiceType.grocery:
      return PhosphorIconsDuotone.basket;
    case ServiceType.homeBrands:
      return PhosphorIconsDuotone.couch;
    case ServiceType.pharmacy:
      return PhosphorIconsDuotone.pill;
    case ServiceType.otherShops:
      return PhosphorIconsDuotone.storefront;
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
    return RegistrationStepScaffold(
      stage: RegistrationStage.business,
      icon: PhosphorIconsDuotone.storefront,
      title: AppStrings.Registration.kindTitle,
      subtitle: AppStrings.Registration.kindSubtitle,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final wide = ProviderWebLayout.isWide(context);
            final columns = !wide
                ? 2
                : constraints.maxWidth >= 560
                ? 3
                : 2;
            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: columns,
                mainAxisSpacing: AppSizes.spaceMd,
                crossAxisSpacing: AppSizes.spaceMd,
                mainAxisExtent: 150,
              ),
              itemCount: _kRegistrationKindOrder.length,
              itemBuilder: (context, index) {
                final kind = _kRegistrationKindOrder[index];
                return RegisterKindCard(
                  selected: draft.kind == kind,
                  title: _kindLabelKey(kind),
                  icon: _kindIcon(kind),
                  onTap: () => _onSelectKind(context, kind),
                );
              },
            );
          },
        ),
        SizedBox(height: AppSizes.spaceLg),
        const _DeliveryCompanyCta(),
      ],
    );
  }
}

/// Entry to the delivery company sign-up, kept apart from the shop kinds.
class _DeliveryCompanyCta extends StatelessWidget {
  const _DeliveryCompanyCta();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: AppColors.secondColor.withValues(alpha: 0.08),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        side: BorderSide(color: AppColors.secondColor.withValues(alpha: 0.35)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        onTap: () => context.push(AppRoutes.registerCompany),
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.spaceMd),
          child: Row(
            children: [
              const RegistrationIllustration(
                icon: PhosphorIconsDuotone.truck,
                size: 52,
              ),
              SizedBox(width: AppSizes.spaceMd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomText(
                      AppStrings.Company.registerCtaTitle,
                      style: const TextStyle(
                        fontSize: AppSizes.fontBody,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: AppSizes.spaceXs),
                    CustomText(
                      AppStrings.Company.registerCtaSubtitle,
                      style: TextStyle(
                        fontSize: AppSizes.fontCaption,
                        color: scheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Directionality.of(context) == TextDirection.rtl
                    ? ToukhIcons.back
                    : ToukhIcons.forward,
                color: AppColors.secondColor,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
