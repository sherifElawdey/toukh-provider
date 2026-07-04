import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:toukh_provider/di/service_locator.dart';
import 'package:toukh_provider/domain/entities/home_service_category.dart';
import 'package:toukh_provider/domain/entities/provider_kind.dart';
import 'package:toukh_provider/domain/entities/shop_category.dart';
import 'package:toukh_provider/domain/repositories/home_service_categories_repository.dart';
import 'package:toukh_provider/features/registration/cubit/registration_cubit.dart';
import 'package:toukh_provider/features/registration/presentation/widgets/home_service_category_card.dart';
import 'package:toukh_provider/l10n/app_strings.dart';
import 'package:toukh_ui/toukh_ui.dart';

class ReviewEditCategoryBody extends StatefulWidget {
  const ReviewEditCategoryBody({super.key});

  @override
  State<ReviewEditCategoryBody> createState() => ReviewEditCategoryBodyState();
}

class ReviewEditCategoryBodyState extends State<ReviewEditCategoryBody> {
  ShopCategory? _shopCategory;
  String? _serviceCategoryId;
  String? _serviceCategoryTitle;

  @override
  void initState() {
    super.initState();
    final d = context.read<RegistrationCubit>().state;
    _shopCategory = d.shopCategory;
    _serviceCategoryId = d.serviceCategoryId;
    _serviceCategoryTitle = d.serviceCategoryTitle;
  }

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

  bool save() {
    final cubit = context.read<RegistrationCubit>();
    final kind = cubit.state.kind;
    if (kind == ServiceType.restaurant) {
      if (_shopCategory == null) return false;
      cubit.setShopCategory(_shopCategory!);
      return true;
    }
    if (kind == ServiceType.homeService) {
      final id = _serviceCategoryId;
      if (id == null || id.isEmpty || _serviceCategoryTitle == null || _serviceCategoryTitle!.isEmpty) return false;
      cubit.setServiceCategoryId(id,_serviceCategoryTitle  ?? id);
      return true;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final kind = context.watch<RegistrationCubit>().state.kind;
    final scheme = Theme.of(context).colorScheme;

    if (kind == ServiceType.restaurant) {
      return Column(
        children: [
          for (final c in ShopCategory.values)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSizes.spaceSm),
              child: ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                ),
                tileColor: _shopCategory == c
                    ? AppColors.thirdColor.withValues(alpha: 0.35)
                    : scheme.surfaceContainerHighest.withValues(alpha: 0.35),
                title: CustomText(_shopLabel(c)),
                trailing: _shopCategory == c
                    ? const Icon(PhosphorIconsFill.checkCircle,
                        color: AppColors.success)
                    : null,
                onTap: () => setState(() => _shopCategory = c),
              ),
            ),
        ],
      );
    }

    if (kind == ServiceType.homeService) {
      return StreamBuilder<List<HomeServiceCategory>>(
        stream: getIt<HomeServiceCategoriesRepository>().watchActiveCategories(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return CustomText(
              AppStrings.Registration.homeCategoriesLoadError.tr,
              textAlign: TextAlign.center,
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final categories = snapshot.data!;
          if (categories.isEmpty) {
            return CustomText(
              AppStrings.Registration.homeCategoriesEmpty.tr,
              textAlign: TextAlign.center,
            );
          }
          return GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: AppSizes.spaceMd,
              crossAxisSpacing: AppSizes.spaceMd,
              childAspectRatio: 0.78,
            ),
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final s = categories[index];
              final selected = _serviceCategoryId == s.id;
              return HomeServiceCategoryCard(
                category: s,
                selected: selected,
                scheme: scheme,
                onTap: () => setState((){
                  _serviceCategoryId = s.id;
                  _serviceCategoryTitle = s.title;
                }),
              );
            },
          );
        },
      );
    }

    return CustomText(
      '—',
      style: TextStyle(color: scheme.onSurface.withValues(alpha: 0.6)),
    );
  }
}
