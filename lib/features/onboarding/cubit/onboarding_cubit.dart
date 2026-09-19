import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:toukh_provider/core/firebase/app_firebase_errors.dart';
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

  /// Legacy permanent skip key — cleared on each [refresh] so we re-prompt
  /// once per cold start while permission remains denied.
  static const notificationsPromptSkippedKey = 'notifications_prompt_skipped';

  final AuthCubit _authCubit;
  StreamSubscription<AuthState>? _authSub;
  AuthState? _priorAuthForGate;

  /// Session-only skips: cleared when the cubit is created (cold start).
  bool _sessionNotificationsSkipped = false;
  bool _sessionLocationSkipped = false;

  bool get sessionNotificationsSkipped => _sessionNotificationsSkipped;
  bool get sessionLocationSkipped => _sessionLocationSkipped;

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

    // Drop any permanent skip from older builds so deny never hard-blocks.
    await _clearLegacyPermanentSkip();

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

      final needsNotif =
          !status.notification && !_sessionNotificationsSkipped;
      final needsLocation =
          !status.foregroundLocation && !_sessionLocationSkipped;

      if (needsNotif || needsLocation) {
        emit(const OnboardingState(gate: OnboardingGate.needsPermissions));
        return null;
      }

      emit(const OnboardingState(gate: OnboardingGate.ready));
      if (status.notification) {
        await ToukhPushMessaging.instance.syncToken(
          auth.user.uid,
          existingFcmTokens: auth.profile.fcmTokens,
        );
      }
      return null;
    } catch (e, st) {
      debugPrint('OnboardingCubit.refresh error: $e\n$st');
      emit(const OnboardingState(gate: OnboardingGate.needsPermissions));
      return appFirebaseError(e);
    }
  }

  Future<void> _clearLegacyPermanentSkip() async {
    try {
      final p = await SharedPreferences.getInstance();
      if (p.containsKey(notificationsPromptSkippedKey)) {
        await p.remove(notificationsPromptSkippedKey);
      }
    } catch (e, st) {
      debugPrint('OnboardingCubit._clearLegacyPermanentSkip: $e\n$st');
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

  /// Whether notifications are currently granted (for feature gates).
  Future<bool> isNotificationGranted() => _isNotificationGranted();

  /// Whether foreground location is currently granted (for feature gates).
  Future<bool> isForegroundLocationGranted() =>
      _isForegroundLocationGranted();

  Future<void> requestNotificationPermission() async {
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      final settings =
          await FirebaseMessaging.instance.getNotificationSettings();
      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        await openAppSettings();
        return;
      }
      await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      return;
    }
    final status = await Permission.notification.status;
    if (status.isGranted) return;
    if (status.isPermanentlyDenied || status.isRestricted) {
      await openAppSettings();
      return;
    }
    final result = await Permission.notification.request();
    if (!result.isGranted &&
        (result.isPermanentlyDenied || result.isRestricted)) {
      await openAppSettings();
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

  /// Session skip for the soft permissions prompt (Not now / system deny).
  Future<String?> skipPermissionsPrompt({
    bool notifications = true,
    bool location = true,
  }) async {
    if (notifications) _sessionNotificationsSkipped = true;
    if (location) _sessionLocationSkipped = true;
    return refresh();
  }

  /// @deprecated Prefer [skipPermissionsPrompt]. Kept for call-site clarity.
  Future<String?> skipNotificationsPrompt() => skipPermissionsPrompt();

  /// After Enable: if still denied, treat like skip so the user is not stuck.
  Future<String?> continueAfterNotificationRequest() async {
    final granted = await _isNotificationGranted();
    if (!granted) {
      _sessionNotificationsSkipped = true;
    }
    return refresh();
  }

  Future<String?> continueAfterLocationRequest() async {
    final granted = await _isForegroundLocationGranted();
    if (!granted) {
      _sessionLocationSkipped = true;
    }
    return refresh();
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

  bool get notificationsReady => notification;

  @override
  List<Object?> get props => [notification, foregroundLocation];
}
