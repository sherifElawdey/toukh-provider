import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:toukh_provider/domain/entities/menu_item.dart';
import 'package:toukh_provider/l10n/app_strings.dart';
import 'package:toukh_ui/toukh_ui.dart';

/// What the store chose in [showCatalogItemSheet].
sealed class CatalogItemSheetResult {
  const CatalogItemSheetResult();
}

class CatalogItemSaved extends CatalogItemSheetResult {
  const CatalogItemSaved(this.item);
  final MenuItemEntity item;
}

class CatalogItemRemoved extends CatalogItemSheetResult {
  const CatalogItemRemoved();
}

/// Sizes, prices, availability and menu section for one catalog product.
/// [existing] is the store's menu item when the product is already listed.
Future<CatalogItemSheetResult?> showCatalogItemSheet(
  BuildContext context, {
  required GroceryCatalogProduct product,
  required List<String> menuCategories,
  MenuItemEntity? existing,
}) {
  return showModalBottomSheet<CatalogItemSheetResult>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppSizes.radiusXl)),
    ),
    builder: (_) => _CatalogItemSheet(
      product: product,
      menuCategories: menuCategories,
      existing: existing,
    ),
  );
}

class _CatalogItemSheet extends StatefulWidget {
  const _CatalogItemSheet({
    required this.product,
    required this.menuCategories,
    this.existing,
  });

  final GroceryCatalogProduct product;
  final List<String> menuCategories;
  final MenuItemEntity? existing;

  @override
  State<_CatalogItemSheet> createState() => _CatalogItemSheetState();
}

class _CatalogItemSheetState extends State<_CatalogItemSheet> {
  /// Selected sizes in display order, each with its price field.
  final _prices = <GroceryUnitSize, TextEditingController>{};
  late bool _available;
  late String _section;
  String? _error;

