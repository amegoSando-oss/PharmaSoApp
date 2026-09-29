import 'dart:async';

import '../core/api_client.dart';
import 'data_cache.dart';

/// Generic write-through/read-fallback wrapper around a paginated-envelope
/// API call: on success, caches the raw JSON under [key] and returns it
/// mapped through [fromJson]; on failure, reads whatever was cached last
/// under [key] and maps that instead — only rethrowing when there's nothing
/// cached at all. Caches raw maps (not domain objects) so callers don't need
/// to add toJson() to any model; reconstruction reuses the model's own
/// fromJson.
///
/// Only falls back to the cache for a failure with no server response at all
/// (i.e. not an [ApiException]) — the same distinction every other offline
/// fallback in this app already makes (see CreateOfferScreen's `_load`). A
/// real response (expired session, permission denied, ...) is a genuine
/// answer from the server and must not be silently papered over with stale
/// data.
class CachedFetch {
  CachedFetch._();

  static Future<List<T>> list<T>({
    required String key,
    required Future<Map<String, dynamic>> Function() request,
    required T Function(Map<String, dynamic>) fromJson,
  }) async {
    try {
      final payload = await request();
      final data = (payload['data'] as List?) ?? const [];
      final rows = data.cast<Map<String, dynamic>>();
      unawaited(DataCache.instance.put(key, rows));
      return rows.map(fromJson).toList();
    } on ApiException {
      rethrow;
    } catch (_) {
      final cached = await DataCache.instance.get(key);
      if (cached is List) {
        return cached.cast<Map<String, dynamic>>().map(fromJson).toList();
      }
      rethrow;
    }
  }

  static Future<T> detail<T>({
    required String key,
    required Future<Map<String, dynamic>> Function() request,
    required T Function(Map<String, dynamic>) fromPayload,
  }) async {
    try {
      final payload = await request();
      unawaited(DataCache.instance.put(key, payload));
      return fromPayload(payload);
    } on ApiException {
      rethrow;
    } catch (_) {
      final cached = await DataCache.instance.get(key);
      if (cached is Map) {
        return fromPayload(cached.cast<String, dynamic>());
      }
      rethrow;
    }
  }

}
