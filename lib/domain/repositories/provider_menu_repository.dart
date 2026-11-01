import 'package:toukh_provider/domain/entities/menu_item.dart';

class ProviderMenuSnapshot {
  const ProviderMenuSnapshot({required this.categories, required this.items});

  final List<String> categories;
  final List<MenuItemEntity> items;
}

abstract class ProviderMenuRepository {
  /// Live menu categories (including empty) and all items.
  Stream<ProviderMenuSnapshot> watchMenu(String providerId);

  Future<void> upsertItem(String providerId, MenuItemEntity item);

  Future<void> deleteItem(String providerId, MenuItemEntity item);

  Future<void> upsertCategory(String providerId, String displayName);

  Future<void> deleteCategory(String providerId, String displayName);

  Future<void> renameCategory(
    String providerId,
    String oldDisplayName,
    String newDisplayName,
  );

  /// Saves the category order ([displayNames] first to last).
  Future<void> reorderCategories(String providerId, List<String> displayNames);

  /// Saves the item order inside [category] ([itemIds] first to last).
  Future<void> reorderItems(
    String providerId,
    String category,
    List<String> itemIds,
  );

  Future<bool> hasAnyItems(String providerId);

  /// Writes legacy profile [menuItems] into Menu subcollection when Menu is empty.
  Future<void> migrateFromProfileArrayIfNeeded(
    String providerId,
    List<MenuItemEntity>? legacyItems,
  );
}
