import 'dart:convert';

import 'package:sqflite/sqflite.dart';

import '../models/warehouse_item_stock.dart';
import 'offline_db.dart';

/// Result of a cache lookup: the stock as of [cachedAt], so the UI can tell
/// the rep how stale it might be.
class CachedWarehouseStock {
  final List<WarehouseItemStock> stock;
  final DateTime cachedAt;

  CachedWarehouseStock(this.stock, this.cachedAt);
}

/// Last-known-good warehouse stock per item, refreshed every time
/// CreateOfferScreen successfully fetches it online. Purely informational
/// data (see WarehouseItemStock's doc comment — no warehouse is actually
/// assigned at price-offer time), so serving a slightly stale cached copy
/// while offline is a reasonable trade-off against showing nothing at all.
class WarehouseStockCache {
  WarehouseStockCache._();
  static final WarehouseStockCache instance = WarehouseStockCache._();

  Future<Database> get _db async => OfflineDb.instance.database;

  Future<void> save(int itemId, List<WarehouseItemStock> stock) async {
    final db = await _db;
    await db.insert(
      'warehouse_stock_cache',
      {
        'item_id': itemId,
        'stock': jsonEncode(stock
            .map((s) => {
                  'warehouse_id': s.warehouseId,
                  'warehouse_name': s.warehouseName,
                  'on_hand_qty': s.onHandQty,
                  'committed_qty': s.committedQty,
                  'available_qty': s.availableQty,
                })
            .toList()),
        'cached_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Returns null if this item has never been cached.
  Future<CachedWarehouseStock?> load(int itemId) async {
    final db = await _db;
    final rows = await db.query('warehouse_stock_cache', where: 'item_id = ?', whereArgs: [itemId]);
    if (rows.isEmpty) return null;
    final row = rows.first;
    final stock = (jsonDecode(row['stock'] as String) as List)
        .map((s) => WarehouseItemStock.fromJson(s as Map<String, dynamic>))
        .toList();
    return CachedWarehouseStock(stock, DateTime.parse(row['cached_at'] as String));
  }
}
