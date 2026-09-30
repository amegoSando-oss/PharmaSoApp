import 'dart:async';

import 'package:flutter/foundation.dart';

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
      debugPrint('[CachedFetch] list "$key" -> live fetch OK, ${rows.length} row(s), caching');
      unawaited(DataCache.instance.put(key, rows));
      return rows.map(fromJson).toList();
    } on ApiException catch (e) {
      debugPrint('[CachedFetch] list "$key" -> ApiException (${e.message}), NOT falling back to cache');
      rethrow;
    } catch (e) {
      debugPrint('[CachedFetch] list "$key" -> live fetch failed ($e), falling back to cache');
      final cached = await DataCache.instance.get(key);
      if (cached is List) {
        debugPrint('[CachedFetch] list "$key" -> served ${cached.length} row(s) from cache');
        return cached.cast<Map<String, dynamic>>().map(fromJson).toList();
      }
      debugPrint('[CachedFetch] list "$key" -> nothing cached, rethrowing');
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
      debugPrint('[CachedFetch] detail "$key" -> live fetch OK, caching');
      unawaited(DataCache.instance.put(key, payload));
      return fromPayload(payload);
    } on ApiException catch (e) {
      debugPrint('[CachedFetch] detail "$key" -> ApiException (${e.message}), NOT falling back to cache');
      rethrow;
    } catch (e) {
      debugPrint('[CachedFetch] detail "$key" -> live fetch failed ($e), falling back to cache');
      final cached = await DataCache.instance.get(key);
      if (cached is Map) {
        debugPrint('[CachedFetch] detail "$key" -> served from cache');
        return fromPayload(cached.cast<String, dynamic>());
      }
      debugPrint('[CachedFetch] detail "$key" -> nothing cached, rethrowing');
      rethrow;
    }
  }

}
