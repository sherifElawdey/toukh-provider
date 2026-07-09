import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:toukh_provider/domain/repositories/app_settings_repository.dart';
import 'package:toukh_ui/toukh_ui.dart';

class OrderAcceptanceSlaCubit extends Cubit<OrderAcceptanceSla> {
  OrderAcceptanceSlaCubit(this._repository)
      : super(OrderAcceptanceSla.defaults) {
    _subscription = _repository.watchAcceptanceSla().listen(emit);
  }

  final AppSettingsRepository _repository;
  StreamSubscription<OrderAcceptanceSla>? _subscription;

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
