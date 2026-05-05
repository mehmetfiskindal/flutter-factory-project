import 'package:dio/dio.dart';

import '../../../../core/network/api_interceptor.dart';
import '../models/auth_user_model.dart';

class AuthSession {
  const AuthSession({
    required this.user,
    required this.accessToken,
    required this.refreshToken,
  });

  final AuthUserModel user;
  final String accessToken;
  final String refreshToken;
}

abstract interface class AuthRemoteDataSource {
  Future<AuthSession> signIn({
    required String email,
    required String password,
  });
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  const AuthRemoteDataSourceImpl(this._client);

  final Dio _client;

  @override
  Future<AuthSession> signIn({
    required String email,
    required String password,
  }) async {
    final response = await _client.post<Map<String, dynamic>>(
      '/auth/login',
      data: {
        'email': email,
        'password': password,
      },
      options: Options(extra: {ApiInterceptor.skipAuthKey: true}),
    );
    final data = response.data;

    if (data == null) {
      throw StateError('Empty auth response.');
    }

    return AuthSession(
      user: AuthUserModel.fromJson(data['user'] as Map<String, dynamic>),
      accessToken: data['accessToken'] as String,
      refreshToken: data['refreshToken'] as String,
    );
  }
}
