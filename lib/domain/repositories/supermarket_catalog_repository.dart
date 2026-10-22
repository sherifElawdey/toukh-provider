import 'package:toukh_ui/toukh_ui.dart';

/// Read-only access to the admin-managed packaged supermarket catalog.
abstract class SupermarketCatalogRepository {
  /// Products admins show, sorted by aisle, sort order, brand, then name.
  Stream<List<SupermarketCatalogProduct>> watchActive();

  /// One product by id, or null if admins deleted it.
  Future<SupermarketCatalogProduct?> getById(String id);
}
