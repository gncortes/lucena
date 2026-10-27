import '../../domain/models/lesson_content.dart';
import 'asset_service.dart';

/// Memoizes successful parsing only for the current logical source/account.
/// Failures are evicted, and an account change during a load rejects its result.
class ScopedAssetCache {
  ScopedAssetCache(this.assets);

  final AssetService assets;
  Object? _scope;
  final _entries = <Object, Future<dynamic>>{};

  Future<T> load<T>(Object key, Future<T> Function() read) {
    final scope = assets.cacheScope;
    if (_scope != scope) {
      _scope = scope;
      _entries.clear();
    }
    final saved = _entries[key];
    if (saved != null) return saved as Future<T>;
    late final Future<T> result;
    result = Future<T>.sync(read)
        .then((value) {
          if (assets.cacheScope != scope) {
            throw const LessonContentUnavailable();
          }
          return value;
        })
        .onError((Object error, StackTrace stack) {
          if (identical(_entries[key], result)) _entries.remove(key);
          Error.throwWithStackTrace(error, stack);
        });
    _entries[key] = result;
    return result;
  }
}
