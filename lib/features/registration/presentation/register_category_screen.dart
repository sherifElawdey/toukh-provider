import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:toukh_provider/core/router/app_routes.dart';
import 'package:toukh_provider/domain/entities/provider_kind.dart';
import 'package:toukh_provider/domain/entities/shop_category.dart';
import 'package:toukh_provider/features/registration/cubit/registration_cubit.dart';
import 'package:toukh_provider/features/registration/presentation/widgets/home_services_category_body.dart';
import 'package:toukh_provider/features/registration/presentation/widgets/registration_step_layout.dart';
import 'package:toukh_provider/l10n/app_strings.dart';
import 'package:toukh_ui/toukh_ui.dart';

class RegisterCategoryScreen extends StatelessWidget {
  const RegisterCategoryScreen({super.key});

  String _shopLabel(ShopCategory c) {
    switch (c) {
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

  IconData _shopIcon(ShopCategory c) {
    switch (c) {
      case ShopCategory.pharmacy:
        return PhosphorIconsDuotone.pill;
      case ShopCategory.supermarket:
        return PhosphorIconsDuotone.shoppingCart;
      case ShopCategory.fruitVeg:
        return PhosphorIconsDuotone.carrot;
      case ShopCategory.restaurant:
        return PhosphorIconsDuotone.hamburger;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.watch<RegistrationCubit>();
    final draft = cubit.state;
    final kind = draft.kind;
    final scheme = Theme.of(context).colorScheme;

    if (kind != ServiceType.restaurant && kind != ServiceType.homeService) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) context.pop();
      });
      return const Scaffold(body: SizedBox.shrink());
    }

    final restaurant = kind == ServiceType.restaurant;
    return RegistrationStepScaffold(
      stage: RegistrationStage.business,
      icon: restaurant
          ? PhosphorIconsDuotone.forkKnife
          : PhosphorIconsDuotone.wrench,
      title: restaurant
          ? AppStrings.Registration.shopCategoryTitle
          : AppStrings.Registration.serviceCategoryTitle,
      subtitle: restaurant
          ? AppStrings.Registration.shopCategorySubtitle
          : AppStrings.Registration.serviceCategorySubtitle,
      children: [
        if (restaurant)
          for (final c in ShopCategory.values)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSizes.spaceSm),
              child: _ShopCategoryTile(
                label: _shopLabel(c),
                icon: _shopIcon(c),
                selected: draft.shopCategory == c,
                onTap: () {
                  cubit.setShopCategory(c);
                  context.push(AppRoutes.registerCredentials);
                },
              ),
            )
        else
          HomeServicesCategoryBody(
            draft: draft,
            cubit: cubit,
            scheme: scheme,
            embedded: true,
          ),
      ],
    );
  }
}

class _ShopCategoryTile extends StatelessWidget {
  const _ShopCategoryTile({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: selected
          ? AppColors.tint(context, AppColors.secondColor)
          : scheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        side: BorderSide(
          color: selected ? AppColors.secondColor : AppColors.borderSubtle,
          width: selected ? 2 : 1.2,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.spaceMd),
          child: Row(
            children: [
              RegistrationIllustration(icon: icon, size: 52),
              SizedBox(width: AppSizes.spaceMd),
              Expanded(
                child: CustomText(
                  label,
                  style: const TextStyle(
                    fontSize: AppSizes.fontBody,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (selected)
                const Icon(
                  PhosphorIconsFill.checkCircle,
                  color: AppColors.success,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
