{{#is_rest_backend}}import '../../../../core/network/token_storage.dart';
import '../../domain/entities/auth_user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';

class AuthRepositoryImpl implements AuthRepository {
  const AuthRepositoryImpl({
    required AuthRemoteDataSource remoteDataSource,
    required TokenStorage tokenStorage,
  })  : _remoteDataSource = remoteDataSource,
        _tokenStorage = tokenStorage;

  final AuthRemoteDataSource _remoteDataSource;
  final TokenStorage _tokenStorage;

  @override
  Future<AuthUser?> currentUser() async {
    final accessToken = _tokenStorage.readAccessToken();
    if (accessToken == null || accessToken.isEmpty) {
      return null;
    }

    return const AuthUser(
      id: 'cached-user',
      email: 'cached@example.com',
      displayName: 'Cached User',
    );
  }

  @override
  Future<AuthUser> signIn({
    required String email,
    required String password,
  }) async {
    final session = await _remoteDataSource.signIn(
      email: email,
      password: password,
    );

    await _tokenStorage.saveTokens(
      accessToken: session.accessToken,
      refreshToken: session.refreshToken,
    );

    return session.user;
  }

  @override
  Future<void> signOut() {
    return _tokenStorage.clearTokens();
  }
}
{{/is_rest_backend}}{{#is_firebase_backend}}import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;

import '../../domain/entities/auth_user.dart';
import '../../domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  const AuthRepositoryImpl({
    required firebase_auth.FirebaseAuth firebaseAuth,
  }) : _firebaseAuth = firebaseAuth;

  final firebase_auth.FirebaseAuth _firebaseAuth;

  @override
  Future<AuthUser?> currentUser() async {
    return _firebaseAuth.currentUser?.toDomain();
  }

  @override
  Future<AuthUser> signIn({
    required String email,
    required String password,
  }) async {
    final credential = await _firebaseAuth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    final user = credential.user;
    if (user == null) {
      throw StateError('Firebase Auth did not return a user.');
    }

    return user.toDomain();
  }

  @override
  Future<void> signOut() {
    return _firebaseAuth.signOut();
  }
}

extension on firebase_auth.User {
  AuthUser toDomain() {
    return AuthUser(
      id: uid,
      email: email ?? '',
      displayName: displayName,
    );
  }
}
{{/is_firebase_backend}}
