import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import '../core/api_client.dart';
import '../core/json_utils.dart';
import '../models/offline_price_offer.dart';
import '../models/warehouse_item_stock.dart';
import 'offline_db.dart';
import 'warehouse_stock_cache.dart';

/// Outcome of the most recently *attempted* manual/automatic sync — drives
/// the home screen's sync status readout.
enum LastSyncResult { success, partialFailure, offline }

/// Client-side implementation of the 3-step mobile offline-sync protocol
/// for price offer requests (see Mobile Offline Sync.pdf and
/// MobileSyncController's doc comment on the backend). Scoped only to price
/// offer requests, per the protocol.
class OfflineSyncService extends ChangeNotifier {
  // Reserve more serials once fewer than this many unused ones remain for a
  // salesman — deliberately more than 1 so a rep composing several offers
  // in a row offline doesn't run out mid-session.
  static const _reserveThreshold = 3;
  static const _reserveBatchSize = 15;
  static const _uuid = Uuid();

  static const _lastSyncAtKey = 'pharmaso_offline_last_sync_at';
  static const _lastSyncResultKey = 'pharmaso_offline_last_sync_result';

  final ApiClient apiClient;

  OfflineSyncService(this.apiClient);

  bool busy = false;
  int pendingCount = 0;
  DateTime? lastSyncAt;
  LastSyncResult? lastSyncResult;

  Future<Database> get _db async => OfflineDb.instance.database;

