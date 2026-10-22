import 'package:toukh_ui/toukh_ui.dart';

/// Read-only access to the admin-managed produce / grocery master catalog.
abstract class GroceryCatalogRepository {
  /// Products admins have switched on, sorted by category then sort order.
  Stream<List<GroceryCatalogProduct>> watchActive();

  /// One product by id, or null if admins deleted it.
  Future<GroceryCatalogProduct?> getById(String id);
}
