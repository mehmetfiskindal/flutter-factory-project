import '../entities/auth_user.dart';

abstract interface class AuthRepository {
  Future<AuthUser?> currentUser();

  {{#is_firebase_backend}}Stream<AuthUser?> authStateChanges();

  Future<AuthUser> createAccount({
    required String email,
    required String password,
  });

  Future<void> sendPasswordResetEmail({
    required String email,
  });

  {{/is_firebase_backend}}

  Future<AuthUser> signIn({
    required String email,
    required String password,
  });

  Future<void> signOut();
}
