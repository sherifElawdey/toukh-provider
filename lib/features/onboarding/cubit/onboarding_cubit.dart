import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:toukh_provider/domain/entities/provider_account_status.dart';
import 'package:toukh_provider/features/auth/cubit/auth_cubit.dart';

enum OnboardingGate { checking, needsPermissions, ready }

class OnboardingState extends Equatable {
  const OnboardingState({required this.gate});

  final OnboardingGate gate;

  OnboardingState copyWith({OnboardingGate? gate}) =>
      OnboardingState(gate: gate ?? this.gate);

  @override
  List<Object?> get props => [gate];
}

/// Permissions skipped; active providers go [ready] immediately.
class OnboardingCubit extends Cubit<OnboardingState> {
  OnboardingCubit(this._authCubit)
      : super(const OnboardingState(gate: OnboardingGate.checking)) {
    _authSub = _authCubit.stream.listen(_onAuthState);
    _onAuthState(_authCubit.state);
  }

  final AuthCubit _authCubit;
  StreamSubscription<AuthState>? _authSub;
  AuthState? _priorAuthForGate;

  void _onAuthState(AuthState state) {
    final prev = _priorAuthForGate;
    _priorAuthForGate = state;

    if (state is! Authenticated ||
        state.profile.status != ProviderAccountStatus.active) {
      emit(const OnboardingState(gate: OnboardingGate.checking));
      return;
    }

    final auth = state;
    final wasSameActive = prev is Authenticated &&
        prev.user.uid == auth.user.uid &&
        prev.profile.status == ProviderAccountStatus.active;

    if (!wasSameActive) {
      unawaited(refresh());
    }
  }

  Future<String?> refresh() async {
    final auth = _authCubit.state;
    if (auth is! Authenticated ||
        auth.profile.status != ProviderAccountStatus.active) {
      emit(const OnboardingState(gate: OnboardingGate.checking));
      return null;
    }
    emit(const OnboardingState(gate: OnboardingGate.ready));
    return null;
  }

  Future<PermissionsStatus> readPermissionStatus() async {
    return const PermissionsStatus(
      notification: true,
      foregroundLocation: true,
    );
  }

  Future<bool> isNotificationGranted() async => true;
  Future<bool> isForegroundLocationGranted() async => true;

  Future<void> requestNotificationPermission() async {}
  Future<void> requestForegroundLocationPermission() async {}

  Future<String?> skipPermissionsPrompt({
    bool notifications = true,
    bool location = true,
  }) =>
      refresh();

  Future<String?> skipNotificationsPrompt() => skipPermissionsPrompt();
  Future<String?> continueAfterNotificationRequest() => refresh();
  Future<String?> continueAfterLocationRequest() => refresh();
  Future<String?> continueAfterPermissionsGranted() => refresh();
  Future<void> openSystemSettings() async {}

  @override
  Future<void> close() {
    _authSub?.cancel();
    return super.close();
  }
}

class PermissionsStatus extends Equatable {
  const PermissionsStatus({
    required this.notification,
    required this.foregroundLocation,
  });

  final bool notification;
  final bool foregroundLocation;

  bool get notificationsReady => notification;

  @override
  List<Object?> get props => [notification, foregroundLocation];
}
