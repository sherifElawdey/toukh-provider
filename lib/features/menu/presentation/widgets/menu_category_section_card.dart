import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:toukh_provider/domain/entities/menu_item.dart';
import 'package:toukh_provider/features/menu/presentation/widgets/menu_item_tile.dart';
import 'package:toukh_provider/l10n/app_strings.dart';
import 'package:toukh_ui/toukh_ui.dart';

class MenuCategorySectionCard extends StatelessWidget {
  const MenuCategorySectionCard({
    super.key,
    required this.category,
    required this.itemCount,
    required this.items,
    required this.onAddItem,
    required this.onEditItem,
    required this.onDeleteItem,
    required this.onRenameCategory,
    required this.onDeleteCategory,
  });

  final String category;
  final int itemCount;
  final List<MenuItemEntity> items;
  final VoidCallback onAddItem;
  final void Function(MenuItemEntity) onEditItem;
  final void Function(MenuItemEntity) onDeleteItem;
  final VoidCallback onRenameCategory;
  final VoidCallback onDeleteCategory;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        border: Border.all(color: AppColors.borderSubtle, width: 0.6),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 8, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CustomText(
                        category,
                        style: t.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      CustomText(
                        '$itemCount items',
                        style: t.bodySmall?.copyWith(
                          color: scheme.onSurface.withValues(alpha: 0.5),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: AppStrings.Registration.addItem.tr,
                  icon: Icon(
                    ToukhIcons.add,
                    color: AppColors.secondColor,
                  ),
                  onPressed: onAddItem,
                ),
                PopupMenuButton<String>(
                  onSelected: (v) {
                    if (v == 'rename') onRenameCategory();
                    if (v == 'delete') onDeleteCategory();
                  },
                  itemBuilder: (ctx) => [
                    PopupMenuItem(
                      value: 'rename',
                      child: ListTile(
                        leading: Icon(ToukhIcons.edit),
                        title:
                            CustomText(AppStrings.Registration.renameCategory),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: ListTile(
                        leading: Icon(
                          ToukhIcons.delete,
                          color: scheme.error,
                        ),
                        title: CustomText(AppStrings.Common.delete),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            if (items.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Center(
                  child: CustomText(
                    AppStrings.Registration.noItemsInCategory,
                    style: t.bodyMedium?.copyWith(
                      color: scheme.onSurface.withValues(alpha: 0.45),
                    ),
                  ),
                ),
              )
            else
              ...[
                for (var i = 0; i < items.length; i++)
                  MenuItemTile(
                    item: items[i],
                    showDivider: i < items.length - 1,
                    onTap: () => onEditItem(items[i]),
                    onDelete: () => onDeleteItem(items[i]),
                  ),
              ],
          ],
        ),
      ),
    );
  }
}
