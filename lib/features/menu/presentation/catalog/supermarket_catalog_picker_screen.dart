import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:toukh_provider/di/service_locator.dart';
import 'package:toukh_provider/domain/entities/menu_item.dart';
import 'package:toukh_provider/domain/repositories/cleaning_catalog_repository.dart';
import 'package:toukh_provider/domain/repositories/supermarket_catalog_repository.dart';
import 'package:toukh_provider/features/menu/presentation/catalog/catalog_menu_actions.dart';
import 'package:toukh_provider/features/menu/presentation/catalog/supermarket_item_sheet.dart';
import 'package:toukh_provider/features/menu/presentation/cubit/menu_builder_cubit.dart';
import 'package:toukh_provider/features/menu/presentation/cubit/menu_builder_state.dart';
import 'package:toukh_provider/l10n/app_strings.dart';
import 'package:toukh_ui/toukh_ui.dart';
import 'package:toukh_provider/core/utils/egp_label.dart';

/// Opens the supermarket catalog over the menu builder (shares its cubit).
/// [onAddCustom] closes the picker and adds a product the catalog lacks.
/// [aisles] limits the catalog to a shop's own aisles (meat & frozen);
/// null shows every aisle.
Future<void> openSupermarketCatalogPicker(
  BuildContext context, {
  VoidCallback? onAddCustom,
  Set<SupermarketAisle>? aisles,
}) {
  return _openPackagedCatalogPicker(
    context,
    catalogKind: MenuCatalogKinds.supermarket,
    titleKey: AppStrings.Catalog.supermarketTitle,
    searchHintKey: AppStrings.Catalog.supermarketSearch,
    onAddCustom: onAddCustom,
    watch: () => getIt<SupermarketCatalogRepository>().watchActive().map(
          (all) => [
            for (final p in all)
              if (aisles == null || aisles.contains(p.aisle)) p,
          ],
        ),
  );
}

/// Opens the cleaning products catalog over the menu builder (shares its
/// cubit). [onAddCustom] closes the picker and adds a product the catalog
/// lacks, with the shop's own photo.
Future<void> openCleaningCatalogPicker(
  BuildContext context, {
  VoidCallback? onAddCustom,
}) {
  return _openPackagedCatalogPicker(
    context,
    catalogKind: MenuCatalogKinds.cleaning,
    titleKey: AppStrings.Catalog.cleaningTitle,
    searchHintKey: AppStrings.Catalog.cleaningSearch,
    onAddCustom: onAddCustom,
    watch: () => getIt<CleaningCatalogRepository>().watchActive(),
  );
}

Future<void> _openPackagedCatalogPicker(
  BuildContext context, {
  required String catalogKind,
  required String titleKey,
  required String searchHintKey,
  required Stream<List<PackagedCatalogProduct>> Function() watch,
  VoidCallback? onAddCustom,
}) {
  final cubit = context.read<MenuBuilderCubit>();
  return Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => BlocProvider.value(
        value: cubit,
        child: PackagedCatalogPickerScreen(
          catalogKind: catalogKind,
          titleKey: titleKey,
          searchHintKey: searchHintKey,
          watch: watch,
          onAddCustom: onAddCustom,
        ),
      ),
    ),
  );
}

/// Shops pick packaged products (supermarket or cleaning catalog), then set
/// their own sale options, prices, terms and per-order limits.
class PackagedCatalogPickerScreen extends StatefulWidget {
  const PackagedCatalogPickerScreen({
    super.key,
    required this.catalogKind,
    required this.titleKey,
    required this.searchHintKey,
    required this.watch,
    this.onAddCustom,
  });

  /// [MenuCatalogKinds] of the products, to find the ones already on the menu.
  final String catalogKind;
  final String titleKey;
  final String searchHintKey;

  /// Active catalog products, sorted by section; called once.
  final Stream<List<PackagedCatalogProduct>> Function() watch;
  final VoidCallback? onAddCustom;

  @override
  State<PackagedCatalogPickerScreen> createState() => _PackagedCatalogPickerScreenState();
}

class _PackagedCatalogPickerScreenState extends State<PackagedCatalogPickerScreen> {
  final _search = TextEditingController();
  late final _catalog = widget.watch();

  /// [PackagedCatalogProduct.sectionIndex] of the selected filter chip.
  int? _section;
  bool _inMenuOnly = false;

