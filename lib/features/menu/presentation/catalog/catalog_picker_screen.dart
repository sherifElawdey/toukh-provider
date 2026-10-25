import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:toukh_provider/di/service_locator.dart';
import 'package:toukh_provider/domain/entities/menu_item.dart';
import 'package:toukh_provider/domain/repositories/grocery_catalog_repository.dart';
import 'package:toukh_provider/features/menu/presentation/catalog/catalog_item_sheet.dart';
import 'package:toukh_provider/features/menu/presentation/catalog/catalog_menu_actions.dart';
import 'package:toukh_provider/features/menu/presentation/cubit/menu_builder_cubit.dart';
import 'package:toukh_provider/features/menu/presentation/cubit/menu_builder_state.dart';
import 'package:toukh_provider/l10n/app_strings.dart';
import 'package:toukh_ui/toukh_ui.dart';
import 'package:toukh_provider/core/utils/egp_label.dart';

/// Opens the master catalog over the menu builder (shares its cubit).
/// [onAddCustom] closes the picker and adds a product the catalog lacks.
Future<void> openCatalogPicker(BuildContext context, {VoidCallback? onAddCustom}) {
  final cubit = context.read<MenuBuilderCubit>();
  return Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => BlocProvider.value(
        value: cubit,
        child: CatalogPickerScreen(onAddCustom: onAddCustom),
      ),
    ),
  );
}

/// Fruit & vegetable shops and supermarkets pick products from the admin
/// catalog, then set their own sizes and prices for each.
class CatalogPickerScreen extends StatefulWidget {
  const CatalogPickerScreen({super.key, this.onAddCustom});

  final VoidCallback? onAddCustom;

  @override
  State<CatalogPickerScreen> createState() => _CatalogPickerScreenState();
}

class _CatalogPickerScreenState extends State<CatalogPickerScreen> {
  final _search = TextEditingController();
  late final _catalog = getIt<GroceryCatalogRepository>().watchActive();
  GroceryCatalogCategory? _category;

  String get _lang => Get.locale?.languageCode ?? 'ar';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _open(GroceryCatalogProduct product, MenuItemEntity? existing) async {
    final cubit = context.read<MenuBuilderCubit>();
    final result = await showCatalogItemSheet(
      context,
      product: product,
      menuCategories: cubit.state.categories,
      existing: existing,
    );
    if (result == null || !mounted) return;
    await applyCatalogItemResult(
      context,
      result: result,
      existing: existing,
      productName: product.localizedName(_lang),
    );
  }

  void _addCustom() {
    final onAddCustom = widget.onAddCustom;
    if (onAddCustom == null) return;
    Navigator.of(context).pop();
    onAddCustom();
  }

