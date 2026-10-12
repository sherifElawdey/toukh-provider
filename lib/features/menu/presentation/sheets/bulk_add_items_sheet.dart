import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:toukh_provider/core/media/picked_media.dart';
import 'package:toukh_provider/core/media/safe_image_pick.dart';
import 'package:toukh_provider/core/utils/english_price_input.dart';
import 'package:toukh_provider/domain/entities/menu_item.dart';
import 'package:toukh_provider/features/menu/presentation/models/menu_item_editor_result.dart';
import 'package:toukh_provider/l10n/app_strings.dart';
import 'package:toukh_ui/toukh_ui.dart';
import 'package:uuid/uuid.dart';

Future<List<MenuItemEditorResult>?> showBulkAddItemsSheet(
  BuildContext context, {
  required String category,
}) {
  return showModalBottomSheet<List<MenuItemEditorResult>>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => BulkAddItemsSheet(category: category),
  );
}

class _SizeRow {
  _SizeRow({String label = 'Regular'})
      : id = const Uuid().v4(),
        labelController = TextEditingController(text: label),
        priceController = TextEditingController();

  final String id;
  final TextEditingController labelController;
  final TextEditingController priceController;

  void dispose() {
    labelController.dispose();
    priceController.dispose();
  }
}

class _ItemForm {
  _ItemForm()
      : id = const Uuid().v4(),
        name = TextEditingController(),
        description = TextEditingController(),
        discount = TextEditingController(),
        offerPrice = TextEditingController(),
        sizes = [_SizeRow()];

  final String id;
  final TextEditingController name;
  final TextEditingController description;
  final TextEditingController discount;
  final TextEditingController offerPrice;
  final List<_SizeRow> sizes;
  PickedMedia? image;
  bool available = true;
  MenuItemOfferType offer = MenuItemOfferType.none;

  void dispose() {
    name.dispose();
    description.dispose();
    discount.dispose();
    offerPrice.dispose();
    for (final size in sizes) {
      size.dispose();
    }
  }
}

class BulkAddItemsSheet extends StatefulWidget {
  const BulkAddItemsSheet({required this.category, super.key});

  final String category;

  @override
  State<BulkAddItemsSheet> createState() => _BulkAddItemsSheetState();
}

class _BulkAddItemsSheetState extends State<BulkAddItemsSheet> {
  final _items = <_ItemForm>[_ItemForm()];
  final _uuid = const Uuid();

  @override
  void dispose() {
    for (final item in _items) {
      item.dispose();
    }
    super.dispose();
  }

  void _addItem() => setState(() => _items.add(_ItemForm()));

  void _removeItem(int index) {
    if (_items.length <= 1) return;
    setState(() => _items.removeAt(index).dispose());
  }

  Future<void> _pickImage(_ItemForm item) async {
    final file = await pickImageFromSource(context, ImageSource.gallery);
    if (file == null) return;
    setState(() => item.image = file);
  }

  void _addSize(_ItemForm item) {
    setState(() => item.sizes.add(_SizeRow(label: '')));
  }

  void _removeSize(_ItemForm item, int index) {
    if (item.sizes.length <= 1) return;
    setState(() => item.sizes.removeAt(index).dispose());
  }

  bool _isUntouched(_ItemForm item) {
    if (item.name.text.trim().isNotEmpty) return false;
    if (item.description.text.trim().isNotEmpty) return false;
    if (item.image != null) return false;
    if (!item.available) return false;
    if (item.offer != MenuItemOfferType.none) return false;
    for (final size in item.sizes) {
      if (size.priceController.text.trim().isNotEmpty) return false;
      final label = size.labelController.text.trim();
      if (label.isNotEmpty && label != 'Regular') return false;
    }
    return true;
  }

  double? _parsePrice(String raw) {
    return double.tryParse(raw.trim().replaceAll(',', '.'));
  }

  void _warn(String message) {
    AppSnack.show(
      context,
      message: message,
      state: AppSnackState.warning,
      icon: ToukhIcons.warning,
    );
  }

  List<MenuItemSize>? _sizesFor(_ItemForm item) {
    final sizes = <MenuItemSize>[];
    for (final row in item.sizes) {
      final label = row.labelController.text.trim();
      final raw = row.priceController.text.trim();
      if (label.isEmpty && raw.isEmpty) continue;
      final price = _parsePrice(raw);
      if (label.isEmpty || price == null || price <= 0) {
        _warn(AppStrings.Registration.sizes.tr);
        return null;
      }
      sizes.add(MenuItemSize(label: label, priceEgp: price));
    }
    if (sizes.isEmpty) {
      _warn(AppStrings.Registration.sizes.tr);
      return null;
    }
    return sizes;
  }