  String get _lang => Get.locale?.languageCode ?? 'ar';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _open(PackagedCatalogProduct product, MenuItemEntity? existing) async {
    final cubit = context.read<MenuBuilderCubit>();
    final result = await showPackagedItemSheet(
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
    return Scaffold(
      appBar: AppBar(
        title: CustomText(widget.titleKey),
        leading: IconButton(icon: Icon(ToukhIcons.back), onPressed: () => Navigator.of(context).maybePop()),
      ),
      body: StreamBuilder<List<PackagedCatalogProduct>>(
        stream: _catalog,
        builder: (context, snap) {
          if (snap.hasError) return Center(child: CustomText(AppStrings.Common.error));
          if (!snap.hasData) return const Center(child: AppLoadingMark());
          final all = snap.data!;
          if (all.isEmpty) return _emptyCatalog();
          final sections = <int, String>{
            for (final p in [...all]..sort((a, b) => a.sectionIndex.compareTo(b.sectionIndex)))
              p.sectionIndex: p.sectionLabel(_lang),
          };

          return BlocBuilder<MenuBuilderCubit, MenuBuilderState>(
            builder: (context, menu) {
              final byCatalogId = {
                for (final item in menu.items)
                  if (item.isFromPackagedCatalog(widget.catalogKind)) item.catalogProductId!: item,
              };
              final shown = all
                  .where((p) => _section == null || p.sectionIndex == _section)
                  .where((p) => !_inMenuOnly || byCatalogId.containsKey(p.id))
                  .where((p) => p.matches(_search.text))
                  .toList();
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
                        hintText: widget.searchHintKey.tr,
                        prefixIcon: Icon(ToukhIcons.search),
                        isDense: true,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppSizes.radiusLg)),
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
                        _Chip(
                          label: '${AppStrings.Catalog.inMenu.tr} · ${byCatalogId.length}',
                          selected: _inMenuOnly,
                          onTap: () => setState(() => _inMenuOnly = !_inMenuOnly),
                        ),
                        _Chip(
                          label: AppStrings.Catalog.all.tr,
                          selected: _section == null,
                          onTap: () => setState(() => _section = null),
                        ),
                        for (final MapEntry(key: index, value: label) in sections.entries)
                          _Chip(
                            label: label,
                            selected: _section == index,
                            onTap: () => setState(() => _section = index),
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
                                childAspectRatio: 0.66,
                              ),
                              itemCount: shown.length,
                              itemBuilder: (context, i) {
                                final p = shown[i];
                                final existing = byCatalogId[p.id];
                                return _ProductTile(
                                  product: p,
                                  languageCode: _lang,
                                  inMenu: existing,
                                  onTap: () => _open(p, existing),
                                );
                              },
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

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsetsDirectional.only(end: AppSizes.spaceSm),
        child: ChoiceChip(label: Text(label), selected: selected, onSelected: (_) => onTap()),
      );
}

class _ProductTile extends StatelessWidget {
  const _ProductTile({
    required this.product,
    required this.languageCode,
    required this.inMenu,
    required this.onTap,
  });

  final PackagedCatalogProduct product;
  final String languageCode;
  final MenuItemEntity? inMenu;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    final item = inMenu;
    final listed = item != null;
    final minPrice = listed && item.sizes.isNotEmpty
        ? item.sizes.map((s) => s.priceEgp).reduce((a, b) => a < b ? a : b)
        : null;
    final subtitle = product.subtitle(languageCode);
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
                        ? Padding(
                            padding: const EdgeInsets.all(6),
                            child: HavitNetworkImage(imageUrl: product.imageUrl!, fit: BoxFit.contain),
                          )
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
                          backgroundColor: item.isAvailable ? AppColors.success : scheme.outline,
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
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: t.labelLarge?.copyWith(fontWeight: FontWeight.w800, height: 1.15),
                    ),
                    if (subtitle.isNotEmpty)
                      CustomText(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: t.labelSmall?.copyWith(color: scheme.onSurfaceVariant),
                      ),
                    if (minPrice != null)
                      CustomText(
                        [
                          egpLabel(minPrice.toStringAsFixed(minPrice == minPrice.roundToDouble() ? 0 : 2)),
                          if (item!.maxOrderQty != null)
                            AppStrings.Catalog.maxPerOrderShort.trParams({'count': '${item.maxOrderQty}'}),
                        ].join(' · '),
                        maxLines: 1,
                        style: t.labelSmall?.copyWith(color: AppColors.success, fontWeight: FontWeight.w700),
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
