import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:toukh_provider/domain/entities/provider_account_status.dart';
import 'package:toukh_provider/features/auth/cubit/auth_cubit.dart';
import 'package:toukh_ui/toukh_ui.dart';

enum OnboardingGate { checking, needsPermissions, ready }

class OnboardingState extends Equatable {
  const OnboardingState({required this.gate});

  final OnboardingGate gate;

  OnboardingState copyWith({OnboardingGate? gate}) =>
      OnboardingState(gate: gate ?? this.gate);

  @override
  List<Object?> get props => [gate];
}

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
      return;
    }
  }

  Future<String?> refresh() async {
    final auth = _authCubit.state;
    if (auth is! Authenticated ||
        auth.profile.status != ProviderAccountStatus.active) {
      emit(const OnboardingState(gate: OnboardingGate.checking));
      return null;
    }

    emit(const OnboardingState(gate: OnboardingGate.checking));

    try {
      final status = await readPermissionStatus().timeout(
        const Duration(seconds: 12),
        onTimeout: () {
          debugPrint('OnboardingCubit.refresh: permission read timed out');
          return const PermissionsStatus(
            notification: false,
            foregroundLocation: false,
          );
        },
      );
      if (!status.notification || !status.foregroundLocation) {
        emit(const OnboardingState(gate: OnboardingGate.needsPermissions));
        return null;
      }
      emit(const OnboardingState(gate: OnboardingGate.ready));
      await ToukhPushMessaging.instance.syncToken(
        auth.user.uid,
        existingFcmTokens: auth.profile.fcmTokens,
      );
      return null;
    } catch (e, st) {
      debugPrint('OnboardingCubit.refresh error: $e\n$st');
      emit(const OnboardingState(gate: OnboardingGate.needsPermissions));
      return e.toString();
    }
  }

  Future<PermissionsStatus> readPermissionStatus() async {
    final notification = await _isNotificationGranted();
    final foregroundLocation = await _isForegroundLocationGranted();
    return PermissionsStatus(
      notification: notification,
      foregroundLocation: foregroundLocation,
    );
  }

  Future<void> requestNotificationPermission() async {
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      return;
    }
    final s = await Permission.notification.status;
    if (!s.isGranted) {
      await Permission.notification.request();
    }
  }

  Future<void> requestForegroundLocationPermission() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      await Geolocator.openLocationSettings();
      if (!await Geolocator.isLocationServiceEnabled()) {
        return;
      }
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.deniedForever) {
      await openAppSettings();
      return;
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.unableToDetermine) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.deniedForever) {
      await openAppSettings();
    }
  }

  Future<String?> continueAfterPermissionsGranted() => refresh();

  Future<void> openSystemSettings() => openAppSettings();

  Future<bool> _isNotificationGranted() async {
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      final settings =
          await FirebaseMessaging.instance.getNotificationSettings();
      return settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional;
    }
    final status = await Permission.notification.status;
    return status.isGranted;
  }

  Future<bool> _isForegroundLocationGranted() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return false;
    final permission = await Geolocator.checkPermission();
    return permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
  }

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

  bool get allGranted => notification && foregroundLocation;

  @override
  List<Object?> get props => [notification, foregroundLocation];
}
