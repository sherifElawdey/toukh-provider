import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// Resolves a Firebase error message key to a localized string.
typedef FirebaseErrorLocalizer = String Function(
  String key, {
  Map<String, String> params,
});

/// Stable l10n keys for Firebase-related user messages.
abstract final class FirebaseErrorKeys {
  FirebaseErrorKeys._();

  static const unknown = 'firebase.errors.unknown';
  static const signInAgain = 'firebase.errors.sign_in_again';
  static const permissionDenied = 'firebase.errors.permission_denied';
  static const network = 'firebase.errors.network';
  static const tryAgain = 'firebase.errors.try_again';
  static const serviceUnavailable = 'firebase.errors.service_unavailable';
  static const actionNotAllowed = 'firebase.errors.action_not_allowed';
  static const authInvalidCredentials =
      'firebase.errors.auth_invalid_credentials';
  static const authEmailInUse = 'firebase.errors.auth_email_in_use';
  static const authTooManyRequests = 'firebase.errors.auth_too_many_requests';
  static const authRequiresRecentLogin =
      'firebase.errors.auth_requires_recent_login';
  static const indexBuilding = 'firebase.errors.index_building';
}

const _englishDefaults = <String, String>{
  FirebaseErrorKeys.unknown: 'Something went wrong. Please try again.',
  FirebaseErrorKeys.signInAgain: 'Please sign in again.',
  FirebaseErrorKeys.permissionDenied: "You don't have permission to do that.",
  FirebaseErrorKeys.network: 'Check your connection and try again.',
  FirebaseErrorKeys.tryAgain:
      'Service temporarily unavailable. Try again.',
  FirebaseErrorKeys.serviceUnavailable:
      'Service is unavailable right now.',
  FirebaseErrorKeys.actionNotAllowed:
      "This action isn't allowed right now.",
  FirebaseErrorKeys.authInvalidCredentials: 'Incorrect phone number or password.',
  FirebaseErrorKeys.authEmailInUse: 'This phone number is already registered.',
  FirebaseErrorKeys.authTooManyRequests:
      'Too many attempts. Try again later.',
  FirebaseErrorKeys.authRequiresRecentLogin: 'Sign in again to continue.',
  FirebaseErrorKeys.indexBuilding: 'Data is still loading. Try again shortly.',
};

/// Logs full Firebase error details to the console (debug/profile builds).
void logFirebaseError(String context, Object error, [StackTrace? stackTrace]) {
  debugPrint('════════ Firebase error [$context] ════════');
  debugPrint('type: ${error.runtimeType}');
  debugPrint('error: $error');

  if (error is FirebaseFunctionsException) {
    debugPrint('functions.code: ${error.code}');
    debugPrint('functions.message: ${error.message}');
    debugPrint('functions.details: ${error.details}');
  } else if (error is FirebaseException) {
    debugPrint('firebase.code: ${error.code}');
    debugPrint('firebase.message: ${error.message}');
  } else if (error is FirebaseAuthException) {
    debugPrint('auth.code: ${error.code}');
    debugPrint('auth.message: ${error.message}');
  }

  if (stackTrace != null) {
    debugPrint('stackTrace:\n$stackTrace');
  }
  debugPrint('══════════════════════════════════════════');
}

/// User-facing message for Firebase and common wrapped errors.
String firebaseUserMessage(
  Object error, {
  FirebaseErrorLocalizer? localize,
  String unknownKey = FirebaseErrorKeys.unknown,
}) {
  final resolved = _resolveMessage(error, unknownKey: unknownKey);
  if (localize != null) {
    return localize(resolved.key, params: const {});
  }
  if (resolved.serverMessage != null) {
    return resolved.serverMessage!;
  }
  return _englishDefaults[resolved.key] ??
      _englishDefaults[FirebaseErrorKeys.unknown]!;
}

class _ResolvedFirebaseMessage {
  const _ResolvedFirebaseMessage({
    required this.key,
    this.serverMessage,
  });

  final String key;
  final String? serverMessage;
}

_ResolvedFirebaseMessage _resolveMessage(
  Object error, {
  required String unknownKey,
}) {
  if (error is FirebaseFunctionsException) {
    return _functionsMessage(error);
  }
  if (error is FirebaseAuthException) {
    return _authMessage(error);
  }
  if (error is FirebaseException) {
    return _firestoreMessage(error);
  }

  final text = error.toString();
  if (text.contains('FAILED_PRECONDITION') &&
      (text.contains('requires an index') || text.contains('index'))) {
    return const _ResolvedFirebaseMessage(key: FirebaseErrorKeys.indexBuilding);
  }

  return _ResolvedFirebaseMessage(key: unknownKey);
}

