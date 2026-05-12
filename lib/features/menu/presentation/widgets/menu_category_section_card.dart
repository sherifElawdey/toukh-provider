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
    return Material(
      elevation: 1,
      shadowColor: scheme.shadow.withValues(alpha: 0.12),
      color: scheme.surface,
      borderRadius: BorderRadius.circular(AppSizes.radiusLg),
      child: Padding(
        padding: const EdgeInsets.all(12),
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
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      SizedBox(height: 2),
                      CustomText(
                        '$itemCount items',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: scheme.onSurface.withValues(alpha: 0.55),
                            ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: AppStrings.Registration.addItem.tr,
                  icon: const Icon(Icons.add_rounded),
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
                        leading: const Icon(Icons.edit_outlined),
                        title: CustomText(AppStrings.Registration.renameCategory),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: ListTile(
                        leading: Icon(
                          Icons.delete_outline,
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
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Center(
                  child: CustomText(
                    AppStrings.Registration.noItemsInCategory,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurface.withValues(alpha: 0.5),
                        ),
                  ),
                ),
              )
            else
              ...items.map(
                (item) => Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: MenuItemTile(
                    item: item,
                    onTap: () => onEditItem(item),
                    onDelete: () => onDeleteItem(item),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