  void _save() {
    final results = <MenuItemEditorResult>[];
    for (final item in _items) {
      if (_isUntouched(item)) continue;
      final name = item.name.text.trim();
      if (name.isEmpty) {
        _warn(AppStrings.Registration.itemTitle.tr);
        return;
      }
      final sizes = _sizesFor(item);
      if (sizes == null) return;

      double? discountPercent;
      double? offerPriceEgp;
      if (item.offer == MenuItemOfferType.percent) {
        discountPercent = _parsePrice(item.discount.text);
        if (discountPercent == null ||
            discountPercent <= 0 ||
            discountPercent > 100) {
          _warn(AppStrings.Registration.menuOfferPercentLabel.tr);
          return;
        }
      } else if (item.offer == MenuItemOfferType.fixed) {
        offerPriceEgp = _parsePrice(item.offerPrice.text);
        if (offerPriceEgp == null || offerPriceEgp <= 0) {
          _warn(AppStrings.Registration.menuOfferFixedLabel.tr);
          return;
        }
      }

      final description = item.description.text.trim();
      results.add(
        MenuItemEditorResult(
          entity: MenuItemEntity(
            id: _uuid.v4(),
            name: name,
            description: description.isEmpty ? null : description,
            category: widget.category,
            sizes: sizes,
            isAvailable: item.available,
            offerType: item.offer,
            discountPercent: discountPercent,
            offerPriceEgp: offerPriceEgp,
          ),
          newImageFile: item.image,
        ),
      );
    }

    if (results.isEmpty) {
      _warn(AppStrings.Registration.bulkAddInvalid.tr);
      return;
    }
    Navigator.pop(context, results);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppSizes.radiusXl),
          ),
        ),
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height * 0.92,
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: scheme.onSurface.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 8, 4),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CustomText(
                            AppStrings.Registration.bulkAddItems,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                          CustomText(
                            widget.category,
                            style: Theme.of(context).textTheme.bodySmall,
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
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                child: Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: CustomText(
                    AppStrings.Registration.bulkAddHint,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: scheme.onSurface.withValues(alpha: 0.65),
                        ),
                  ),
                ),
              ),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                  itemCount: _items.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(height: AppSizes.spaceMd),
                  itemBuilder: (context, index) {
                    return _BulkItemCard(
                      index: index,
                      item: _items[index],
                      canRemove: _items.length > 1,
                      onChanged: () => setState(() {}),
                      onRemove: () => _removeItem(index),
                      onPickImage: () => _pickImage(_items[index]),
                      onClearImage: () =>
                          setState(() => _items[index].image = null),
                      onAddSize: () => _addSize(_items[index]),
                      onRemoveSize: (sizeIndex) =>
                          _removeSize(_items[index], sizeIndex),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AppTextButton(
                      text: AppStrings.Registration.bulkAddRow,
                      icon: ToukhIcons.add,
                      onTap: _addItem,
                    ),
                    const SizedBox(height: AppSizes.spaceSm),
                    AppFilledButton(
                      text: AppStrings.Common.save,
                      onTap: _save,
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

class _BulkItemCard extends StatelessWidget {
  const _BulkItemCard({
    required this.index,
    required this.item,
    required this.canRemove,
    required this.onChanged,
    required this.onRemove,
    required this.onPickImage,
    required this.onClearImage,
    required this.onAddSize,
    required this.onRemoveSize,
  });

  final int index;
  final _ItemForm item;
  final bool canRemove;
  final VoidCallback onChanged;
  final VoidCallback onRemove;
  final VoidCallback onPickImage;
  final VoidCallback onClearImage;
  final VoidCallback onAddSize;
  final ValueChanged<int> onRemoveSize;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        border: Border.all(color: AppColors.borderSubtle, width: 0.6),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 8, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: CustomText(
                    '${index + 1}',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                ),
                if (canRemove)
                  IconButton(
                    onPressed: onRemove,
                    icon: Icon(ToukhIcons.delete, color: scheme.error),
                  ),
              ],
            ),
            Row(
              children: [
                Material(
                  color: AppColors.fieldFill(context),
                  borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                  child: InkWell(
                    onTap: onPickImage,
                    borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                    child: SizedBox(
                      width: 72,
                      height: 72,
                      child: item.image != null
                          ? ClipRRect(
                              borderRadius:
                                  BorderRadius.circular(AppSizes.radiusMd),
                              child: Image(
                                image: item.image!.imageProvider,
                                fit: BoxFit.cover,
                              ),
                            )
                          : Icon(
                              ToukhIcons.image,
                              color: scheme.onSurface.withValues(alpha: 0.45),
                            ),
                    ),
                  ),
                ),
                const SizedBox(width: AppSizes.spaceSm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      AppTextButton(
                        text: AppStrings.Registration.menuItemPhoto,
                        icon: ToukhIcons.gallery,
                        size: AppButtonSize.small,
                        onTap: onPickImage,
                      ),
                      if (item.image != null)
                        AppTextButton(
                          text: AppStrings.Registration.menuRemoveItemPhoto,
                          icon: PhosphorIconsRegular.eyeSlash,
                          size: AppButtonSize.small,
                          onTap: onClearImage,
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSizes.spaceSm),
            AppTextField(
              controller: item.name,
              labelText: AppStrings.Registration.itemTitle,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: AppSizes.spaceSm),
            AppTextField(
              controller: item.description,
              labelText: AppStrings.Registration.itemDescription,
              maxLines: 2,
              textInputAction: TextInputAction.next,
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: CustomText(
                item.available
                    ? AppStrings.Registration.menuItemAvailable
                    : AppStrings.Registration.menuItemUnavailable,
              ),
              value: item.available,
              onChanged: (value) {
                item.available = value;
                onChanged();
              },
            ),
            CustomText(
              AppStrings.Registration.menuItemOffer,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: AppSizes.spaceSm),
            SegmentedButton<MenuItemOfferType>(
              segments: [
                ButtonSegment(
                  value: MenuItemOfferType.none,
                  label: Text(AppStrings.Registration.menuOfferNone.tr),
                ),
                ButtonSegment(
                  value: MenuItemOfferType.percent,
                  label: Text(AppStrings.Registration.menuOfferPercent.tr),
                ),
                ButtonSegment(
                  value: MenuItemOfferType.fixed,
                  label: Text(AppStrings.Registration.menuOfferFixed.tr),
                ),
              ],
              selected: {item.offer},
              onSelectionChanged: (selected) {
                item.offer = selected.first;
                onChanged();
              },
            ),
            if (item.offer == MenuItemOfferType.percent) ...[
              const SizedBox(height: AppSizes.spaceSm),
              AppTextField(
                controller: item.discount,
                labelText: AppStrings.Registration.menuOfferPercentLabel,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: EnglishPriceInput.formatters,
              ),
            ],
            if (item.offer == MenuItemOfferType.fixed) ...[
              const SizedBox(height: AppSizes.spaceSm),
              AppTextField(
                controller: item.offerPrice,
                labelText: AppStrings.Registration.menuOfferFixedLabel,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: EnglishPriceInput.formatters,
              ),
            ],
            const SizedBox(height: AppSizes.spaceMd),
            Row(
              children: [
                Expanded(
                  child: CustomText(
                    AppStrings.Registration.sizes,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                ),
                AppTextButton(
                  text: AppStrings.Registration.addSize,
                  icon: ToukhIcons.add,
                  size: AppButtonSize.small,
                  onTap: onAddSize,
                ),
              ],
            ),
            for (var i = 0; i < item.sizes.length; i++) ...[
              const SizedBox(height: AppSizes.spaceSm),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: AppTextField(
                      controller: item.sizes[i].labelController,
                      labelText: AppStrings.Registration.sizeLabel,
                      hintText: AppStrings.Registration.regular,
                    ),
                  ),
                  const SizedBox(width: AppSizes.spaceSm),
                  Expanded(
                    child: AppTextField(
                      controller: item.sizes[i].priceController,
                      labelText: AppStrings.Registration.pricePerSize,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      suffixText: 'EGP',
                      inputFormatters: EnglishPriceInput.formatters,
                    ),
                  ),
                  IconButton(
                    onPressed: item.sizes.length > 1
                        ? () => onRemoveSize(i)
                        : null,
                    icon: Icon(ToukhIcons.delete),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
