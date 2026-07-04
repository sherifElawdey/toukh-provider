import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:toukh_provider/core/router/app_routes.dart';
import 'package:toukh_provider/di/service_locator.dart';
import 'package:toukh_provider/domain/entities/home_service_category.dart';
import 'package:toukh_provider/domain/repositories/home_service_categories_repository.dart';
import 'package:toukh_provider/features/registration/cubit/registration_cubit.dart';
import 'package:toukh_provider/features/registration/presentation/widgets/home_service_category_card.dart';
import 'package:toukh_provider/l10n/app_strings.dart';
import 'package:toukh_ui/toukh_ui.dart';

class HomeServicesCategoryBody extends StatelessWidget {
  const HomeServicesCategoryBody({
    super.key,
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
              return HomeServiceCategoryCard(
                category: s,
                selected: selected,
                scheme: scheme,
                onTap: () {
                  cubit.setServiceCategoryId(s.id,s.title);
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
