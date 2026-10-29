import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:toukh_provider/domain/entities/menu_item.dart';
import 'package:toukh_provider/features/menu/presentation/catalog/catalog_item_sheet.dart';
import 'package:toukh_provider/l10n/app_strings.dart';
import 'package:toukh_ui/toukh_ui.dart';

/// Sale options (piece / pack of N / carton …) with prices, per-order limit,
/// sales terms, availability and menu section for one supermarket product.
Future<CatalogItemSheetResult?> showSupermarketItemSheet(
  BuildContext context, {
  required SupermarketCatalogProduct product,
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
    builder: (_) => _SupermarketItemSheet(
      product: product,
      menuCategories: menuCategories,
      existing: existing,
    ),
  );
}

class _SaleOption {
  _SaleOption(this.unit, {int? count, double? price})
      : count = TextEditingController(text: count == null ? '' : '$count'),
        price = TextEditingController(text: price == null ? '' : _fmt(price));

  GroceryUnitSize unit;
  final TextEditingController count;
  final TextEditingController price;

  static String _fmt(double p) =>
      p == p.roundToDouble() ? p.toStringAsFixed(0) : p.toStringAsFixed(2);

  void dispose() {
    count.dispose();
    price.dispose();
  }
}

class _SupermarketItemSheet extends StatefulWidget {
  const _SupermarketItemSheet({
    required this.product,
    required this.menuCategories,
    this.existing,
  });

  final SupermarketCatalogProduct product;
  final List<String> menuCategories;
  final MenuItemEntity? existing;

  @override
  State<_SupermarketItemSheet> createState() => _SupermarketItemSheetState();
}

class _SupermarketItemSheetState extends State<_SupermarketItemSheet> {
  final _options = <_SaleOption>[];
  late final TextEditingController _maxQty;
  late final TextEditingController _terms;
  late bool _available;
  late String _section;
  String? _error;

