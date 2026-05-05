import 'package:dio/dio.dart';

import '../../../../core/network/api_interceptor.dart';
import '../../../../core/network/token_storage.dart';

class AuthTokenRefresherImpl implements AuthTokenRefresher {
  const AuthTokenRefresherImpl({
    required Dio client,
    required TokenStorage tokenStorage,
  })  : _client = client,
        _tokenStorage = tokenStorage;

  final Dio _client;
  final TokenStorage _tokenStorage;

  @override
  Future<String?> refreshAccessToken() async {
    final refreshToken = _tokenStorage.readRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) {
      return null;
    }

    final response = await _client.post<Map<String, dynamic>>(
      '/auth/refresh',
      data: {'refreshToken': refreshToken},
      options: Options(extra: {ApiInterceptor.skipAuthKey: true}),
    );
    final data = response.data;

    if (data == null) {
      return null;
    }

    final accessToken = data['accessToken'] as String?;
    final nextRefreshToken = data['refreshToken'] as String? ?? refreshToken;

    if (accessToken == null || accessToken.isEmpty) {
      return null;
    }

    await _tokenStorage.saveTokens(
      accessToken: accessToken,
      refreshToken: nextRefreshToken,
    );

    return accessToken;
  }
}
