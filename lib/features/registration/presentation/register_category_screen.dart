import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:toukh_provider/core/widgets/toukh_service_logo.dart';
import 'package:toukh_provider/core/router/app_routes.dart';
import 'package:toukh_provider/domain/entities/provider_kind.dart';
import 'package:toukh_provider/domain/entities/shop_category.dart';
import 'package:toukh_provider/features/registration/cubit/registration_cubit.dart';
import 'package:toukh_provider/features/registration/presentation/widgets/home_services_category_body.dart';
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

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(ToukhIcons.back),
          onPressed: () => context.pop(),
        ),
        title: CustomText(
          kind == ServiceType.restaurant
              ? AppStrings.Registration.shopCategoryTitle
              : AppStrings.Registration.serviceCategoryTitle,
        ),
      ),
      body: kind == ServiceType.restaurant
          ? ListView(
              padding: AppSizes.screenPadding,
              children: [
                Center(
                  child: ToukhServiceLogo(
                    size: 56,
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                SizedBox(height: AppSizes.spaceMd),
                for (final c in ShopCategory.values)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSizes.spaceSm),
                    child: ListTile(
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(AppSizes.radiusMd),
                      ),
                      tileColor: draft.shopCategory == c
                          ? AppColors.thirdColor.withValues(alpha: 0.35)
                          : scheme.surfaceContainerHighest
                              .withValues(alpha: 0.35),
                      title: CustomText(_shopLabel(c)),
                      trailing: draft.shopCategory == c
                          ? const Icon(PhosphorIconsFill.checkCircle,
                              color: AppColors.success)
                          : null,
                      onTap: () {
                        cubit.setShopCategory(c);
                        context.push(AppRoutes.registerCredentials);
                      },
                    ),
                  ),
              ],
            )
          : HomeServicesCategoryBody(
              draft: draft,
              cubit: cubit,
              scheme: scheme,
            ),
    );
  }
}

