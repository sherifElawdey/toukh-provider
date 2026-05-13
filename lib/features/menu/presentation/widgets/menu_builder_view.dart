import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:toukh_provider/domain/entities/menu_item.dart';
import 'package:toukh_provider/features/auth/cubit/auth_cubit.dart';
import 'package:toukh_provider/features/menu/presentation/cubit/menu_builder_cubit.dart';
import 'package:toukh_provider/features/menu/presentation/cubit/menu_builder_state.dart';
import 'package:toukh_provider/features/menu/presentation/models/menu_item_editor_result.dart';
import 'package:toukh_provider/features/menu/presentation/sheets/add_category_sheet.dart';
import 'package:toukh_provider/features/menu/presentation/sheets/add_or_edit_item_sheet.dart';
import 'package:toukh_provider/features/menu/presentation/widgets/menu_builder_header_card.dart';
import 'package:toukh_provider/features/menu/presentation/widgets/menu_category_filter_chips.dart';
import 'package:toukh_provider/features/menu/presentation/widgets/menu_category_section_card.dart';
import 'package:toukh_provider/features/menu/presentation/widgets/menu_empty_categories_placeholder.dart';
import 'package:toukh_provider/l10n/app_strings.dart';
import 'package:toukh_ui/toukh_ui.dart';

class MenuBuilderView extends StatelessWidget {
  const MenuBuilderView({super.key});

  Future<void> _persistMenu(
    BuildContext context, {
    bool auto = false,
    bool showEmptyCategoriesWarning = true,
  }) async {
    final cubit = context.read<MenuBuilderCubit>();
    final empty = cubit.state.emptyCategories();
    if (showEmptyCategoriesWarning &&
        empty.isNotEmpty &&
        context.mounted) {
      AppSnack.show(
        context,
        message:
            '${AppStrings.Registration.emptyCategoriesWarning.tr}: ${empty.join(', ')}',
        state: AppSnackState.warning,
        icon: Icons.info_outline_rounded,
      );
    }
    try {
      await context.withAppLoading(() => cubit.saveMenu(auto: auto));
    } on MenuSaveMinimumItemsException {
      if (!auto && context.mounted) {
        AppSnack.show(
          context,
          message: AppStrings.Registration.menuMinimumItems.tr,
          state: AppSnackState.warning,
          icon: Icons.restaurant_menu_outlined,
        );
      }
      return;
    }
    if (!context.mounted) return;
    final s = context.read<AuthCubit>().state;
    if (s is AuthFailure) {
      AppSnack.show(
        context,
        message: s.message,
        state: AppSnackState.error,
        icon: Icons.error_outline_rounded,
      );
      await context.read<AuthCubit>().dismissFailure();
    }
  }

