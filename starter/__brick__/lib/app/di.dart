{{#is_riverpod}}{{#is_rest_backend}}import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';

import '../core/cache/cache_providers.dart';
import '../features/auth/presentation/providers/auth_controller.dart';
import 'flavor.dart';

Future<ProviderContainer> configureDependencies(
  AppEnvironment environment,
) async {
  final documentsDirectory = await getApplicationDocumentsDirectory();
  Hive.init(documentsDirectory.path);

  final appCacheBox = await Hive.openBox<dynamic>('app_cache');
  final secureCacheBox = await Hive.openBox<dynamic>('secure_cache');

  final container = ProviderContainer(
    overrides: [
      appEnvironmentProvider.overrideWithValue(environment),
      appCacheBoxProvider.overrideWithValue(appCacheBox),
      secureCacheBoxProvider.overrideWithValue(secureCacheBox),
    ],
  );

  await container.read(authControllerProvider.future);

  return container;
}
{{/is_rest_backend}}{{#is_firebase_backend}}import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/auth/presentation/providers/auth_controller.dart';
import 'flavor.dart';

Future<ProviderContainer> configureDependencies(
  AppEnvironment environment,
) async {
  final container = ProviderContainer(
    overrides: [
      appEnvironmentProvider.overrideWithValue(environment),
    ],
  );

  await container.read(authControllerProvider.future);

  return container;
}
{{/is_firebase_backend}}{{/is_riverpod}}{{#is_bloc}}{{#is_rest_backend}}import 'package:dio/dio.dart';
import 'package:hive/hive.dart';
import 'package:logger/logger.dart';
import 'package:path_provider/path_provider.dart';

import '../core/cache/cache_store.dart';
import '../core/logging/app_logger.dart';
import '../core/network/api_interceptor.dart';
import '../core/network/token_storage.dart';
import '../core/utils/constants/network_constants.dart';
import '../features/auth/data/datasources/auth_remote_datasource.dart';
import '../features/auth/data/datasources/auth_token_refresher.dart';
import '../features/auth/data/repositories/auth_repository_impl.dart';
import '../features/auth/domain/repositories/auth_repository.dart';
import '../features/auth/domain/usecases/get_current_user.dart';
import '../features/auth/domain/usecases/sign_in.dart';
import '../features/auth/domain/usecases/sign_out.dart';
import 'flavor.dart';

class AppDependencies {
  const AppDependencies({
    required this.environment,
    required this.appCacheStore,
    required this.secureCacheStore,
    required this.logger,
    required this.dio,
    required this.tokenStorage,
    required this.authRepository,
    required this.getCurrentUserUseCase,
    required this.signInUseCase,
    required this.signOutUseCase,
  });

  final AppEnvironment environment;
  final CacheStore appCacheStore;
  final CacheStore secureCacheStore;
  final Logger logger;
  final Dio dio;
  final TokenStorage tokenStorage;
  final AuthRepository authRepository;
  final GetCurrentUserUseCase getCurrentUserUseCase;
  final SignInUseCase signInUseCase;
  final SignOutUseCase signOutUseCase;
}

Future<AppDependencies> configureDependencies(
  AppEnvironment environment,
) async {
  final documentsDirectory = await getApplicationDocumentsDirectory();
  Hive.init(documentsDirectory.path);

  final appCacheBox = await Hive.openBox<dynamic>('app_cache');
  final secureCacheBox = await Hive.openBox<dynamic>('secure_cache');
  final appCacheStore = HiveCacheStore(appCacheBox);
  final secureCacheStore = HiveCacheStore(secureCacheBox);
  final tokenStorage = HiveTokenStorage(secureCacheStore);
  final logger = createAppLogger(environment);
  final rawDio = _createRawDio(environment);
  final tokenRefresher = AuthTokenRefresherImpl(
    client: rawDio,
    tokenStorage: tokenStorage,
  );
  final dio = _createDio(
    environment: environment,
    logger: logger,
    rawDio: rawDio,
    tokenStorage: tokenStorage,
    tokenRefresher: tokenRefresher,
  );
  final remoteDataSource = AuthRemoteDataSourceImpl(dio);
  final authRepository = AuthRepositoryImpl(
    remoteDataSource: remoteDataSource,
    tokenStorage: tokenStorage,
  );

  return AppDependencies(
    environment: environment,
    appCacheStore: appCacheStore,
    secureCacheStore: secureCacheStore,
    logger: logger,
    dio: dio,
    tokenStorage: tokenStorage,
    authRepository: authRepository,
    getCurrentUserUseCase: GetCurrentUserUseCase(authRepository),
    signInUseCase: SignInUseCase(authRepository),
    signOutUseCase: SignOutUseCase(authRepository),
  );
}

Dio _createRawDio(AppEnvironment environment) {
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
}

Dio _createDio({
  required AppEnvironment environment,
  required Logger logger,
  required Dio rawDio,
  required TokenStorage tokenStorage,
  required AuthTokenRefresher tokenRefresher,
}) {
  rawDio.interceptors
    ..clear()
    ..add(
      ApiInterceptor(
        dio: rawDio,
        tokenStorage: tokenStorage,
        tokenRefresher: tokenRefresher,
        logger: logger,
        enableLogging: environment.enableNetworkLogs,
      ),
    );

  return rawDio;
}
{{/is_rest_backend}}{{#is_firebase_backend}}import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:firebase_storage/firebase_storage.dart';

import '../core/firebase/cloud_storage_service.dart';
import '../core/firebase/firestore_service.dart';
import '../features/auth/data/repositories/auth_repository_impl.dart';
import '../features/auth/domain/repositories/auth_repository.dart';
import '../features/auth/domain/usecases/get_current_user.dart';
import '../features/auth/domain/usecases/sign_in.dart';
import '../features/auth/domain/usecases/sign_out.dart';
import 'flavor.dart';

class AppDependencies {
  const AppDependencies({
    required this.environment,
    required this.firebaseAuth,
    required this.firestore,
    required this.storage,
    required this.firestoreService,
    required this.cloudStorageService,
    required this.authRepository,
    required this.getCurrentUserUseCase,
    required this.signInUseCase,
    required this.signOutUseCase,
  });

  final AppEnvironment environment;
  final firebase_auth.FirebaseAuth firebaseAuth;
  final FirebaseFirestore firestore;
  final FirebaseStorage storage;
  final FirestoreService firestoreService;
  final CloudStorageService cloudStorageService;
  final AuthRepository authRepository;
  final GetCurrentUserUseCase getCurrentUserUseCase;
  final SignInUseCase signInUseCase;
  final SignOutUseCase signOutUseCase;
}

Future<AppDependencies> configureDependencies(
  AppEnvironment environment,
) async {
  final firebaseAuth = firebase_auth.FirebaseAuth.instance;
  final firestore = FirebaseFirestore.instance;
  final storage = FirebaseStorage.instance;
  final firestoreService = FirestoreService(firestore);
  final cloudStorageService = CloudStorageService(storage);
  final authRepository = AuthRepositoryImpl(firebaseAuth: firebaseAuth);

  return AppDependencies(
    environment: environment,
    firebaseAuth: firebaseAuth,
    firestore: firestore,
    storage: storage,
    firestoreService: firestoreService,
    cloudStorageService: cloudStorageService,
    authRepository: authRepository,
    getCurrentUserUseCase: GetCurrentUserUseCase(authRepository),
    signInUseCase: SignInUseCase(authRepository),
    signOutUseCase: SignOutUseCase(authRepository),
  );
}
{{/is_firebase_backend}}{{/is_bloc}}
