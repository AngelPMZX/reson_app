import 'package:firebase_auth/firebase_auth.dart';
import '../domain/auth_repository.dart';

class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuthRepository(this._auth);
  final FirebaseAuth _auth;

  Future<void> _guard(Future<void> Function() action) async {
    try {
      await action();
    } on FirebaseAuthException catch (error) {
      throw AuthFailure(error.code);
    }
  }

  @override
  Stream<AuthIdentity?> watchSession() => _auth.userChanges().map(
    (user) => user == null
        ? null
        : AuthIdentity(
            uid: user.uid,
            email: user.email ?? '',
            name: user.displayName,
            emailVerified: user.emailVerified,
          ),
  );

  @override
  Future<void> signIn(String email, String password) => _guard(() async {
    await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  });

  @override
  Future<void> register(String name, String email, String password) =>
      _guard(() async {
        final result = await _auth.createUserWithEmailAndPassword(
          email: email.trim(),
          password: password,
        );
        await result.user!.updateDisplayName(name.trim());
      });

  @override
  Future<void> resetPassword(String email, String language) => _guard(() async {
    await _auth.setLanguageCode(language);
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (error) {
      // Do not reveal whether an address belongs to an account.
      if (error.code != 'user-not-found') rethrow;
    }
  });

  @override
  Future<void> sendVerification(String language) => _guard(() async {
    await _auth.setLanguageCode(language);
    await _auth.currentUser?.sendEmailVerification();
  });

  @override
  Future<void> refreshUser() => _guard(() async {
    await _auth.currentUser?.reload();
    await _auth.currentUser?.getIdToken(true);
  });

  @override
  Future<void> signOut() => _guard(_auth.signOut);
}
