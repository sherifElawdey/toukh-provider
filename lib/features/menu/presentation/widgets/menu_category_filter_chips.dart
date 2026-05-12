import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:toukh_provider/l10n/app_strings.dart';
import 'package:toukh_ui/toukh_ui.dart';

class MenuCategoryFilterChips extends StatelessWidget {
  const MenuCategoryFilterChips({
    super.key,
    required this.categories,
    required this.selectedCategory,
    required this.countForCategory,
    required this.onAllSelected,
    required this.onCategoryToggle,
    required this.onAddCategory,
  });

  final List<String> categories;
  final String? selectedCategory;
  final int Function(String cat) countForCategory;
  final VoidCallback onAllSelected;
  final void Function(String cat) onCategoryToggle;
  final VoidCallback onAddCategory;

  static const double _chipHeight = 52;

  TextStyle? _chipLabelStyle(
    BuildContext context, {
    required bool selected,
  }) {
    final base = Theme.of(context).textTheme.labelLarge;
    return base?.copyWith(
      color: selected ? Colors.white : Theme.of(context).colorScheme.onSurface,
      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _chipHeight,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: AppSizes.screenHorizontal.copyWith(bottom: AppSizes.spaceSm),
        itemCount: categories.length + 2,
        separatorBuilder: (_, _) => SizedBox(width: AppSizes.spaceSm),
        itemBuilder: (context, index) {
          if (index == 0) {
            final allSelected = selectedCategory == null;
            return ChoiceChip(
              showCheckmark: true,
              checkmarkColor: Colors.white,
              selectedColor: AppColors.appColor,
              label: Text(AppStrings.Registration.menuAllCategories.tr),
              labelStyle: _chipLabelStyle(context, selected: allSelected),
              selected: allSelected,
              onSelected: (_) => onAllSelected(),
              side: BorderSide.none,
              backgroundColor:
                  Theme.of(context).colorScheme.surfaceContainerHighest,
            );
          }
          if (index == categories.length + 1) {
            return ActionChip(
              avatar: const Icon(Icons.add, size: 18),
              label: CustomText(AppStrings.Registration.addCategory),
              onPressed: onAddCategory,
              side: BorderSide.none,
            );
          }
          final cat = categories[index - 1];
          final n = countForCategory(cat);
          final selected = selectedCategory == cat;
          return ChoiceChip(
            showCheckmark: true,
            checkmarkColor: Colors.white,
            selectedColor: AppColors.appColor,
            label: Text(cat, overflow: TextOverflow.ellipsis),
            labelStyle: _chipLabelStyle(context, selected: selected),
            selected: selected,
            onSelected: (_) => onCategoryToggle(cat),
            side: BorderSide.none,
            backgroundColor:
                Theme.of(context).colorScheme.surfaceContainerHighest,
            avatar: selected
                ? CircleAvatar(
                    backgroundColor: Colors.white.withValues(alpha: 0.25),
                    child: CustomText(
                      '$n',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  )
                : CircleAvatar(
                    backgroundColor:
                        AppColors.appColor.withValues(alpha: 0.2),
                    child: CustomText(
                      '$n',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
          );
        },
      ),
    );
  }
}
