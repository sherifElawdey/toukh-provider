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
        return Padding(
          padding: AppSizes.screenPadding,
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: AppSizes.spaceMd,
              crossAxisSpacing: AppSizes.spaceMd,
              childAspectRatio: 0.78,
            ),
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final s = categories[index];
              final selected = draft.serviceCategoryId == s.id;
              return _HomeServiceCategoryCard(
                category: s,
                selected: selected,
                scheme: scheme,
                onTap: () {
                  cubit.setServiceCategoryId(s.id);
                  context.push(AppRoutes.registerCredentials);
                },
              );
            },
          ),
        );
      },
    );
  }
}

class _HomeServiceCategoryCard extends StatelessWidget {
  const _HomeServiceCategoryCard({
    required this.category,
    required this.selected,
    required this.scheme,
    required this.onTap,
  });

  final HomeServiceCategory category;
  final bool selected;
  final ColorScheme scheme;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final desc = category.description;
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
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.spaceSm),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    ClipRRect(
                      borderRadius:
                          BorderRadius.circular(AppSizes.radiusMd),
                      child: ColoredBox(
                        color: scheme.surfaceContainerHigh
                            .withValues(alpha: 0.5),
                        child: category.imageUrl != null &&
                                category.imageUrl!.isNotEmpty
                            ? Image.network(
                                category.imageUrl!,
                                fit: BoxFit.cover,
                                filterQuality: FilterQuality.medium,
                                errorBuilder: (_, _, _) => Center(
                                  child: Icon(
                                    Icons.home_repair_service_outlined,
                                    size: 40,
                                    color: AppColors.secondColor,
                                  ),
                                ),
                              )
                            : Center(
                                child: Icon(
                                  Icons.home_repair_service_outlined,
                                  size: 40,
                                  color: AppColors.secondColor,
                                ),
                              ),
                      ),
                    ),
                    if (selected)
                      Positioned(
                        top: AppSizes.spaceXs,
                        right: AppSizes.spaceXs,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: scheme.surface.withValues(alpha: 0.92),
                            shape: BoxShape.circle,
                          ),
                          child: const Padding(
                            padding: EdgeInsets.all(2),
                            child: Icon(
                              Icons.check_circle_rounded,
                              color: AppColors.success,
                              size: 22,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              SizedBox(height: AppSizes.spaceSm),
              CustomText(
                category.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: AppSizes.fontBody,
                  fontWeight: FontWeight.w700,
                  height: 1.2,
                ),
              ),
              if (desc.isNotEmpty) ...[
                SizedBox(height: AppSizes.spaceXs),
                CustomText(
                  desc,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: AppSizes.fontCaption,
                    height: 1.25,
                    color: scheme.onSurface.withValues(alpha: 0.65),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
