import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:toukh_provider/domain/repositories/app_settings_repository.dart';
import 'package:toukh_ui/toukh_ui.dart';

/// Admin-set wait for a courier to accept before the store can re-request
/// (`dispatchSettings.storeDriverSearchTimeoutMin`). Also keeps
/// [DriverSearchWindow.current] in step for the order models.
class DriverSearchTimeoutCubit extends Cubit<Duration> {
  DriverSearchTimeoutCubit(this._repository)
      : super(DriverSearchWindow.current) {
    _subscription = _repository.watchDispatchSettings().listen((settings) {
      final timeout = settings.storeDriverSearchTimeout;
      DriverSearchWindow.current = timeout;
      emit(timeout);
    });
  }

  final AppSettingsRepository _repository;
  StreamSubscription<DispatchSettings>? _subscription;

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
