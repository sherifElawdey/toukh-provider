import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:toukh_provider/features/auth/cubit/auth_cubit.dart';

class GoRouterAuthRefresh extends ChangeNotifier {
  GoRouterAuthRefresh(AuthCubit authCubit) {
    _last = authCubit.state;
    _sub = authCubit.stream.listen(_onAuth);
    notifyListeners();
  }

  late AuthState _last;
  StreamSubscription<AuthState>? _sub;

  void _onAuth(AuthState next) {
    if (_shouldRefreshRouter(_last, next)) {
      notifyListeners();
    }
    _last = next;
  }

  static bool _shouldRefreshRouter(AuthState prev, AuthState next) {
    if (prev.runtimeType != next.runtimeType) return true;

    return switch (next) {
      Authenticated() => _authenticatedGateChanged(
          prev as Authenticated,
          next,
        ),
      AuthenticatedNoProfile(:final user) =>
        prev is AuthenticatedNoProfile && prev.user.uid != user.uid,
      AuthFailure(:final message) =>
        prev is AuthFailure && prev.message != message,
      _ => false,
    };
  }

  static bool _authenticatedGateChanged(
    Authenticated prev,
    Authenticated next,
  ) {
    if (prev.user.uid != next.user.uid) return true;
    if (prev.profile.status != next.profile.status) return true;
    if (prev.profile.phoneVerified != next.profile.phoneVerified) return true;
    if (prev.profile.registrationExtrasComplete !=
        next.profile.registrationExtrasComplete) {
      return true;
    }
    return false;
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
