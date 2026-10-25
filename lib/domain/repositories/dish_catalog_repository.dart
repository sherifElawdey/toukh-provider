import 'package:toukh_ui/toukh_ui.dart';

/// Read-only access to the admin-managed dishes & desserts library.
abstract class DishCatalogRepository {
  /// Dishes admins have switched on, sorted by section then sort order.
  Stream<List<DishCatalogProduct>> watchActive();
}
