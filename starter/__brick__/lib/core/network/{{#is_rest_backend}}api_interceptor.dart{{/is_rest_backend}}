import 'package:dio/dio.dart';
import 'package:logger/logger.dart';

import '../error/app_exception.dart';
import 'token_storage.dart';

abstract interface class AuthTokenRefresher {
  Future<String?> refreshAccessToken();
}

class ApiInterceptor extends Interceptor {
  ApiInterceptor({
    required Dio dio,
    required TokenStorage tokenStorage,
    required AuthTokenRefresher tokenRefresher,
    required Logger logger,
    required bool enableLogging,
  })  : _dio = dio,
        _tokenStorage = tokenStorage,
        _tokenRefresher = tokenRefresher,
        _logger = logger,
        _enableLogging = enableLogging;

  static const skipAuthKey = 'skipAuth';
  static const retryKey = 'authRetry';

  final Dio _dio;
  final TokenStorage _tokenStorage;
  final AuthTokenRefresher _tokenRefresher;
  final Logger _logger;
  final bool _enableLogging;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (options.extra[skipAuthKey] != true) {
      final accessToken = _tokenStorage.readAccessToken();
      if (accessToken != null && accessToken.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $accessToken';
      }
    }

    if (_enableLogging) {
      _logger.d('${options.method} ${options.uri}');
    }

    handler.next(options);
  }

  @override
  void onResponse(Response<dynamic> response, ResponseInterceptorHandler handler) {
    if (_enableLogging) {
      _logger.d(
        '${response.requestOptions.method} ${response.requestOptions.uri} '
        '-> ${response.statusCode}',
      );
    }

    handler.next(response);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (_enableLogging) {
      _logger.e(
        '${err.requestOptions.method} ${err.requestOptions.uri} failed',
        error: err,
        stackTrace: err.stackTrace,
      );
    }

    final shouldRefresh = err.response?.statusCode == 401 &&
        err.requestOptions.extra[retryKey] != true &&
        err.requestOptions.extra[skipAuthKey] != true;

    if (!shouldRefresh) {
      handler.next(err);
      return;
    }

    try {
      final newAccessToken = await _tokenRefresher.refreshAccessToken();
      if (newAccessToken == null || newAccessToken.isEmpty) {
        await _tokenStorage.clearTokens();
        handler.next(err);
        return;
      }

      final retryOptions = err.requestOptions
        ..headers['Authorization'] = 'Bearer $newAccessToken'
        ..extra[retryKey] = true;

      final response = await _dio.fetch<dynamic>(retryOptions);
      handler.resolve(response);
    } on Object catch (error, stackTrace) {
      await _tokenStorage.clearTokens();
      handler.reject(
        DioException(
          requestOptions: err.requestOptions,
          response: err.response,
          type: DioExceptionType.badResponse,
          error: UnauthorizedException(
            cause: error,
            stackTrace: stackTrace,
          ),
        ),
      );
    }
  }
}
