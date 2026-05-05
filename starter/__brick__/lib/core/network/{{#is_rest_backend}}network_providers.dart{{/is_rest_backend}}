{{#is_riverpod}}
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/flavor.dart';
import '../../features/auth/data/datasources/auth_token_refresher.dart';
import '../cache/cache_providers.dart';
import '../logging/app_logger.dart';
import '../utils/constants/network_constants.dart';
import 'api_interceptor.dart';
import 'dio_client.dart';
import 'token_storage.dart';

final tokenStorageProvider = Provider<TokenStorage>((ref) {
  return HiveTokenStorage(ref.watch(secureCacheStoreProvider));
});

final authTokenRefresherProvider = Provider<AuthTokenRefresher>((ref) {
  return AuthTokenRefresherImpl(
    client: ref.watch(rawDioProvider),
    tokenStorage: ref.watch(tokenStorageProvider),
  );
});

final rawDioProvider = Provider<Dio>((ref) {
  final environment = ref.watch(appEnvironmentProvider);

  return Dio(
    BaseOptions(
      baseUrl: environment.apiBaseUrl,
      connectTimeout: NetworkConstants.connectTimeout,
      receiveTimeout: NetworkConstants.receiveTimeout,
      sendTimeout: NetworkConstants.sendTimeout,
      headers: const {
        NetworkConstants.acceptHeader: NetworkConstants.applicationJson,
        NetworkConstants.contentTypeHeader: NetworkConstants.applicationJson,
      },
    ),
  );
});

final dioProvider = Provider<Dio>((ref) {
  final environment = ref.watch(appEnvironmentProvider);
  final logger = ref.watch(appLoggerProvider);
  final dio = ref.watch(rawDioProvider);

  dio.interceptors
    ..clear()
    ..add(
      ApiInterceptor(
        dio: dio,
        tokenStorage: ref.watch(tokenStorageProvider),
        tokenRefresher: ref.watch(authTokenRefresherProvider),
        logger: logger,
        enableLogging: environment.enableNetworkLogs,
      ),
    );

  return dio;
});

final dioClientProvider = Provider<DioClient>((ref) {
  return DioClient(dio: ref.watch(dioProvider));
});
{{/is_riverpod}}{{#is_bloc}}export 'dio_client.dart';
export 'token_storage.dart';
{{/is_bloc}}