_ResolvedFirebaseMessage _authMessage(FirebaseAuthException e) {
  switch (e.code) {
    case 'wrong-password':
    case 'invalid-credential':
    case 'user-not-found':
    case 'invalid-email':
    case 'invalid-phone-number':
      return const _ResolvedFirebaseMessage(
        key: FirebaseErrorKeys.authInvalidCredentials,
      );
    case 'email-already-in-use':
    case 'account-exists-with-different-credential':
      return const _ResolvedFirebaseMessage(
        key: FirebaseErrorKeys.authEmailInUse,
      );
    case 'too-many-requests':
      return const _ResolvedFirebaseMessage(
        key: FirebaseErrorKeys.authTooManyRequests,
      );
    case 'network-request-failed':
      return const _ResolvedFirebaseMessage(key: FirebaseErrorKeys.network);
    case 'requires-recent-login':
      return const _ResolvedFirebaseMessage(
        key: FirebaseErrorKeys.authRequiresRecentLogin,
      );
    case 'user-disabled':
      return const _ResolvedFirebaseMessage(
        key: FirebaseErrorKeys.actionNotAllowed,
      );
    default:
      final safe = _safeServerMessage(e.message);
      if (safe != null) {
        return _ResolvedFirebaseMessage(
          key: FirebaseErrorKeys.unknown,
          serverMessage: safe,
        );
      }
      return const _ResolvedFirebaseMessage(key: FirebaseErrorKeys.unknown);
  }
}

_ResolvedFirebaseMessage _functionsMessage(FirebaseFunctionsException e) {
  switch (e.code) {
    case 'unauthenticated':
      return const _ResolvedFirebaseMessage(key: FirebaseErrorKeys.signInAgain);
    case 'permission-denied':
      return const _ResolvedFirebaseMessage(
        key: FirebaseErrorKeys.permissionDenied,
      );
    case 'unavailable':
    case 'deadline-exceeded':
      return const _ResolvedFirebaseMessage(key: FirebaseErrorKeys.tryAgain);
    case 'not-found':
    case 'internal':
      return const _ResolvedFirebaseMessage(
        key: FirebaseErrorKeys.serviceUnavailable,
      );
    case 'failed-precondition':
    case 'invalid-argument':
      final safe = _safeServerMessage(e.message);
      if (safe != null) {
        return _ResolvedFirebaseMessage(
          key: FirebaseErrorKeys.actionNotAllowed,
          serverMessage: safe,
        );
      }
      return const _ResolvedFirebaseMessage(
        key: FirebaseErrorKeys.actionNotAllowed,
      );
    default:
      final safe = _safeServerMessage(e.message);
      if (safe != null) {
        return _ResolvedFirebaseMessage(
          key: FirebaseErrorKeys.unknown,
          serverMessage: safe,
        );
      }
      return const _ResolvedFirebaseMessage(key: FirebaseErrorKeys.unknown);
  }
}

_ResolvedFirebaseMessage _firestoreMessage(FirebaseException e) {
  final raw = e.message ?? '';
  if (e.code == 'failed-precondition' &&
      (raw.contains('index') || raw.contains('FAILED_PRECONDITION'))) {
    return const _ResolvedFirebaseMessage(key: FirebaseErrorKeys.indexBuilding);
  }

  switch (e.code) {
    case 'permission-denied':
      return const _ResolvedFirebaseMessage(
        key: FirebaseErrorKeys.permissionDenied,
      );
    case 'unavailable':
      return const _ResolvedFirebaseMessage(key: FirebaseErrorKeys.network);
    default:
      final safe = _safeServerMessage(e.message);
      if (safe != null) {
        return _ResolvedFirebaseMessage(
          key: FirebaseErrorKeys.unknown,
          serverMessage: safe,
        );
      }
      return const _ResolvedFirebaseMessage(key: FirebaseErrorKeys.unknown);
  }
}

String? _safeServerMessage(String? raw) {
  if (raw == null) return null;
  final trimmed = raw.trim();
  if (trimmed.isEmpty || trimmed.length > 120) return null;

  final lower = trimmed.toLowerCase();
  if (lower.contains('httpserror') ||
      lower.contains('stack') ||
      lower.contains('exception') ||
      lower.contains('firebasefunctions') ||
      lower.contains('internal error') && trimmed.length < 20) {
    return null;
  }

  return trimmed;
}
