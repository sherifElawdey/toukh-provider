import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

class ProviderNotificationBadgeState extends Equatable {
  const ProviderNotificationBadgeState({this.notificationCount = 0});

  final int notificationCount;

  @override
  List<Object?> get props => [notificationCount];
}

class ProviderNotificationBadgeCubit extends Cubit<ProviderNotificationBadgeState> {
  ProviderNotificationBadgeCubit() : super(const ProviderNotificationBadgeState());

  void setNotificationCount(int value) =>
      emit(ProviderNotificationBadgeState(notificationCount: value));
}
