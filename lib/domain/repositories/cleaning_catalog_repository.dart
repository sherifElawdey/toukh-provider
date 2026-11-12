import 'package:toukh_ui/toukh_ui.dart';

/// Read-only access to the admin-managed cleaning products catalog.
abstract class CleaningCatalogRepository {
  /// Products admins show, sorted by category, sort order, brand, then name.
  Stream<List<CleaningCatalogProduct>> watchActive();

  /// One product by id, or null if admins deleted it.
  Future<CleaningCatalogProduct?> getById(String id);
}