  String get _lang => Get.locale?.languageCode ?? 'ar';

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _available = existing?.isAvailable ?? true;
    _section = existing?.category ?? widget.product.category.label(_lang);
    if (existing != null) {
      for (final s in existing.sizes) {
        final unit = GroceryUnitSize.tryParse(s.unitKey);
        if (unit == null) continue;
        _prices[unit] = TextEditingController(text: _formatPrice(s.priceEgp));
      }
    }
    if (_prices.isEmpty) {
      for (final unit in widget.product.unit.defaultSizes) {
        _prices[unit] = TextEditingController();
      }
    }
  }

  @override
  void dispose() {
    for (final c in _prices.values) {
      c.dispose();
    }
    super.dispose();
  }

  static String _formatPrice(double p) =>
      p == p.roundToDouble() ? p.toStringAsFixed(0) : p.toStringAsFixed(2);

  void _toggle(GroceryUnitSize unit, bool on) {
    setState(() {
      _error = null;
      if (on) {
        _prices[unit] = TextEditingController();
      } else {
        _prices.remove(unit)?.dispose();
      }
    });
  }

  void _save() {
    if (_prices.isEmpty) {
      setState(() => _error = AppStrings.Catalog.sizeRequired.tr);
      return;
    }
    final sizes = <MenuItemSize>[];
    // Keep the preset order (1 kg before ½ kg …) whatever the tap order.
    for (final unit in GroceryUnitSize.values) {
      final ctrl = _prices[unit];
      if (ctrl == null) continue;
      final price = double.tryParse(ctrl.text.trim().replaceAll(',', '.'));
      if (price == null || price <= 0) {
        setState(() => _error = AppStrings.Catalog.priceRequired.tr);
        return;
      }
      sizes.add(MenuItemSize(label: unit.label(_lang), priceEgp: price, unitKey: unit.key));
    }
    final p = widget.product;
    final existing = widget.existing;
    Navigator.pop(
      context,
      CatalogItemSaved(
        MenuItemEntity(
          id: existing?.id ?? 'catalog_${p.id}',
          name: p.localizedName(_lang),
          nameAr: p.nameAr,
          nameEn: p.nameEn,
          imageUrl: p.imageUrl,
          category: _section,
          sizes: sizes,
          isAvailable: _available,
          offerType: existing?.offerType ?? MenuItemOfferType.none,
          discountPercent: existing?.discountPercent,
          offerPriceEgp: existing?.offerPriceEgp,
          catalogProductId: p.id,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    final p = widget.product;
    final otherName = _lang == 'ar' ? p.nameEn : p.nameAr;
    final sections = {
      ...widget.menuCategories,
      p.category.label(_lang),
      _section,
    }.toList();

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: AppSizes.screenPadding.copyWith(top: AppSizes.spaceLg, bottom: AppSizes.spaceXl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                  child: SizedBox(
                    width: 64,
                    height: 64,
                    child: p.hasImage
                        ? HavitNetworkImage(imageUrl: p.imageUrl!, fit: BoxFit.cover)
                        : ColoredBox(
                            color: scheme.surfaceContainerHighest,
                            child: Icon(ToukhIcons.store, color: scheme.onSurfaceVariant),
                          ),
                  ),
                ),
                const SizedBox(width: AppSizes.spaceMd),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CustomText(
                        p.localizedName(_lang),
                        style: t.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      CustomText(
                        '$otherName · ${p.category.label(_lang)}',
                        style: t.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(ToukhIcons.close),
                ),
              ],
            ),
            const SizedBox(height: AppSizes.spaceXl),
            CustomText(
              AppStrings.Catalog.sizesTitle,
              style: t.titleSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: AppSizes.spaceXs),
            CustomText(
              AppStrings.Catalog.sizesHint,
              style: t.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: AppSizes.spaceMd),
            Wrap(
              spacing: AppSizes.spaceSm,
              runSpacing: AppSizes.spaceSm,
              children: [
                for (final unit in GroceryUnitSize.values)
                  FilterChip(
                    label: Text(unit.label(_lang)),
                    selected: _prices.containsKey(unit),
                    onSelected: (v) => _toggle(unit, v),
                  ),
              ],
            ),
            const SizedBox(height: AppSizes.spaceMd),
            for (final unit in GroceryUnitSize.values)
              if (_prices[unit] != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSizes.spaceSm),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 96,
                        child: CustomText(
                          unit.label(_lang),
                          style: t.bodyLarge?.copyWith(fontWeight: FontWeight.w700),
                        ),
                      ),
                      Expanded(
                        child: TextField(
                          controller: _prices[unit],
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                          ],
                          onChanged: (_) {
                            if (_error != null) setState(() => _error = null);
                          },
                          decoration: InputDecoration(
                            labelText: AppStrings.Catalog.priceLabel.tr,
                            isDense: true,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            if (_error != null) ...[
              const SizedBox(height: AppSizes.spaceXs),
              CustomText(
                _error!,
                style: t.bodySmall?.copyWith(color: scheme.error, fontWeight: FontWeight.w600),
              ),
            ],
            const SizedBox(height: AppSizes.spaceLg),
            DropdownButtonFormField<String>(
              initialValue: _section,
              decoration: InputDecoration(
                labelText: AppStrings.Catalog.menuSection.tr,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppSizes.radiusMd)),
              ),
              items: [
                for (final s in sections) DropdownMenuItem(value: s, child: Text(s)),
              ],
              onChanged: (v) => setState(() => _section = v ?? _section),
            ),
            const SizedBox(height: AppSizes.spaceSm),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: CustomText(AppStrings.Catalog.available, fontWeight: FontWeight.w700),
              subtitle: CustomText(AppStrings.Catalog.availableHint),
              value: _available,
              onChanged: (v) => setState(() => _available = v),
            ),
            const SizedBox(height: AppSizes.spaceLg),
            AppFilledButton(
              text: widget.existing == null
                  ? AppStrings.Catalog.addToMenu
                  : AppStrings.Catalog.saveChanges,
              onTap: _save,
            ),
            if (widget.existing != null) ...[
              const SizedBox(height: AppSizes.spaceSm),
              AppTextButton(
                text: AppStrings.Catalog.removeFromMenu,
                color: scheme.error,
                onTap: () => Navigator.pop(context, const CatalogItemRemoved()),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
