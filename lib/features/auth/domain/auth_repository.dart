class AuthIdentity {
  const AuthIdentity({
    required this.uid,
    required this.email,
    this.name,
    this.googlePhotoUrl,
    required this.emailVerified,
  });
  final String uid;
  final String email;
  final String? name;
  final String? googlePhotoUrl;
  final bool emailVerified;
}

class AuthFailure implements Exception {
  const AuthFailure(this.code);
  final String code;
}

abstract interface class AuthRepository {
  Stream<AuthIdentity?> watchSession();
  Future<void> signIn(String email, String password);
  Future<void> register(String name, String email, String password);
  Future<void> resetPassword(String email, String language);
  Future<void> sendVerification(String language);
  Future<void> refreshUser();
  Future<void> signOut();
  Future<void> signInGoogle();
}
