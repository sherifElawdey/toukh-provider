import 'package:toukh_ui/toukh_ui.dart';

abstract class AppSettingsRepository {
  Stream<OrderAcceptanceSla> watchAcceptanceSla();
}
