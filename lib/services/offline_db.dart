import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

/// Local queue for the mobile offline-sync protocol (price offer requests
/// only — see Mobile Offline Sync.pdf / MobileSyncController's doc comment
/// on the backend). Tables:
/// - `serial_reservations`: reservation batches fetched via
///   /mobile/serials/reserve, with a cursor (`next_index`) into their
///   ordered `serials` list so offline creation always draws the next
///   unused one, in order, never skipping or reusing one.
/// - `offline_price_offers`: records created fully offline, queued here
///   until /mobile/price-offer-requests/sync succeeds for them.
/// - `warehouse_stock_cache`: last-known-good warehouse stock per item,
///   refreshed on every successful online fetch — see
///   WarehouseStockCache's doc comment. Purely a read cache, not part of
///   the sync protocol itself.
/// - `data_cache`: generic last-known-good JSON cache (customers,
///   warehouses, items, price lists, effective prices, and full detail for
///   this rep's price offer requests/quotations/sales orders) — see
///   DataCache and DataSyncService's doc comments.
class OfflineDb {
  OfflineDb._();
  static final OfflineDb instance = OfflineDb._();

  static const _dbVersion = 3;

  Database? _db;

  Future<Database> get database async => _db ??= await _open();

  Future<Database> _open() async {
    final path = join(await getDatabasesPath(), 'pharmaso_offline.db');
    return openDatabase(
      path,
      version: _dbVersion,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE serial_reservations (
            reservation_id INTEGER PRIMARY KEY,
            salesman_id INTEGER NOT NULL,
            serials TEXT NOT NULL,
            next_index INTEGER NOT NULL DEFAULT 0,
            expires_at TEXT NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE offline_price_offers (
            client_uuid TEXT PRIMARY KEY,
            serial TEXT NOT NULL,
            reservation_id INTEGER NOT NULL,
            customer_id INTEGER NOT NULL,
            salesman_id INTEGER NOT NULL,
            price_list_id INTEGER NOT NULL,
            lines TEXT NOT NULL,
            created_offline_at TEXT NOT NULL,
            sync_status TEXT NOT NULL DEFAULT 'pending',
            sync_error TEXT
          )
        ''');
        await db.execute('''
          CREATE TABLE warehouse_stock_cache (
            item_id INTEGER PRIMARY KEY,
            stock TEXT NOT NULL,
            cached_at TEXT NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE data_cache (
            cache_key TEXT PRIMARY KEY,
            payload TEXT NOT NULL,
            updated_at TEXT NOT NULL
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS warehouse_stock_cache (
              item_id INTEGER PRIMARY KEY,
              stock TEXT NOT NULL,
              cached_at TEXT NOT NULL
            )
          ''');
        }
        if (oldVersion < 3) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS data_cache (
              cache_key TEXT PRIMARY KEY,
              payload TEXT NOT NULL,
              updated_at TEXT NOT NULL
            )
          ''');
        }
      },
    );
  }
}
