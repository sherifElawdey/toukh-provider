import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:toukh_provider/domain/entities/menu_item.dart';
import 'package:toukh_provider/features/menu/presentation/models/menu_item_editor_result.dart';
import 'package:toukh_provider/l10n/app_strings.dart';
import 'package:toukh_ui/toukh_ui.dart';
import 'package:uuid/uuid.dart';

class AddOrEditItemSheet extends StatefulWidget {
  const AddOrEditItemSheet({
    super.key,
    required this.categories,
    required this.initialCategory,
    this.existing,
  });

  final List<String> categories;
  final String initialCategory;
  final MenuItemEntity? existing;

  @override
  State<AddOrEditItemSheet> createState() => _AddOrEditItemSheetState();
}

class _SizeRow {
  _SizeRow({
    required this.id,
    required this.labelController,
    required this.priceController,
  });

  final String id;
  final TextEditingController labelController;
  final TextEditingController priceController;
}

class _AddOrEditItemSheetState extends State<AddOrEditItemSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _uuid = const Uuid();
  final _picker = ImagePicker();

  late String? _selectedCategory;
  final _rows = <_SizeRow>[];
  File? _pickedImage;
  bool _removedImage = false;

  @override
  void initState() {
    super.initState();
    final ex = widget.existing;
    if (ex != null) {
      _titleCtrl.text = ex.name;
      _descCtrl.text = ex.description ?? '';
      for (final s in ex.sizes) {
        _rows.add(
          _SizeRow(
            id: _uuid.v4(),
            labelController: TextEditingController(text: s.label),
            priceController: TextEditingController(
              text: _priceText(s.priceEgp),
            ),
          ),
        );
      }
    } else {
      _rows.add(
        _SizeRow(
          id: _uuid.v4(),
          labelController: TextEditingController(text: 'Regular'),
          priceController: TextEditingController(),
        ),
      );
    }
    final merged = widget.categories;
    _selectedCategory = merged.contains(widget.initialCategory)
        ? widget.initialCategory
        : (merged.isNotEmpty ? merged.first : null);
  }

  String _priceText(double v) {
    if (v == v.roundToDouble()) return v.toStringAsFixed(0);
    return v.toString();
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    for (final r in _rows) {
      r.labelController.dispose();
      r.priceController.dispose();
    }
    super.dispose();
  }

  Future<void> _pickImage() async {
    final res = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1600,
      imageQuality: 88,
    );
    if (res == null) return;
    setState(() {
      _pickedImage = File(res.path);
      _removedImage = false;
    });
  }

  void _clearImage() {
    setState(() {
      _pickedImage = null;
      _removedImage = true;
    });
  }

  void _addSizeRow() {
    setState(() {
      _rows.add(
        _SizeRow(
          id: _uuid.v4(),
          labelController: TextEditingController(),
          priceController: TextEditingController(),
        ),
      );
    });
  }

  void _removeRow(int index) {
    if (_rows.length <= 1) return;
    setState(() {
      final r = _rows.removeAt(index);
      r.labelController.dispose();
      r.priceController.dispose();
    });
  }

  void _onReorder(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) newIndex--;
      final r = _rows.removeAt(oldIndex);
      _rows.insert(newIndex, r);
    });
  }

  List<MenuItemSize>? _tryCollectSizes(BuildContext context) {
    final sizes = <MenuItemSize>[];
    for (final row in _rows) {
      final label = row.labelController.text.trim();
      final raw = row.priceController.text.trim().replaceAll(',', '.');
      if (label.isEmpty && raw.isEmpty) continue;
      final price = double.tryParse(raw);
      if (label.isEmpty || price == null || price <= 0) {
        AppSnack.show(
          context,
          message: AppStrings.Registration.sizes.tr,
          state: AppSnackState.warning,
          icon: Icons.straighten_rounded,
        );
        return null;
      }
      sizes.add(MenuItemSize(label: label, priceEgp: price));
    }
    return sizes;
  }

  String? _effectiveImageUrl() {
    if (_removedImage) return null;
    return widget.existing?.imageUrl;
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_selectedCategory == null) {
      AppSnack.show(
        context,
        message: AppStrings.Registration.selectCategory.tr,
        state: AppSnackState.warning,
        icon: Icons.category_outlined,
      );
      return;
    }
    final sizes = _tryCollectSizes(context);
    if (sizes == null) return;
    if (sizes.isEmpty) {
      AppSnack.show(
        context,
        message: AppStrings.Registration.sizes.tr,
        state: AppSnackState.warning,
        icon: Icons.straighten_rounded,
      );
      return;
    }

    final imageUrl = _effectiveImageUrl();
    final entity = MenuItemEntity(
      id: widget.existing?.id ?? _uuid.v4(),
      name: _titleCtrl.text.trim(),
      description: _descCtrl.text.trim().isEmpty
          ? null
          : _descCtrl.text.trim(),
      imageUrl: imageUrl,
      category: _selectedCategory!,
      sizes: sizes,
    );

    final clearImage = _removedImage && _pickedImage == null;
    Navigator.pop(
      context,
      MenuItemEditorResult(
        entity: entity,
        newImageFile: _pickedImage,
        clearImage: clearImage,
      ),
    );
  }

  InputDecoration _dropdownDecoration(BuildContext context) {
    return InputDecoration(
      filled: true,
      fillColor: AppColors.fieldFill(context),
      labelText: AppStrings.Registration.selectCategory.tr,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSizes.spaceBase,
        vertical: AppSizes.spaceBase,
      ),
    );
  }

  Widget _buildImagePicker(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final ex = widget.existing;
    final remoteUrl = ex?.imageUrl?.trim();
    final hasRemote =
        remoteUrl != null && remoteUrl.isNotEmpty && !_removedImage;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomText(
          AppStrings.Registration.menuItemPhoto,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
        ),
        SizedBox(height: AppSizes.spaceSm),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Material(
              color: AppColors.fieldFill(context),
              borderRadius: BorderRadius.circular(AppSizes.radiusMd),
              child: InkWell(
                onTap: _pickImage,
                borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                child: SizedBox(
                  width: 96,
                  height: 96,
                  child: _pickedImage != null
                      ? ClipRRect(
                          borderRadius:
                              BorderRadius.circular(AppSizes.radiusMd),
                          child: Image.file(
                            _pickedImage!,
                            fit: BoxFit.cover,
                          ),
                        )
                      : hasRemote
                          ? ClipRRect(
                              borderRadius:
                                  BorderRadius.circular(AppSizes.radiusMd),
                              child: Image.network(
                                remoteUrl,
                                fit: BoxFit.cover,
                                loadingBuilder: (context, child, progress) {
                                  if (progress == null) return child;
                                  return Center(
                                    child: SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: scheme.primary,
                                      ),
                                    ),
                                  );
                                },
                                errorBuilder: (_, _, _) => Center(
                                  child: Icon(
                                    Icons.broken_image_outlined,
                                    color: scheme.onSurface
                                        .withValues(alpha: 0.4),
                                  ),
                                ),
                              ),
                            )
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.add_photo_alternate_outlined,
                                  color: scheme.onSurface
                                      .withValues(alpha: 0.45),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                  ),
                                  child: Text(
                                    AppStrings.Registration.menuTapAddItemPhoto
                                        .tr,
                                    textAlign: TextAlign.center,
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelSmall
                                        ?.copyWith(
                                          color: scheme.onSurface
                                              .withValues(alpha: 0.55),
                                        ),
                                  ),
                                ),
                              ],
                            ),
                ),
              ),
            ),
            SizedBox(width: AppSizes.spaceMd),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextButton.icon(
                    onPressed: _pickImage,
                    icon: const Icon(Icons.photo_library_outlined, size: 20),
                    label: CustomText(AppStrings.Registration.menuItemPhoto),
                  ),
                  if (_pickedImage != null || hasRemote)
                    TextButton.icon(
                      onPressed: _clearImage,
                      icon: const Icon(Icons.hide_image_outlined, size: 20),
                      label:
                          CustomText(AppStrings.Registration.menuRemoveItemPhoto),
                    ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          top: false,
          child: DraggableScrollableSheet(
            expand: false,
            initialChildSize: 0.92,
            minChildSize: 0.45,
            maxChildSize: 0.98,
            builder: (context, scrollCtrl) {
              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: scheme.onSurface.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 8, 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: CustomText(
                            widget.existing == null
                                ? AppStrings.Registration.addItem
                                : AppStrings.Registration.editItem,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close_rounded),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Form(
                      key: _formKey,
                      child: ListView(
                        controller: scrollCtrl,
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                        children: [
                          _buildImagePicker(context),
                          SizedBox(height: AppSizes.spaceMd),
                          AppTextField(
                            controller: _titleCtrl,
                            labelText: AppStrings.Registration.itemTitle,
                            leadingIcon: Icons.fastfood_outlined,
                            textInputAction: TextInputAction.next,
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) {
                                return AppStrings.Registration.itemTitle.tr;
                              }
                              return null;
                            },
                          ),
                          SizedBox(height: AppSizes.spaceMd),
                          AppTextField(
                            controller: _descCtrl,
                            labelText: AppStrings.Registration.itemDescription,
                            maxLines: 3,
                            leadingIcon: Icons.list_alt_outlined,
                            textInputAction: TextInputAction.next,
                          ),
                          SizedBox(height: AppSizes.spaceMd),
                          DropdownButtonFormField<String>(
                            // ignore: deprecated_member_use
                            value: _selectedCategory,
                            decoration: _dropdownDecoration(context),
                            items: widget.categories
                                .map(
                                  (c) => DropdownMenuItem(
                                    value: c,
                                    child: Text(c),
                                  ),
                                )
                                .toList(),
                            onChanged: (v) =>
                                setState(() => _selectedCategory = v),
                            validator: (v) =>
                                v == null || v.isEmpty
                                    ? AppStrings.Registration.selectCategory.tr
                                    : null,
                          ),
                          SizedBox(height: AppSizes.spaceLg),
                          Row(
                            children: [
                              Expanded(
                                child: CustomText(
                                  AppStrings.Registration.sizes,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleSmall
                                      ?.copyWith(fontWeight: FontWeight.w800),
                                ),
                              ),
                              TextButton.icon(
                                onPressed: _addSizeRow,
                                icon: const Icon(Icons.add, size: 18),
                                label: CustomText(
                                  AppStrings.Registration.addSize,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: AppSizes.spaceSm),
                          ReorderableListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            buildDefaultDragHandles: false,
                            onReorder: _onReorder,
                            itemCount: _rows.length,
                            itemBuilder: (context, index) {
                              final row = _rows[index];
                              return Card(
                                key: ValueKey(row.id),
                                margin: const EdgeInsets.only(bottom: 8),
                                elevation: 0,
                                color: AppColors.fieldFill(context),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                    AppSizes.radiusMd,
                                  ),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 8,
                                    horizontal: 8,
                                  ),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      ReorderableDragStartListener(
                                        index: index,
                                        child: Padding(
                                          padding: const EdgeInsets.only(
                                            top: 12,
                                          ),
                                          child: Icon(
                                            Icons.drag_handle_rounded,
                                            color: scheme.onSurface
                                                .withValues(alpha: 0.45),
                                          ),
                                        ),
                                      ),
                                      SizedBox(width: 4),
                                      Expanded(
                                        flex: 2,
                                        child: AppTextField(
                                          controller: row.labelController,
                                          labelText:
                                              AppStrings.Registration.sizeLabel,
                                          hintText: AppStrings
                                              .Registration.regular,
                                        ),
                                      ),
                                      SizedBox(width: 8),
                                      Expanded(
                                        flex: 2,
                                        child: AppTextField(
                                          controller: row.priceController,
                                          labelText: AppStrings
                                              .Registration.pricePerSize,
                                          keyboardType:
                                              const TextInputType.numberWithOptions(
                                            decimal: true,
                                          ),
                                          suffixText: 'EGP',
                                          inputFormatters: [
                                            FilteringTextInputFormatter.allow(
                                              RegExp(r'[\d.,]'),
                                            ),
                                          ],
                                        ),
                                      ),
                                      IconButton(
                                        onPressed: _rows.length > 1
                                            ? () => _removeRow(index)
                                            : null,
                                        icon: const Icon(
                                          Icons.delete_outline,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      20,
                      8,
                      20,
                      16 + MediaQuery.paddingOf(context).bottom,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            child: CustomText(AppStrings.Common.cancel),
                          ),
                        ),
                        SizedBox(width: AppSizes.spaceMd),
                        Expanded(
                          child: FilledButton(
                            onPressed: _submit,
                            child: CustomText(AppStrings.Common.save),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
