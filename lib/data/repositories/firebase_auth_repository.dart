import 'package:firebase_auth/firebase_auth.dart';
import 'package:toukh_provider/core/utils/phone_auth_helpers.dart';
import 'package:toukh_provider/domain/repositories/auth_repository.dart';

class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuthRepository(this._auth);

  final FirebaseAuth _auth;

  @override
  Stream<User?> authStateChanges() => _auth.authStateChanges();

  @override
  User? get currentUser => _auth.currentUser;

  @override
  Future<UserCredential> registerWithPhonePassword({
    required String phone,
    required String password,
  }) {
    final email = syntheticEmailFromPhone(phone);
    return _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  @override
  Future<UserCredential> signInWithPhonePassword({
    required String phone,
    required String password,
  }) {
    final email = syntheticEmailFromPhone(phone);
    return _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  @override
  Future<void> signOut() => _auth.signOut();

  @override
  Future<void> deleteAccount() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('No signed-in user');
    }
    await user.delete();
  }
}
