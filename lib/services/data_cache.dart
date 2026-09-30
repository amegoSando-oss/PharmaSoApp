import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';

import 'offline_db.dart';

/// Generic last-known-good JSON cache, keyed by a fixed string per kind of
/// data (e.g. `'customers'`, `'price_offer_request_detail:42'`). Every
/// service method that needs offline read support writes here on a
/// successful fetch and reads back here when the fetch fails — see
/// OffersService/QuotationsService/SalesOrdersService and
/// DataSyncService's doc comments for how this is used end-to-end.
class DataCache {
  DataCache._();
  static final DataCache instance = DataCache._();

  Future<Database> get _db async => OfflineDb.instance.database;

  Future<void> put(String key, dynamic value) async {
    final db = await _db;
    final encoded = jsonEncode(value);
    await db.insert(
      'data_cache',
      {
        'cache_key': key,
        'payload': encoded,
        'updated_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    final rowCount = value is List ? value.length : 1;
    debugPrint('[DataCache] put "$key" -> $rowCount row(s), ${encoded.length} bytes');
  }

  /// Returns the decoded JSON value, or null if [key] was never cached.
  Future<dynamic> get(String key) async {
    final db = await _db;
    final rows = await db.query('data_cache', where: 'cache_key = ?', whereArgs: [key]);
    if (rows.isEmpty) {
      debugPrint('[DataCache] get "$key" -> MISS (nothing cached)');
      return null;
    }
    final decoded = jsonDecode(rows.first['payload'] as String);
    final rowCount = decoded is List ? decoded.length : 1;
    debugPrint('[DataCache] get "$key" -> HIT, $rowCount row(s), cached at ${rows.first['updated_at']}');
    return decoded;
  }

  Future<DateTime?> updatedAt(String key) async {
    final db = await _db;
    final rows = await db.query('data_cache', columns: ['updated_at'], where: 'cache_key = ?', whereArgs: [key]);
    if (rows.isEmpty) return null;
    return DateTime.tryParse(rows.first['updated_at'] as String);
  }

  Future<void> delete(String key) async {
    final db = await _db;
    await db.delete('data_cache', where: 'cache_key = ?', whereArgs: [key]);
  }

  /// Drops every cached entry whose key starts with [prefix] except those
  /// in [keepKeys] — used to prune detail-cache entries for records that
  /// have dropped out of this rep's current list (e.g. reassigned away)
  /// instead of keeping them forever.
  Future<void> deleteWherePrefixNotIn(String prefix, Set<String> keepKeys) async {
    final db = await _db;
    final rows = await db.query('data_cache', columns: ['cache_key'], where: 'cache_key LIKE ?', whereArgs: ['$prefix%']);
    final toDelete = rows.map((r) => r['cache_key'] as String).where((k) => !keepKeys.contains(k)).toList();
    if (toDelete.isEmpty) return;
    final batch = db.batch();
    for (final key in toDelete) {
      batch.delete('data_cache', where: 'cache_key = ?', whereArgs: [key]);
    }
    await batch.commit(noResult: true);
  }
}
