import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:toukh_provider/di/service_locator.dart';
import 'package:toukh_provider/l10n/app_strings.dart';
import 'package:toukh_ui/toukh_ui.dart';

/// Other shops: pick one main category (tap to open its shop types), one or
/// more shop types inside it, and how customers order. Controlled: the parent
/// owns the values and gets every change through [onChanged].
class OtherShopPicker extends StatefulWidget {
  const OtherShopPicker({
    super.key,
    required this.categoryId,
    required this.typeIds,
    required this.orderMode,
    required this.onChanged,
  });

  final String? categoryId;
  final List<String> typeIds;
  final ProviderOrderMode? orderMode;
  final void Function(String? categoryId, List<String> typeIds, ProviderOrderMode? orderMode) onChanged;

  @override
  State<OtherShopPicker> createState() => _OtherShopPickerState();
}

class _OtherShopPickerState extends State<OtherShopPicker> {
  late final Stream<List<OtherShopCategory>> _categories =
      watchOtherShopCategories(getIt<FirebaseFirestore>());
  late String? _expanded = widget.categoryId;

  void _toggleCategory(OtherShopCategory c) {
    setState(() => _expanded = _expanded == c.id ? null : c.id);
    if (widget.categoryId != c.id) {
      widget.onChanged(c.id, const [], widget.orderMode);
    }
  }

  void _toggleType(OtherShopCategory c, OtherShopType t) {
    final ids = widget.categoryId == c.id ? [...widget.typeIds] : <String>[];
    ids.contains(t.id) ? ids.remove(t.id) : ids.add(t.id);
    widget.onChanged(c.id, ids, widget.orderMode);
  }

  @override
  Widget build(BuildContext context) {
    final lang = Get.locale?.languageCode ?? 'ar';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        StreamBuilder<List<OtherShopCategory>>(
          stream: _categories,
          builder: (context, snap) {
            if (!snap.hasData) {
              return const Padding(
                padding: EdgeInsets.all(AppSizes.space2xl),
                child: Center(child: CircularProgressIndicator()),
              );
            }
            final list = snap.data!;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final c in list)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSizes.spaceSm),
                    child: _CategoryTile(
                      category: c,
                      lang: lang,
                      selected: widget.categoryId == c.id,
                      expanded: _expanded == c.id,
                      selectedTypeIds: widget.categoryId == c.id ? widget.typeIds : const [],
                      onTap: () => _toggleCategory(c),
                      onType: (t) => _toggleType(c, t),
                    ),
                  ),
              ],
            );
          },
        ),
        SizedBox(height: AppSizes.spaceLg),
        CustomText(
          AppStrings.Registration.orderModeTitle,
          style: const TextStyle(fontSize: AppSizes.fontBody, fontWeight: FontWeight.w800),
        ),
        SizedBox(height: AppSizes.spaceSm),
        for (final mode in ProviderOrderMode.values)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSizes.spaceSm),
            child: _OrderModeTile(
              mode: mode,
              selected: widget.orderMode == mode,
              onTap: () => widget.onChanged(widget.categoryId, widget.typeIds, mode),
            ),
          ),
      ],
    );
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({
    required this.category,
    required this.lang,
    required this.selected,
    required this.expanded,
    required this.selectedTypeIds,
    required this.onTap,
    required this.onType,
  });

  final OtherShopCategory category;
  final String lang;
  final bool selected;
  final bool expanded;
  final List<String> selectedTypeIds;
  final VoidCallback onTap;
  final ValueChanged<OtherShopType> onType;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final count = selectedTypeIds.length;
    return Material(
      color: selected ? AppColors.tint(context, AppColors.secondColor) : scheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        side: BorderSide(
          color: selected ? AppColors.secondColor : AppColors.borderSubtle,
          width: selected ? 2 : 1.2,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSizes.spaceMd, vertical: AppSizes.spaceMd),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CustomText(
                          category.name(lang),
                          style: const TextStyle(fontSize: AppSizes.fontBody, fontWeight: FontWeight.w700),
                        ),
                        if (selected && count > 0)
                          CustomText(
                            AppStrings.Registration.otherShopTypesSelected.trParams({'count': '$count'}),
                            style: TextStyle(fontSize: AppSizes.fontCaption, color: AppColors.secondColor),
                          ),
                      ],
                    ),
                  ),
                  if (selected && count > 0)
                    const Padding(
                      padding: EdgeInsetsDirectional.only(end: AppSizes.spaceSm),
                      child: Icon(PhosphorIconsFill.checkCircle, color: AppColors.success, size: 20),
                    ),
                  AnimatedRotation(
                    turns: expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(PhosphorIconsBold.caretDown, size: 18, color: scheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            alignment: Alignment.topCenter,
            child: !expanded
                ? const SizedBox(width: double.infinity)
                : Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSizes.spaceMd, 0, AppSizes.spaceMd, AppSizes.spaceMd),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CustomText(
                          AppStrings.Registration.otherShopTypesHint,
                          style: TextStyle(fontSize: AppSizes.fontCaption, color: scheme.onSurfaceVariant),
                        ),
                        SizedBox(height: AppSizes.spaceSm),
                        Wrap(
                          spacing: AppSizes.spaceSm,
                          runSpacing: AppSizes.spaceSm,
                          children: [
                            for (final t in category.types)
                              FilterChip(
                                label: Text(t.name(lang)),
                                selected: selectedTypeIds.contains(t.id),
                                onSelected: (_) => onType(t),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _OrderModeTile extends StatelessWidget {
  const _OrderModeTile({required this.mode, required this.selected, required this.onTap});

  final ProviderOrderMode mode;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final (icon, title, hint) = switch (mode) {
      ProviderOrderMode.menu => (
          PhosphorIconsDuotone.listBullets,
          AppStrings.Registration.orderModeMenu,
          AppStrings.Registration.orderModeMenuHint,
        ),
      ProviderOrderMode.customRequests => (
          PhosphorIconsDuotone.chatCircleText,
          AppStrings.Registration.orderModeCustom,
          AppStrings.Registration.orderModeCustomHint,
        ),
    };
    return Material(
      color: selected ? AppColors.tint(context, AppColors.secondColor) : scheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        side: BorderSide(
          color: selected ? AppColors.secondColor : AppColors.borderSubtle,
          width: selected ? 2 : 1.2,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.spaceMd),
          child: Row(
            children: [
              Icon(icon, size: 30, color: AppColors.secondColor),
              SizedBox(width: AppSizes.spaceMd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomText(
                      title,
                      style: const TextStyle(fontSize: AppSizes.fontBody, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 2),
                    CustomText(
                      hint,
                      style: TextStyle(
                        fontSize: AppSizes.fontCaption,
                        color: scheme.onSurfaceVariant,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                selected ? PhosphorIconsFill.radioButton : PhosphorIconsRegular.circle,
                color: selected ? AppColors.secondColor : scheme.outline,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
