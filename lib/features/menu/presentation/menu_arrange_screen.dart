import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:toukh_provider/features/menu/presentation/cubit/menu_builder_cubit.dart';
import 'package:toukh_provider/features/menu/presentation/cubit/menu_builder_state.dart';
import 'package:toukh_provider/l10n/app_strings.dart';
import 'package:toukh_ui/toukh_ui.dart';

/// Opens the category order screen; tap a category there for its items.
Future<void> openMenuArrange(BuildContext context) =>
    _push(context, const MenuArrangeScreen());

/// Opens the item order of one category.
Future<void> openMenuArrangeItems(BuildContext context, String category) =>
    _push(context, MenuArrangeItemsScreen(category: category));

Future<void> _push(BuildContext context, Widget screen) {
  final cubit = context.read<MenuBuilderCubit>();
  return Navigator.of(context).push<void>(
    MaterialPageRoute(
      builder: (_) => BlocProvider.value(value: cubit, child: screen),
    ),
  );
}

void _showError(BuildContext context, String? error) {
  if (error == null || !context.mounted) return;
  AppSnack.show(
    context,
    message: error,
    state: AppSnackState.error,
    icon: ToukhIcons.error,
  );
}

/// Shared layout: hint above a list with a drag handle on each row.
class _ArrangeScaffold extends StatelessWidget {
  const _ArrangeScaffold({
    required this.title,
    required this.hint,
    required this.keys,
    required this.rowBuilder,
    required this.onReorder,
  });

  final String title;
  final String hint;
  final List<String> keys;
  final Widget Function(BuildContext, int index) rowBuilder;
  final void Function(int from, int to) onReorder;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: CustomText(title),
        leading: IconButton(
          icon: Icon(ToukhIcons.back),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: AppSizes.screenPadding.copyWith(bottom: AppSizes.spaceSm),
            child: CustomText(
              hint,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: ReorderableListView.builder(
              buildDefaultDragHandles: false,
              padding: AppSizes.screenHorizontal,
              itemCount: keys.length,
              onReorder: onReorder,
              itemBuilder: (context, i) => KeyedSubtree(
                key: ValueKey(keys[i]),
                child: Padding(
                  padding: const EdgeInsets.only(bottom: AppSizes.spaceSm),
                  child: Material(
                    color: scheme.surface,
                    borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                    clipBehavior: Clip.antiAlias,
                    child: rowBuilder(context, i),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DragHandle extends StatelessWidget {
  const _DragHandle(this.index);

  final int index;

  @override
  Widget build(BuildContext context) {
    return ReorderableDragStartListener(
      index: index,
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.spaceSm),
        child: Icon(
          PhosphorIconsRegular.dotsSixVertical,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

class MenuArrangeScreen extends StatelessWidget {
  const MenuArrangeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MenuBuilderCubit, MenuBuilderState>(
      builder: (context, state) => _ArrangeScaffold(
        title: AppStrings.Registration.menuArrange,
        hint: AppStrings.Registration.menuArrangeHint,
        keys: state.categories,
        onReorder: (from, to) async {
          final error = await context.read<MenuBuilderCubit>().moveCategory(from, to);
          if (context.mounted) _showError(context, error);
        },
        rowBuilder: (context, i) {
          final category = state.categories[i];
          return ListTile(
            contentPadding: const EdgeInsetsDirectional.only(end: AppSizes.spaceSm),
            leading: _DragHandle(i),
            title: CustomText(category, fontWeight: FontWeight.w700),
            subtitle: CustomText(
              AppStrings.Catalog.itemsCount.trParams({
                'count': '${state.countForCategory(category)}',
              }),
            ),
            trailing: Icon(ToukhIcons.chevronRight),
            onTap: () => openMenuArrangeItems(context, category),
          );
        },
      ),
    );
  }
}

class MenuArrangeItemsScreen extends StatelessWidget {
  const MenuArrangeItemsScreen({super.key, required this.category});

  final String category;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MenuBuilderCubit, MenuBuilderState>(
      builder: (context, state) {
        final items = state.itemsInCategory(category);
        return _ArrangeScaffold(
          title: category,
          hint: AppStrings.Registration.menuArrangeItemsHint,
          keys: [for (final e in items) e.id],
          onReorder: (from, to) async {
            final error = await context.read<MenuBuilderCubit>().moveItem(category, from, to);
            if (context.mounted) _showError(context, error);
          },
          rowBuilder: (context, i) => ListTile(
            contentPadding: const EdgeInsetsDirectional.only(end: AppSizes.spaceSm),
            leading: _DragHandle(i),
            title: CustomText(items[i].name, maxLines: 1),
          ),
        );
      },
    );
  }
}
