import 'package:toukh_provider/shared/shared.dart';

abstract class AppSettingsRepository {
  Stream<OrderAcceptanceSla> watchAcceptanceSla();
}