  Future<void> _showAddCategorySheet(BuildContext context) async {
    final cubit = context.read<MenuBuilderCubit>();
    final name = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => AddCategorySheet(
        existingTitles: List.of(cubit.state.categories),
      ),
    );
    if (!context.mounted) return;
    if (name == null || name.trim().isEmpty) return;
    final t = name.trim();
    if (cubit.state.categories.any((c) => c.toLowerCase() == t.toLowerCase())) {
      AppSnack.show(
        context,
        message: AppStrings.Registration.duplicateCategory.tr,
        state: AppSnackState.warning,
        icon: Icons.category_outlined,
      );
      return;
    }
    cubit.addCategory(t);
    await _persistMenu(context, auto: true, showEmptyCategoriesWarning: false);
  }

  Future<void> _renameCategory(BuildContext context, String oldName) async {
    final cubit = context.read<MenuBuilderCubit>();
    final ctrl = TextEditingController(text: oldName);
    final newName = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: CustomText(AppStrings.Registration.renameCategory),
        content: AppTextField(
          controller: ctrl,
          labelText: AppStrings.Registration.categoryName,
          textInputAction: TextInputAction.done,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: CustomText(AppStrings.Common.cancel),
          ),
          FilledButton(
            onPressed: () {
              final v = ctrl.text.trim();
              if (v.isEmpty) return;
              if (cubit.state.categories.any(
                    (c) =>
                        c.toLowerCase() == v.toLowerCase() && c != oldName,
                  )) {
                AppSnack.show(
                  ctx,
                  message: AppStrings.Registration.duplicateCategory.tr,
                  state: AppSnackState.warning,
                  icon: Icons.category_outlined,
                );
                return;
              }
              Navigator.pop(ctx, v);
            },
            child: CustomText(AppStrings.Common.save),
          ),
        ],
      ),
    );
    ctrl.dispose();
    if (!context.mounted || newName == null || newName == oldName) return;
    cubit.renameCategory(oldName, newName);
    await _persistMenu(context, auto: true, showEmptyCategoriesWarning: false);
  }

  Future<void> _deleteCategory(BuildContext context, String name) async {
    final cubit = context.read<MenuBuilderCubit>();
    final n = cubit.state.countForCategory(name);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: CustomText(AppStrings.Registration.confirmDeleteCategory),
        content: CustomText(
          n > 0
              ? '${AppStrings.Registration.confirmDeleteCategory.tr}\n'
                  '($n ${n == 1 ? 'item' : 'items'})'
              : AppStrings.Registration.confirmDeleteCategory.tr,
          style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(
                color: Theme.of(ctx).colorScheme.onSurface.withValues(alpha: 0.8),
              ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: CustomText(AppStrings.Common.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: CustomText(AppStrings.Common.delete),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    cubit.deleteCategory(name);
    await _persistMenu(context, auto: true, showEmptyCategoriesWarning: false);
  }

  Future<void> _showItemSheet(
    BuildContext context, {
    required String initialCategory,
    MenuItemEntity? existing,
  }) async {
    final cubit = context.read<MenuBuilderCubit>();
    if (cubit.state.categories.isEmpty) {
      AppSnack.show(
        context,
        message: AppStrings.Registration.addFirstCategoryHint.tr,
        state: AppSnackState.warning,
        icon: Icons.category_outlined,
      );
      return;
    }
    final merged = List<String>.from(cubit.state.categories);
    final extra = existing?.category;
    if (extra != null &&
        extra.isNotEmpty &&
        !merged.any((c) => c.toLowerCase() == extra.toLowerCase())) {
      merged.add(extra);
    }
    final ic = merged.any((c) => c == initialCategory)
        ? initialCategory
        : merged.first;

    final result = await showModalBottomSheet<MenuItemEditorResult>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => AddOrEditItemSheet(
        categories: merged,
        initialCategory: ic,
        existing: existing,
      ),
    );
    if (!context.mounted || result == null) return;

    final err = await context.withAppLoading(() async {
      return context.read<MenuBuilderCubit>().commitItemEditorResult(result);
    });
    if (!context.mounted) return;
    if (err != null) {
      AppSnack.show(
        context,
        message: err,
        state: AppSnackState.error,
        icon: Icons.cloud_upload_outlined,
      );
      return;
    }
    final s = context.read<AuthCubit>().state;
    if (s is AuthFailure) {
      AppSnack.show(
        context,
        message: s.message,
        state: AppSnackState.error,
        icon: Icons.error_outline_rounded,
      );
      await context.read<AuthCubit>().dismissFailure();
    }
  }

  Future<void> _confirmDeleteItem(
    BuildContext context,
    MenuItemEntity item,
  ) async {
    final cubit = context.read<MenuBuilderCubit>();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: CustomText(AppStrings.Registration.confirmDeleteItem),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: CustomText(AppStrings.Common.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: CustomText(AppStrings.Common.delete),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    cubit.removeItem(item.id);
    await _persistMenu(context, auto: true, showEmptyCategoriesWarning: false);
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MenuBuilderCubit, MenuBuilderState>(
      builder: (context, state) {
        return Scaffold(
          body: Column(
            children: [
              Expanded(
                child: CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: AppSizes.screenPadding,
                        child: const MenuBuilderHeaderCard(),
                      ),
                    ),
                    if (state.categories.isEmpty)
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: MenuEmptyCategoriesPlaceholder(
                          onAddCategory: () => _showAddCategorySheet(context),
                        ),
                      )
                    else ...[
                      SliverToBoxAdapter(
                        child: MenuCategoryFilterChips(
                          categories: state.categories,
                          selectedCategory: state.selectedCategory,
                          countForCategory: state.countForCategory,
                          onAllSelected: () =>
                              context.read<MenuBuilderCubit>().toggleFilterAll(),
                          onCategoryToggle: (cat) => context
                              .read<MenuBuilderCubit>()
                              .toggleFilterCategory(cat),
                          onAddCategory: () => _showAddCategorySheet(context),
                        ),
                      ),
                      SliverPadding(
                        padding: AppSizes.screenHorizontal,
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final cat = state.visibleCategories[index];
                              return Padding(
                                padding:
                                    EdgeInsets.only(bottom: AppSizes.spaceMd),
                                child: MenuCategorySectionCard(
                                  category: cat,
                                  itemCount: state.countForCategory(cat),
                                  items: state.itemsInCategory(cat),
                                  onAddItem: () => _showItemSheet(
                                    context,
                                    initialCategory: cat,
                                  ),
                                  onEditItem: (e) => _showItemSheet(
                                    context,
                                    initialCategory: cat,
                                    existing: e,
                                  ),
                                  onDeleteItem: (e) =>
                                      _confirmDeleteItem(context, e),
                                  onRenameCategory: () =>
                                      _renameCategory(context, cat),
                                  onDeleteCategory: () =>
                                      _deleteCategory(context, cat),
                                ),
                              );
                            },
                            childCount: state.visibleCategories.length,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