  Widget _emptyCatalog() => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CustomText(AppStrings.Catalog.empty),
            if (widget.onAddCustom != null) ...[
              const SizedBox(height: AppSizes.spaceSm),
              AppTextButton(
                text: AppStrings.Catalog.addCustomItem,
                icon: ToukhIcons.add,
                size: AppButtonSize.small,
                onTap: _addCustom,
              ),
            ],
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: CustomText(AppStrings.Catalog.title),
        leading: IconButton(
          icon: Icon(ToukhIcons.back),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: StreamBuilder<List<GroceryCatalogProduct>>(
        stream: _catalog,
        builder: (context, snap) {
          if (snap.hasError) {
            return Center(child: CustomText(AppStrings.Common.error));
          }
          if (!snap.hasData) return const Center(child: AppLoadingMark());
          final all = snap.data!;
          if (all.isEmpty) return _emptyCatalog();
          final categories = GroceryCatalogCategory.values
              .where((c) => all.any((p) => p.category == c))
              .toList();
          final shown = all
              .where((p) => _category == null || p.category == _category)
              .where((p) => p.matches(_search.text))
              .toList();

          return BlocBuilder<MenuBuilderCubit, MenuBuilderState>(
            builder: (context, menu) {
              final byCatalogId = {
                for (final item in menu.items)
                  if (item.isFromProduceCatalog) item.catalogProductId!: item,
              };
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: AppSizes.screenPadding.copyWith(bottom: AppSizes.spaceSm),
                    child: TextField(
                      controller: _search,
                      onChanged: (_) => setState(() {}),
                      textInputAction: TextInputAction.search,
                      decoration: InputDecoration(
                        hintText: AppStrings.Catalog.search.tr,
                        prefixIcon: Icon(ToukhIcons.search),
                        isDense: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                        ),
                      ),
                    ),
                  ),
                  if (widget.onAddCustom != null)
                    Padding(
                      padding: AppSizes.screenHorizontal,
                      child: CatalogAddCustomItemButton(onTap: _addCustom),
                    ),
                  SizedBox(
                    height: 44,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: AppSizes.screenHorizontal,
                      children: [
                        _CategoryChip(
                          label: AppStrings.Catalog.all.tr,
                          selected: _category == null,
                          onTap: () => setState(() => _category = null),
                        ),
                        for (final c in categories)
                          _CategoryChip(
                            label: c.label(_lang),
                            selected: _category == c,
                            onTap: () => setState(() => _category = c),
                          ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: shown.isEmpty
                        ? Center(child: CustomText(AppStrings.Catalog.noMatch))
                        : LayoutBuilder(
                            builder: (context, constraints) => GridView.builder(
                              padding: AppSizes.screenPadding,
                              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: constraints.maxWidth >= 600 ? 4 : 3,
                                mainAxisSpacing: AppSizes.spaceMd,
                                crossAxisSpacing: AppSizes.spaceMd,
                                childAspectRatio: 0.78,
                              ),
                              itemCount: shown.length,
                              itemBuilder: (context, i) {
                                final p = shown[i];
                                final existing = byCatalogId[p.id];
                                return _CatalogTile(
                                  product: p,
                                  languageCode: _lang,
                                  inMenu: existing,
                                  onTap: () => _open(p, existing),
                                );
                              },
                            ),
                          ),
                  ),
                  if (byCatalogId.isNotEmpty)
                    SafeArea(
                      top: false,
                      child: Container(
                        padding: AppSizes.screenPadding.copyWith(
                          top: AppSizes.spaceSm,
                          bottom: AppSizes.spaceSm,
                        ),
                        color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
                        child: CustomText(
                          '${AppStrings.Catalog.inMenu.tr}: ${byCatalogId.length}',
                          textAlign: TextAlign.center,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(end: AppSizes.spaceSm),
      child: ChoiceChip(label: Text(label), selected: selected, onSelected: (_) => onTap()),
    );
  }
}

class _CatalogTile extends StatelessWidget {
  const _CatalogTile({
    required this.product,
    required this.languageCode,
    required this.inMenu,
    required this.onTap,
  });

  final GroceryCatalogProduct product;
  final String languageCode;
  final MenuItemEntity? inMenu;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    final listed = inMenu != null;
    final minPrice = listed && inMenu!.sizes.isNotEmpty
        ? inMenu!.sizes.map((s) => s.priceEgp).reduce((a, b) => a < b ? a : b)
        : null;
    return Material(
      color: scheme.surface,
      borderRadius: BorderRadius.circular(AppSizes.radiusLg),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSizes.radiusLg),
            border: Border.all(
              color: listed ? AppColors.success : AppColors.borderSubtle,
              width: listed ? 2 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    product.hasImage
                        ? HavitNetworkImage(imageUrl: product.imageUrl!, fit: BoxFit.cover)
                        : ColoredBox(
                            color: scheme.surfaceContainerHighest,
                            child: Icon(ToukhIcons.store, color: scheme.onSurfaceVariant),
                          ),
                    if (listed)
                      PositionedDirectional(
                        top: 6,
                        end: 6,
                        child: CircleAvatar(
                          radius: 12,
                          backgroundColor: AppColors.success,
                          child: Icon(ToukhIcons.check, size: 14, color: Colors.white),
                        ),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomText(
                      product.localizedName(languageCode),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: t.labelLarge?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    CustomText(
                      minPrice != null
                          ? egpLabel(minPrice.toStringAsFixed(minPrice == minPrice.roundToDouble() ? 0 : 2))
                          : product.category.label(languageCode),
                      maxLines: 1,
                      style: t.labelSmall?.copyWith(
                        color: listed ? AppColors.success : scheme.onSurfaceVariant,
                        fontWeight: listed ? FontWeight.w700 : null,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