  /// Loads persisted last-sync info and the current pending count — call
  /// once at app startup so the home screen has something to show before
  /// any sync has run this session.
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final storedAt = prefs.getString(_lastSyncAtKey);
    lastSyncAt = storedAt != null ? DateTime.tryParse(storedAt) : null;
    final storedResult = prefs.getString(_lastSyncResultKey);
    for (final r in LastSyncResult.values) {
      if (r.name == storedResult) lastSyncResult = r;
    }
    await _refreshPendingCount();
    notifyListeners();
  }

  Future<void> _refreshPendingCount() async {
    final db = await _db;
    final result = await db.rawQuery('SELECT COUNT(*) AS c FROM offline_price_offers');
    pendingCount = Sqflite.firstIntValue(result) ?? 0;
  }

  Future<void> _recordSyncResult(LastSyncResult result) async {
    lastSyncAt = DateTime.now();
    lastSyncResult = result;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastSyncAtKey, lastSyncAt!.toIso8601String());
    await prefs.setString(_lastSyncResultKey, result.name);
  }

  // ---------------------------------------------------------------------
  // Step 1 — reserve serials (online only)
  // ---------------------------------------------------------------------

  /// Tops up [salesmanId]'s local stash of unused, unexpired serials if it's
  /// running low. Safe to call opportunistically (e.g. whenever the app
  /// notices it's online) — a no-op most of the time.
  Future<void> ensureReservation(int salesmanId) async {
    final db = await _db;
    final remaining = await _remainingUnexpired(db, salesmanId);
    if (remaining >= _reserveThreshold) return;
    await _reserveMore(salesmanId, _reserveBatchSize);
  }

  /// Tops up every salesman this device has ever reserved serials for —
  /// used to opportunistically top up in the background whenever the app
  /// notices it's back online, without needing to know up front which
  /// salesman(s) the current user acts for.
  Future<void> ensureReservationsForKnownSalesmen() async {
    final db = await _db;
    final rows = await db.query('serial_reservations', distinct: true, columns: ['salesman_id']);
    for (final row in rows) {
      await ensureReservation(row['salesman_id'] as int);
    }
  }

  Future<int> _remainingUnexpired(Database db, int salesmanId) async {
    final now = DateTime.now();
    final rows = await db.query('serial_reservations', where: 'salesman_id = ?', whereArgs: [salesmanId]);
    var total = 0;
    for (final row in rows) {
      final expiresAt = DateTime.tryParse(row['expires_at'] as String);
      if (expiresAt == null || !expiresAt.isAfter(now)) continue;
      final serialCount = (jsonDecode(row['serials'] as String) as List).length;
      final nextIndex = row['next_index'] as int;
      total += (serialCount - nextIndex).clamp(0, serialCount);
    }
    return total;
  }

  Future<void> _reserveMore(int salesmanId, int count) async {
    final payload = await apiClient.post(
      '/mobile/serials/reserve',
      prefix: 'serials-reserve',
      body: {'salesman_id': salesmanId, 'count': count},
    );
    final data = (payload as Map<String, dynamic>)['data'] as Map<String, dynamic>;
    final db = await _db;
    await db.insert(
      'serial_reservations',
      {
        'reservation_id': asInt(data['reservation_id']),
        'salesman_id': salesmanId,
        'serials': jsonEncode((data['serials'] as List).map((s) => s.toString()).toList()),
        'next_index': 0,
        'expires_at': data['expires_at'].toString(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    notifyListeners();
  }

  // ---------------------------------------------------------------------
  // Step 2 — create a record offline (zero network calls)
  // ---------------------------------------------------------------------

  /// Throws [StateError] if no unused, unexpired serial is available for
  /// [salesmanId] — the caller must come online and let [ensureReservation]
  /// run before it can create offline records for that salesman.
  Future<OfflinePriceOffer> createOffline({
    required int customerId,
    required int salesmanId,
    required int priceListId,
    required List<OfflineOfferLine> lines,
  }) async {
    final db = await _db;
    final reservationRow = await _nextUsableReservation(db, salesmanId);
    if (reservationRow == null) {
      throw StateError(
        'No offline request numbers are ready for this salesman. Connect to the internet briefly so the app can prepare them before you go offline again.',
      );
    }

    final serials = (jsonDecode(reservationRow['serials'] as String) as List).map((s) => s.toString()).toList();
    final nextIndex = reservationRow['next_index'] as int;
    final serial = serials[nextIndex];
    final reservationId = reservationRow['reservation_id'] as int;

    final record = OfflinePriceOffer(
      clientUuid: _uuid.v4(),
      serial: serial,
      reservationId: reservationId,
      customerId: customerId,
      salesmanId: salesmanId,
      priceListId: priceListId,
      lines: lines,
      createdOfflineAt: DateTime.now(),
    );

    await db.transaction((txn) async {
      await txn.insert('offline_price_offers', _toRow(record));
      // Advance the cursor in the same transaction as the insert — if the
      // app is killed between the two, either both happened or neither did,
      // so this serial can never be handed out twice.
      await txn.update('serial_reservations', {'next_index': nextIndex + 1}, where: 'reservation_id = ?', whereArgs: [reservationId]);
    });

    await _refreshPendingCount();
    notifyListeners();
    return record;
  }

  Future<Map<String, Object?>?> _nextUsableReservation(Database db, int salesmanId) async {
    final now = DateTime.now();
    final rows = await db.query(
      'serial_reservations',
      where: 'salesman_id = ?',
      whereArgs: [salesmanId],
      orderBy: 'reservation_id ASC',
    );
    for (final row in rows) {
      final expiresAt = DateTime.tryParse(row['expires_at'] as String);
      if (expiresAt == null || !expiresAt.isAfter(now)) continue;
      final serialCount = (jsonDecode(row['serials'] as String) as List).length;
      final nextIndex = row['next_index'] as int;
      if (nextIndex < serialCount) return row;
    }
    return null;
  }

  // ---------------------------------------------------------------------
  // Listing / discarding queued records
  // ---------------------------------------------------------------------

  Future<List<OfflinePriceOffer>> listPending() async {
    final db = await _db;
    final rows = await db.query('offline_price_offers', orderBy: 'created_offline_at ASC');
    return rows.map(_fromRow).toList();
  }

  /// Drops a queued record without ever syncing it — the only "fix" path
  /// for a record the backend rejected (per the protocol, edit-then-resend
  /// isn't supported here; the rep discards it and creates a corrected one).
  Future<void> discard(String clientUuid) async {
    final db = await _db;
    await db.delete('offline_price_offers', where: 'client_uuid = ?', whereArgs: [clientUuid]);
    await _refreshPendingCount();
    notifyListeners();
  }

  // ---------------------------------------------------------------------
  // Step 3 — sync (once back online)
  // ---------------------------------------------------------------------

  Future<void> syncPending() async {
    if (busy) return;
    busy = true;
    notifyListeners();
    try {
      final db = await _db;
      final rows = await db.query('offline_price_offers', where: 'sync_status != ?', whereArgs: ['syncing']);
      final records = rows.map(_fromRow).toList();
      final byReservation = <int, List<OfflinePriceOffer>>{};
      for (final r in records) {
        byReservation.putIfAbsent(r.reservationId, () => []).add(r);
      }

      var sawFailure = false;
      var sawNetworkError = false;
      for (final entry in byReservation.entries) {
        final outcome = await _syncBatch(entry.key, entry.value);
        if (outcome == LastSyncResult.partialFailure) sawFailure = true;
        if (outcome == LastSyncResult.offline) sawNetworkError = true;
      }

      await _refreshPendingCount();
      // A network error takes priority in the readout even if an earlier
      // batch this same run had a named validation failure — "you're
      // offline" is the more actionable thing to tell the rep.
      await _recordSyncResult(
        sawNetworkError
            ? LastSyncResult.offline
            : sawFailure
                ? LastSyncResult.partialFailure
                : LastSyncResult.success,
      );
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  Future<LastSyncResult> _syncBatch(int reservationId, List<OfflinePriceOffer> items) async {
    final db = await _db;
    final body = {
      'reservation_id': reservationId,
      'items': items
          .map((r) => {
                'client_uuid': r.clientUuid,
                'customer_id': r.customerId,
                'salesman_id': r.salesmanId,
                'price_list_id': r.priceListId,
                'created_offline_at': r.createdOfflineAt.toUtc().toIso8601String(),
                'lines': r.lines.map((l) => l.toSyncJson()).toList(),
                'notes': const [],
              })
          .toList(),
    };

    try {
      // Whole batch is one DB transaction server-side: if this call returns
      // without throwing, every item in it is now safely on the backend
      // (either just created, or already there from an earlier attempt of
      // this same batch and skipped) — safe to drop all of them locally.
      await apiClient.post('/mobile/price-offer-requests/sync', prefix: 'offline-sync', body: body);
      final batch = db.batch();
      for (final r in items) {
        batch.delete('offline_price_offers', where: 'client_uuid = ?', whereArgs: [r.clientUuid]);
      }
      await batch.commit(noResult: true);
      // Best-effort: while we're online for this sync anyway, refresh the
      // local warehouse-stock cache for every item just synced, so the
      // create-offer screen has recent figures ready if the rep goes
      // offline again before browsing these items online.
      final itemIds = items.expand((r) => r.lines.map((l) => l.itemId)).toSet();
      unawaited(_refreshStockCacheForItems(itemIds));
      return LastSyncResult.success;
    } on ApiException catch (e) {
      // Named-failure case: exactly one item is invalid; the rest of the
      // batch was rolled back too (all-or-nothing) so everything goes back
      // to pending except the offending client_uuid, which is marked
      // failed with its error so the rep can discard/redo just that one.
      //
      // If no specific client_uuid can be identified (e.g. a
      // reservation-level error like "not enough serials left" or an
      // expired/invalid reservation_id), the failure isn't caused by any
      // one item — mark the whole batch failed with the shared error
      // instead of silently resetting to pending, which would otherwise
      // retry the exact same failing request forever on every reconnect
      // with nothing ever surfaced to the rep.
      final failedUuid = _extractFailedClientUuid(e.message);
      final batch = db.batch();
      for (final r in items) {
        final isCulprit = failedUuid == null || r.clientUuid == failedUuid;
        batch.update(
          'offline_price_offers',
          isCulprit ? {'sync_status': 'failed', 'sync_error': e.message} : {'sync_status': 'pending', 'sync_error': null},
          where: 'client_uuid = ?',
          whereArgs: [r.clientUuid],
        );
      }
      await batch.commit(noResult: true);
      return LastSyncResult.partialFailure;
    } catch (_) {
      // Network drop with no response at all — leave the batch exactly as
      // it is. Resending the identical payload later is always safe: any
      // client_uuid already committed server-side gets recognized and
      // skipped rather than re-created or errored.
      return LastSyncResult.offline;
    }
  }

  /// Refreshes WarehouseStockCache for each item id, one at a time —
  /// mirrors OffersService.fetchWarehouseStockForItem's one-item-at-a-time
  /// call shape. Failures are swallowed per item so one bad lookup can't
  /// block the rest or fail a sync that already succeeded.
  Future<void> _refreshStockCacheForItems(Iterable<int> itemIds) async {
    for (final itemId in itemIds) {
      try {
        final payload = await apiClient.get('/warehouse-item-stocks/for-items?item_ids[]=$itemId');
        final data = ((payload as Map<String, dynamic>)['data'] as List?) ?? const [];
        final stock = data.map((s) => WarehouseItemStock.fromJson(s as Map<String, dynamic>)).toList();
        await WarehouseStockCache.instance.save(itemId, stock);
      } catch (_) {
        // Best-effort only — see doc comment above.
      }
    }
  }

  String? _extractFailedClientUuid(String message) {
    final match = RegExp(r'client_uuid\\?"([0-9a-fA-F-]{36})\\?"').firstMatch(message);
    return match?.group(1);
  }

  Map<String, Object?> _toRow(OfflinePriceOffer r) => {
        'client_uuid': r.clientUuid,
        'serial': r.serial,
        'reservation_id': r.reservationId,
        'customer_id': r.customerId,
        'salesman_id': r.salesmanId,
        'price_list_id': r.priceListId,
        'lines': jsonEncode(r.lines.map((l) => l.toStorageJson()).toList()),
        'created_offline_at': r.createdOfflineAt.toIso8601String(),
        'sync_status': r.status.name,
        'sync_error': r.syncError,
      };

  OfflinePriceOffer _fromRow(Map<String, Object?> row) {
    final linesJson = jsonDecode(row['lines'] as String) as List;
    return OfflinePriceOffer(
      clientUuid: row['client_uuid'] as String,
      serial: row['serial'] as String,
      reservationId: row['reservation_id'] as int,
      customerId: row['customer_id'] as int,
      salesmanId: row['salesman_id'] as int,
      priceListId: row['price_list_id'] as int,
      lines: linesJson.map((l) => OfflineOfferLine.fromStorageJson(l as Map<String, dynamic>)).toList(),
      createdOfflineAt: DateTime.parse(row['created_offline_at'] as String),
      status: OfflineSyncStatus.values.firstWhere(
        (s) => s.name == row['sync_status'],
        orElse: () => OfflineSyncStatus.pending,
      ),
      syncError: row['sync_error'] as String?,
    );
  }
}
