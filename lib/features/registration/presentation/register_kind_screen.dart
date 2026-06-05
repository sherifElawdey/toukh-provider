import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:toukh_provider/core/widgets/toukh_service_logo.dart';
import 'package:toukh_provider/core/router/app_routes.dart';
import 'package:toukh_provider/domain/entities/provider_kind.dart';
import 'package:toukh_provider/features/registration/cubit/registration_cubit.dart';
import 'package:toukh_provider/features/registration/presentation/widgets/register_kind_card.dart';
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
      return ToukhIcons.restaurant;
    case ServiceType.homeService:
      return PhosphorIconsRegular.wrench;
    case ServiceType.supermarket:
      return ToukhIcons.store;
    case ServiceType.grocery:
      return PhosphorIconsRegular.shoppingCart;
    case ServiceType.homeBrands:
      return PhosphorIconsRegular.seal;
    case ServiceType.pharmacy:
      return PhosphorIconsRegular.firstAid;
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
          icon: Icon(ToukhIcons.back),
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
                  return RegisterKindCard(
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

