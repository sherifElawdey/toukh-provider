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
}
