import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/customer.dart';
import '../models/item.dart';
import '../models/price_list.dart';
import '../models/salesman.dart';
import '../models/warehouse.dart';
import 'data_cache.dart';
import 'offers_service.dart';

/// Caches customers/warehouses/price-lists/items so screens can resolve
/// id -> name without refetching on every navigation, mirroring
/// resources/js/core/reference.js. Also the app's single persisted copy of
/// this "static" reference data (backed by DataCache) — every successful
/// load writes through to disk, and a load that fails offline with nothing
/// in memory yet (e.g. a cold app start) hydrates from disk instead of
/// staying empty, so screens that depend on it keep working across restarts,
/// not just within one session.
class ReferenceCache extends ChangeNotifier {
  static const _customersKey = 'customers';
  static const _warehousesKey = 'warehouses';
  static const _priceListsKey = 'price_lists';
  static const _itemsKey = 'items';

  final OffersService offers;

  ReferenceCache(this.offers);

  List<Customer> customers = const [];
  List<WarehouseEntry> warehouses = const [];
  List<PriceListEntry> priceLists = const [];
  List<ItemEntry> items = const [];
  DateTime? lastLoadedAt;

  Future<void>? _inflight;

  Future<void> ensureLoaded({bool force = false}) {
    if (!force && customers.isNotEmpty) return Future.value();
    return _inflight ??= _load().whenComplete(() => _inflight = null);
  }

  Future<void> _load() async {
    try {
      final results = await Future.wait([
        offers.fetchCustomers(),
        offers.fetchWarehouses(),
        offers.fetchPriceLists(),
        offers.fetchItems(perPage: 500),
      ]);
      customers = results[0] as List<Customer>;
      warehouses = results[1] as List<WarehouseEntry>;
      priceLists = results[2] as List<PriceListEntry>;
      items = results[3] as List<ItemEntry>;
      lastLoadedAt = DateTime.now();
      debugPrint('[ReferenceCache] live load OK: ${customers.length} customers, ${warehouses.length} warehouses, '
          '${priceLists.length} price lists (active: ${priceLists.where((p) => p.isActive).map((p) => p.id).toList()}), '
          '${items.length} items — persisting to disk');
      unawaited(_persist());
      notifyListeners();
    } catch (e) {
      debugPrint('[ReferenceCache] live load FAILED ($e)${customers.isEmpty ? ', hydrating from disk' : ', keeping in-memory data'}');
      if (customers.isEmpty) await _hydrateFromDisk();
      rethrow;
    }
  }

  Future<void> _persist() async {
    await Future.wait([
      DataCache.instance.put(_customersKey, customers.map(_customerToJson).toList()),
      DataCache.instance.put(_warehousesKey, warehouses.map(_warehouseToJson).toList()),
      DataCache.instance.put(_priceListsKey, priceLists.map(_priceListToJson).toList()),
      DataCache.instance.put(_itemsKey, items.map(_itemToJson).toList()),
    ]);
    debugPrint('[ReferenceCache] persist() finished writing all 4 keys to disk');
  }

  Future<void> _hydrateFromDisk() async {
    final cachedCustomers = await DataCache.instance.get(_customersKey);
    final cachedWarehouses = await DataCache.instance.get(_warehousesKey);
    final cachedPriceLists = await DataCache.instance.get(_priceListsKey);
    final cachedItems = await DataCache.instance.get(_itemsKey);
    if (cachedCustomers is! List) {
      debugPrint('[ReferenceCache] hydrateFromDisk -> nothing cached at all, staying empty');
      return;
    }
    customers = cachedCustomers.cast<Map<String, dynamic>>().map(Customer.fromJson).toList();
    warehouses = (cachedWarehouses as List? ?? const [])
        .cast<Map<String, dynamic>>()
        .map(WarehouseEntry.fromJson)
        .toList();
    priceLists = (cachedPriceLists as List? ?? const []).cast<Map<String, dynamic>>().map(PriceListEntry.fromJson).toList();
    items = (cachedItems as List? ?? const []).cast<Map<String, dynamic>>().map(ItemEntry.fromJson).toList();
    lastLoadedAt = await DataCache.instance.updatedAt(_customersKey);
    debugPrint('[ReferenceCache] hydrateFromDisk -> ${customers.length} customers, ${warehouses.length} warehouses, '
        '${priceLists.length} price lists (active: ${priceLists.where((p) => p.isActive).map((p) => p.id).toList()}), '
        '${items.length} items, last loaded at $lastLoadedAt');
    notifyListeners();
  }

  Map<String, dynamic> _customerToJson(Customer c) => {
        'id': c.id,
        'name': c.name,
        'trade_name': c.tradeName,
        'status': c.status,
        'salesmen': c.salesmen.map(_salesmanToJson).toList(),
      };

  Map<String, dynamic> _salesmanToJson(Salesman s) => {
        'id': s.id,
        'name': s.name,
        'code': s.code,
        'effective_date': s.effectiveDate,
        'expired_date': s.expiredDate,
      };

  Map<String, dynamic> _warehouseToJson(WarehouseEntry w) => {'id': w.id, 'name': w.name, 'location': w.location};

  Map<String, dynamic> _priceListToJson(PriceListEntry p) => {
        'id': p.id,
        'name': p.name,
        'code': p.code,
        'computed_status': p.computedStatus,
        'effective_from': p.effectiveFrom,
        'effective_to': p.effectiveTo,
      };

  Map<String, dynamic> _itemToJson(ItemEntry i) => {
        'id': i.id,
        'name': i.name,
        'jde_item_number': i.jdeItemNumber,
        'uom': i.uom,
        'pack_size': i.packSize,
        'pack_unit': i.packUnit,
      };

  String customerName(int id) {
    for (final c in customers) {
      if (c.id == id) return c.name;
    }
    return 'Customer #$id';
  }

  String priceListName(int id) {
    for (final p in priceLists) {
      if (p.id == id) return p.name;
    }
    return 'Price list #$id';
  }

  String itemName(int id) {
    for (final i in items) {
      if (i.id == id) return i.name;
    }
    return 'Item #$id';
  }
}
