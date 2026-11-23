import 'package:firebase_auth/firebase_auth.dart';

abstract class AuthRepository {
  Stream<User?> authStateChanges();

  User? get currentUser;

  Future<UserCredential> signInWithPhonePassword({
    required String phone,
    required String password,
  });

  Future<UserCredential> registerWithPhonePassword({
    required String phone,
    required String password,
  });

  Future<void> signOut();

  Future<void> deleteAccount();

  /// Checks [currentPassword] by signing in again, then sets [newPassword].
  /// Throws [FirebaseAuthException] (`wrong-password` / `invalid-credential`)
  /// when the current password is wrong.
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  });
}
