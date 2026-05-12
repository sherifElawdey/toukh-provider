import 'package:toukh_provider/domain/entities/home_service_category.dart';

abstract class HomeServiceCategoriesRepository {
  /// Active home-service categories (`isActive == true`).
  Stream<List<HomeServiceCategory>> watchActiveCategories();
}
