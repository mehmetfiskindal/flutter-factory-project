import '../cache/cache_store.dart';
import '../utils/constants/cache_keys.dart';

abstract interface class TokenStorage {
  String? readAccessToken();

  String? readRefreshToken();

  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  });

  Future<void> clearTokens();
}

final class HiveTokenStorage implements TokenStorage {
  const HiveTokenStorage(this._cacheStore);

  final CacheStore _cacheStore;

  @override
  String? readAccessToken() {
    return _cacheStore.readString(CacheKeys.accessToken);
  }

  @override
  String? readRefreshToken() {
    return _cacheStore.readString(CacheKeys.refreshToken);
  }

  @override
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await _cacheStore.writeString(CacheKeys.accessToken, accessToken);
    await _cacheStore.writeString(CacheKeys.refreshToken, refreshToken);
  }

  @override
  Future<void> clearTokens() async {
    await _cacheStore.remove(CacheKeys.accessToken);
    await _cacheStore.remove(CacheKeys.refreshToken);
  }
}
