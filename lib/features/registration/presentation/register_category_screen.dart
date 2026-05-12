import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:toukh_provider/core/widgets/toukh_service_logo.dart';
import 'package:toukh_provider/core/router/app_routes.dart';
import 'package:toukh_provider/di/service_locator.dart';
import 'package:toukh_provider/domain/entities/home_service_category.dart';
import 'package:toukh_provider/domain/entities/provider_kind.dart';
import 'package:toukh_provider/domain/entities/shop_category.dart';
import 'package:toukh_provider/domain/repositories/home_service_categories_repository.dart';
import 'package:toukh_provider/features/registration/cubit/registration_cubit.dart';
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
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
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
                          ? const Icon(Icons.check_circle_rounded,
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
          : _HomeServicesCategoryBody(
              draft: draft,
              cubit: cubit,
              scheme: scheme,
            ),
    );
  }
}

class _HomeServicesCategoryBody extends StatelessWidget {
  const _HomeServicesCategoryBody({
    required this.draft,
    required this.cubit,
    required this.scheme,
  });

  final RegistrationDraft draft;
  final RegistrationCubit cubit;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<HomeServiceCategory>>(
      stream: getIt<HomeServiceCategoriesRepository>().watchActiveCategories(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Padding(
            padding: AppSizes.screenPadding,
            child: Center(
              child: CustomText(
                AppStrings.Registration.homeCategoriesLoadError.tr,
                textAlign: TextAlign.center,
              ),
            ),
          );
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final categories = snapshot.data!;
        if (categories.isEmpty) {
          return Padding(
            padding: AppSizes.screenPadding,
            child: Center(
              child: CustomText(
                AppStrings.Registration.homeCategoriesEmpty.tr,
                textAlign: TextAlign.center,
              ),
            ),
          );
        }
        return ListView(
          padding: AppSizes.screenPadding,
          children: [
            Center(
              child: ToukhServiceLogo(
                size: 56,
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            SizedBox(height: AppSizes.spaceMd),
            for (final s in categories)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSizes.spaceSm),
                child: ListTile(
                  leading: s.imageUrl != null && s.imageUrl!.isNotEmpty
                      ? ClipRRect(
                          borderRadius:
                              BorderRadius.circular(AppSizes.radiusSm),
                          child: Image.network(
                            s.imageUrl!,
                            width: 48,
                            height: 48,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => Icon(
                              Icons.home_repair_service_outlined,
                              color: AppColors.secondColor,
                            ),
                          ),
                        )
                      : Icon(
                          Icons.home_repair_service_outlined,
                          color: AppColors.secondColor,
                        ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                  ),
                  tileColor: draft.serviceCategoryId == s.id
                      ? AppColors.thirdColor.withValues(alpha: 0.35)
                      : scheme.surfaceContainerHighest.withValues(alpha: 0.35),
                  title: CustomText(s.title),
                  subtitle: s.description.isEmpty
                      ? null
                      : CustomText(
                          s.description,
                          style: TextStyle(
                            fontSize: AppSizes.fontLabel,
                            color: scheme.onSurface.withValues(alpha: 0.65),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                  trailing: draft.serviceCategoryId == s.id
                      ? const Icon(Icons.check_circle_rounded,
                          color: AppColors.success)
                      : null,
                  onTap: () {
                    cubit.setServiceCategoryId(s.id);
                    context.push(AppRoutes.registerCredentials);
                  },
                ),
              ),
          ],
        );
      },
    );
  }
}
