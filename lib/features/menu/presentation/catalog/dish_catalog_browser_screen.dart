import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:toukh_provider/di/service_locator.dart';
import 'package:toukh_provider/domain/repositories/dish_catalog_repository.dart';
import 'package:toukh_provider/l10n/app_strings.dart';
import 'package:toukh_ui/toukh_ui.dart';

/// Opens the dishes library and resolves to the dish the restaurant picked.
/// [inMenu] holds library ids already on the menu (marked, still pickable).
Future<DishCatalogProduct?> openDishCatalogBrowser(
  BuildContext context, {
  Set<String> inMenu = const {},
}) {
  return Navigator.of(context).push<DishCatalogProduct>(
    MaterialPageRoute(
      builder: (_) => DishCatalogBrowserScreen(inMenu: inMenu),
    ),
  );
}

/// Admin-managed popular Egyptian dishes and desserts. Picking one prefills
/// the item sheet; the restaurant then owns the copy.
class DishCatalogBrowserScreen extends StatefulWidget {
  const DishCatalogBrowserScreen({super.key, this.inMenu = const {}});

  final Set<String> inMenu;

  @override
  State<DishCatalogBrowserScreen> createState() =>
      _DishCatalogBrowserScreenState();
}

class _DishCatalogBrowserScreenState extends State<DishCatalogBrowserScreen> {
  final _search = TextEditingController();
  late final _dishes = getIt<DishCatalogRepository>().watchActive();
  DishCatalogCategory? _category;

  String get _lang => Get.locale?.languageCode ?? 'ar';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: CustomText(AppStrings.Catalog.dishesTitle),
        leading: IconButton(
          icon: Icon(ToukhIcons.back),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: StreamBuilder<List<DishCatalogProduct>>(
        stream: _dishes,
        builder: (context, snap) {
          if (snap.hasError) {
            return Center(child: CustomText(AppStrings.Common.error));
          }
          if (!snap.hasData) return const Center(child: AppLoadingMark());
          final all = snap.data!;
          if (all.isEmpty) {
            return Center(child: CustomText(AppStrings.Catalog.dishesEmpty));
          }
          final categories = DishCatalogCategory.values
              .where((c) => all.any((p) => p.category == c))
              .toList();
          final shown = all
              .where((p) => _category == null || p.category == _category)
              .where((p) => p.matches(_search.text))
              .toList();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: AppSizes.screenPadding.copyWith(bottom: 0),
                child: CustomText(
                  AppStrings.Catalog.dishesHint,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
              Padding(
                padding: AppSizes.screenPadding.copyWith(
                  top: AppSizes.spaceSm,
                  bottom: AppSizes.spaceSm,
                ),
                child: TextField(
                  controller: _search,
                  onChanged: (_) => setState(() {}),
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    hintText: AppStrings.Catalog.dishesSearch.tr,
                    prefixIcon: Icon(ToukhIcons.search),
                    isDense: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                    ),
                  ),
                ),
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
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: constraints.maxWidth >= 900
                                    ? 4
                                    : constraints.maxWidth >= 600
                                    ? 3
                                    : 2,
                                mainAxisSpacing: AppSizes.spaceMd,
                                crossAxisSpacing: AppSizes.spaceMd,
                                childAspectRatio: 0.82,
                              ),
                          itemCount: shown.length,
                          itemBuilder: (context, i) {
                            final p = shown[i];
                            return _DishTile(
                              product: p,
                              languageCode: _lang,
                              inMenu: widget.inMenu.contains(p.id),
                              onTap: () => Navigator.of(context).pop(p),
                            );
                          },
                        ),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(end: AppSizes.spaceSm),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
      ),
    );
  }
}

class _DishTile extends StatelessWidget {
  const _DishTile({
    required this.product,
    required this.languageCode,
    required this.inMenu,
    required this.onTap,
  });

  final DishCatalogProduct product;
  final String languageCode;
  final bool inMenu;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    final sizes = product.sizes.map((s) => s.label(languageCode)).join(' · ');
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
              color: inMenu ? AppColors.success : AppColors.borderSubtle,
              width: inMenu ? 2 : 1,
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
                        ? HavitNetworkImage(
                            imageUrl: product.imageUrl!,
                            fit: BoxFit.cover,
                          )
                        : ColoredBox(
                            color: scheme.surfaceContainerHighest,
                            child: Icon(
                              ToukhIcons.restaurant,
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                    if (inMenu)
                      PositionedDirectional(
                        top: 6,
                        end: 6,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.success,
                            borderRadius: BorderRadius.circular(
                              AppSizes.radiusFull,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                ToukhIcons.check,
                                size: 12,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 3),
                              Text(
                                AppStrings.Catalog.inMenu.tr,
                                style: t.labelSmall?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomText(
                      product.localizedName(languageCode),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: t.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    CustomText(
                      sizes.isNotEmpty
                          ? sizes
                          : product.category.label(languageCode),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: t.labelSmall?.copyWith(
                        color: scheme.onSurfaceVariant,
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