  String get _lang => Get.locale?.languageCode ?? 'ar';

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _available = e?.isAvailable ?? true;
    _section = e?.category ?? widget.product.aisle.label(_lang);
    _maxQty = TextEditingController(text: e?.maxOrderQty == null ? '' : '${e!.maxOrderQty}');
    _terms = TextEditingController(text: e?.salesTerms ?? '');
    for (final s in e?.sizes ?? const <MenuItemSize>[]) {
      final unit = GroceryUnitSize.tryParse(s.unitKey) ?? GroceryUnitSize.piece;
      _options.add(_SaleOption(unit, count: s.packCount, price: s.priceEgp));
    }
    if (_options.isEmpty) _options.add(_SaleOption(GroceryUnitSize.piece));
  }

  @override
  void dispose() {
    for (final o in _options) {
      o.dispose();
    }
    _maxQty.dispose();
    _terms.dispose();
    super.dispose();
  }

  void _clearError() {
    if (_error != null) setState(() => _error = null);
  }

  void _save() {
    final sizes = <MenuItemSize>[];
    final labels = <String>{};
    for (final o in _options) {
      final price = double.tryParse(o.price.text.trim().replaceAll(',', '.'));
      if (price == null || price <= 0) {
        setState(() => _error = AppStrings.Catalog.priceRequired.tr);
        return;
      }
      int? count;
      if (o.unit.takesCount) {
        count = int.tryParse(o.count.text.trim());
        if (count == null || count < 2) {
          setState(() => _error = AppStrings.Catalog.packCountRequired.tr);
          return;
        }
      }
      final label = o.unit.labelWithCount(_lang, count);
      if (!labels.add(label)) {
        setState(() => _error = AppStrings.Catalog.optionDuplicate.tr);
        return;
      }
      sizes.add(MenuItemSize(label: label, priceEgp: price, unitKey: o.unit.key, packCount: count));
    }
    if (sizes.isEmpty) {
      setState(() => _error = AppStrings.Catalog.sizeRequired.tr);
      return;
    }
    final maxText = _maxQty.text.trim();
    final maxQty = maxText.isEmpty ? null : int.tryParse(maxText);
    if (maxText.isNotEmpty && (maxQty == null || maxQty < 1)) {
      setState(() => _error = AppStrings.Catalog.maxQtyInvalid.tr);
      return;
    }
    final p = widget.product;
    final e = widget.existing;
    final terms = _terms.text.trim();
    Navigator.pop(
      context,
      CatalogItemSaved(
        MenuItemEntity(
          id: e?.id ?? 'sm_${p.id}',
          name: p.localizedName(_lang),
          nameAr: p.nameAr,
          nameEn: p.nameEn,
          description: p.subtitle(_lang).isEmpty ? null : p.subtitle(_lang),
          imageUrl: p.imageUrl,
          category: _section,
          sizes: sizes,
          isAvailable: _available,
          offerType: e?.offerType ?? MenuItemOfferType.none,
          discountPercent: e?.discountPercent,
          offerPriceEgp: e?.offerPriceEgp,
          catalogProductId: p.id,
          catalog: MenuCatalogKinds.supermarket,
          maxOrderQty: maxQty,
          salesTerms: terms.isEmpty ? null : terms,
        ),
      ),
    );
  }

  InputDecoration _decoration(String labelKey, {String? helperKey}) => InputDecoration(
        labelText: labelKey.tr,
        helperText: helperKey?.tr,
        helperMaxLines: 2,
        isDense: true,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppSizes.radiusMd)),
      );

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    final p = widget.product;
    final subtitle = p.subtitle(_lang);
    final sections = {...widget.menuCategories, p.aisle.label(_lang), _section}.toList();

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
                        ? HavitNetworkImage(imageUrl: p.imageUrl!, fit: BoxFit.contain)
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
                        subtitle.isEmpty ? p.aisle.label(_lang) : subtitle,
                        style: t.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                IconButton(onPressed: () => Navigator.pop(context), icon: Icon(ToukhIcons.close)),
              ],
            ),
            const SizedBox(height: AppSizes.spaceXl),
            CustomText(
              AppStrings.Catalog.saleOptionsTitle,
              style: t.titleSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: AppSizes.spaceXs),
            CustomText(
              AppStrings.Catalog.saleOptionsHint,
              style: t.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: AppSizes.spaceMd),
            for (final o in _options)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSizes.spaceSm),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 4,
                      child: DropdownButtonFormField<GroceryUnitSize>(
                        initialValue: o.unit,
                        isDense: true,
                        decoration: _decoration(AppStrings.Catalog.saleUnit),
                        items: [
                          for (final u in GroceryUnitSize.supermarketOptions)
                            DropdownMenuItem(value: u, child: Text(u.label(_lang))),
                        ],
                        onChanged: (v) => setState(() {
                          o.unit = v ?? o.unit;
                          _error = null;
                        }),
                      ),
                    ),
                    if (o.unit.takesCount) ...[
                      const SizedBox(width: AppSizes.spaceSm),
                      Expanded(
                        flex: 2,
                        child: TextField(
                          controller: o.count,
                          keyboardType: TextInputType.number,
                          inputFormatters: [const EnglishDigitsInputFormatter(), FilteringTextInputFormatter.digitsOnly],
                          onChanged: (_) => _clearError(),
                          decoration: _decoration(AppStrings.Catalog.packCount),
                        ),
                      ),
                    ],
                    const SizedBox(width: AppSizes.spaceSm),
                    Expanded(
                      flex: 3,
                      child: TextField(
                        controller: o.price,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: [const EnglishDigitsInputFormatter(), FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
                        onChanged: (_) => _clearError(),
                        decoration: _decoration(AppStrings.Catalog.priceLabel),
                      ),
                    ),
                    IconButton(
                      onPressed: _options.length == 1
                          ? null
                          : () => setState(() {
                                _options.remove(o);
                                o.dispose();
                              }),
                      icon: Icon(ToukhIcons.close, size: 18),
                    ),
                  ],
                ),
              ),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: AppTextButton(
                text: AppStrings.Catalog.addSaleOption,
                icon: ToukhIcons.add,
                size: AppButtonSize.small,
                onTap: _options.length >= 5
                    ? null
                    : () => setState(() => _options.add(_SaleOption(GroceryUnitSize.pack))),
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
            TextField(
              controller: _maxQty,
              keyboardType: TextInputType.number,
              inputFormatters: [const EnglishDigitsInputFormatter(), FilteringTextInputFormatter.digitsOnly],
              onChanged: (_) => _clearError(),
              decoration: _decoration(AppStrings.Catalog.maxQty, helperKey: AppStrings.Catalog.maxQtyHint),
            ),
            const SizedBox(height: AppSizes.spaceMd),
            TextField(
              controller: _terms,
              maxLines: 3,
              maxLength: 200,
              decoration: _decoration(AppStrings.Catalog.salesTerms, helperKey: AppStrings.Catalog.salesTermsHint),
            ),
            const SizedBox(height: AppSizes.spaceSm),
            DropdownButtonFormField<String>(
              initialValue: _section,
              decoration: _decoration(AppStrings.Catalog.menuSection),
              items: [for (final s in sections) DropdownMenuItem(value: s, child: Text(s))],
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
              text: widget.existing == null ? AppStrings.Catalog.addToMenu : AppStrings.Catalog.saveChanges,
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
