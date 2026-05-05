{{#is_riverpod}}
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

import 'cache_store.dart';

final appCacheBoxProvider = Provider<Box<dynamic>>((ref) {
  throw UnimplementedError('appCacheBoxProvider must be overridden.');
});

final secureCacheBoxProvider = Provider<Box<dynamic>>((ref) {
  throw UnimplementedError('secureCacheBoxProvider must be overridden.');
});

final appCacheStoreProvider = Provider<CacheStore>((ref) {
  return HiveCacheStore(ref.watch(appCacheBoxProvider));
});

final secureCacheStoreProvider = Provider<CacheStore>((ref) {
  return HiveCacheStore(ref.watch(secureCacheBoxProvider));
});
{{/is_riverpod}}{{#is_bloc}}export 'cache_store.dart';
{{/is_bloc}}
