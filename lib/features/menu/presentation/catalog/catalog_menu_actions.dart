import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:toukh_provider/di/service_locator.dart';
import 'package:toukh_provider/domain/entities/menu_item.dart';
import 'package:toukh_provider/domain/repositories/grocery_catalog_repository.dart';
import 'package:toukh_provider/domain/repositories/supermarket_catalog_repository.dart';
import 'package:toukh_provider/features/menu/presentation/catalog/catalog_item_sheet.dart';
import 'package:toukh_provider/features/menu/presentation/catalog/supermarket_item_sheet.dart';
import 'package:toukh_provider/features/menu/presentation/cubit/menu_builder_cubit.dart';
import 'package:toukh_provider/features/menu/presentation/models/menu_item_editor_result.dart';
import 'package:toukh_provider/l10n/app_strings.dart';
import 'package:toukh_ui/toukh_ui.dart';

/// Saves or removes what the store chose in a catalog item sheet, then shows
/// the outcome. [existing] is the menu item the sheet was opened for.
Future<void> applyCatalogItemResult(
  BuildContext context, {
  required CatalogItemSheetResult result,
  required MenuItemEntity? existing,
  required String productName,
}) async {
  final cubit = context.read<MenuBuilderCubit>();
  final error = await context.withAppLoading(() async {
    switch (result) {
      case CatalogItemRemoved():
        return cubit.removeItem(existing!.id);
      case CatalogItemSaved(:final item):
        // Items live under their section; moving one drops the old copy.
        if (existing != null && existing.category != item.category) {
          final err = await cubit.removeItem(existing.id);
          if (err != null) return err;
        }
        return cubit.commitItemEditorResult(MenuItemEditorResult(entity: item));
    }
  });
  if (!context.mounted) return;
  AppSnack.show(
    context,
    message: error ??
        (result is CatalogItemRemoved
                ? AppStrings.Catalog.removed
                : AppStrings.Catalog.added)
            .trParams({'name': productName}),
    state: error == null ? AppSnackState.success : AppSnackState.error,
    icon: error == null ? ToukhIcons.check : ToukhIcons.error,
  );
}

/// Opens the price / availability / sizes sheet for a menu item that came
/// from a master catalog, straight from the menu.
Future<void> editCatalogMenuItem(BuildContext context, MenuItemEntity item) async {
  final cubit = context.read<MenuBuilderCubit>();
  final id = item.catalogProductId!;
  final supermarket = item.isFromSupermarketCatalog;
  final Object? product;
  try {
    product = await context.withAppLoading(
      () => supermarket
          ? getIt<SupermarketCatalogRepository>().getById(id)
          : getIt<GroceryCatalogRepository>().getById(id),
    );
  } catch (e) {
    if (!context.mounted) return;
    AppSnack.show(
      context,
      message: AppStrings.Common.error.tr,
      state: AppSnackState.error,
      icon: ToukhIcons.error,
    );
    return;
  }
  if (!context.mounted) return;

  final lang = Get.locale?.languageCode ?? 'ar';
  final CatalogItemSheetResult? result;
  final String name;
  switch (product) {
    case SupermarketCatalogProduct p:
      name = p.localizedName(lang);
      result = await showSupermarketItemSheet(
        context,
        product: p,
        menuCategories: cubit.state.categories,
        existing: item,
      );
    case GroceryCatalogProduct p:
      name = p.localizedName(lang);
      result = await showCatalogItemSheet(
        context,
        product: p,
        menuCategories: cubit.state.categories,
        existing: item,
      );
    default:
      AppSnack.show(
        context,
        message: AppStrings.Catalog.productGone.tr,
        state: AppSnackState.warning,
        icon: ToukhIcons.info,
      );
      return;
  }
  if (result == null || !context.mounted) return;
  await applyCatalogItemResult(
    context,
    result: result,
    existing: item,
    productName: name,
  );
}

/// "Add an item not in the catalog" link shown inside the catalog pickers.
class CatalogAddCustomItemButton extends StatelessWidget {
  const CatalogAddCustomItemButton({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: AppTextButton(
        text: AppStrings.Catalog.addCustomItem,
        icon: ToukhIcons.add,
        size: AppButtonSize.small,
        onTap: onTap,
      ),
    );
  }
}
