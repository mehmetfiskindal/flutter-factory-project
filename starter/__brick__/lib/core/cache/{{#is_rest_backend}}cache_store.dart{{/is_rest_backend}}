import 'package:hive/hive.dart';

import '../error/app_exception.dart';

abstract interface class CacheStore {
  String? readString(String key);

  Future<void> writeString(String key, String value);

  Future<void> remove(String key);

  Future<void> clear();
}

final class HiveCacheStore implements CacheStore {
  const HiveCacheStore(this._box);

  final Box<dynamic> _box;

  @override
  String? readString(String key) {
    try {
      return _box.get(key) as String?;
    } on Object catch (error) {
      throw CacheException(
        message: 'Could not read "$key" from cache.',
        cause: error,
      );
    }
  }

  @override
  Future<void> writeString(String key, String value) async {
    try {
      await _box.put(key, value);
    } on Object catch (error) {
      throw CacheException(
        message: 'Could not write "$key" to cache.',
        cause: error,
      );
    }
  }

  @override
  Future<void> remove(String key) async {
    try {
      await _box.delete(key);
    } on Object catch (error) {
      throw CacheException(
        message: 'Could not remove "$key" from cache.',
        cause: error,
      );
    }
  }

  @override
  Future<void> clear() async {
    try {
      await _box.clear();
    } on Object catch (error) {
      throw CacheException(
        message: 'Could not clear cache.',
        cause: error,
      );
    }
  }
}
