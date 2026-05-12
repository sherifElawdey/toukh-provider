import 'package:equatable/equatable.dart';
import 'package:toukh_provider/domain/entities/menu_item.dart';

class MenuBuilderState extends Equatable {
  const MenuBuilderState({
    required this.categories,
    required this.items,
    this.selectedCategory,
    this.seededFromProfile = false,
  });

  final List<String> categories;
  final List<MenuItemEntity> items;
  final String? selectedCategory;
  final bool seededFromProfile;

  static const empty = MenuBuilderState(categories: [], items: []);

  int countForCategory(String cat) =>
      items.where((e) => e.category == cat).length;

  List<MenuItemEntity> itemsInCategory(String cat) =>
      items.where((e) => e.category == cat).toList();

  List<String> emptyCategories() =>
      categories.where((c) => countForCategory(c) == 0).toList();

  List<String> get visibleCategories {
    final selected = selectedCategory;
    if (selected == null) return categories;
    if (categories.contains(selected)) return [selected];
    return categories;
  }

  MenuBuilderState copyWith({
    List<String>? categories,
    List<MenuItemEntity>? items,
    String? selectedCategory,
    bool clearSelectedCategory = false,
    bool updateSelectedCategory = false,
    bool? seededFromProfile,
  }) {
    final String? nextSelected;
    if (clearSelectedCategory) {
      nextSelected = null;
    } else if (updateSelectedCategory) {
      nextSelected = selectedCategory;
    } else {
      nextSelected = this.selectedCategory;
    }
    return MenuBuilderState(
      categories: categories ?? this.categories,
      items: items ?? this.items,
      selectedCategory: nextSelected,
      seededFromProfile: seededFromProfile ?? this.seededFromProfile,
    );
  }

  @override
  List<Object?> get props =>
      [categories, items, selectedCategory, seededFromProfile];
}
