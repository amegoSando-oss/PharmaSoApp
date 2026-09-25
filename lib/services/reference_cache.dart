import 'package:flutter/foundation.dart';

import '../models/customer.dart';
import '../models/item.dart';
import '../models/price_list.dart';
import 'offers_service.dart';

/// Caches customers/price-lists/items so screens can resolve id -> name
/// without refetching on every navigation, mirroring resources/js/core/reference.js.
class ReferenceCache extends ChangeNotifier {
  final OffersService offers;

  ReferenceCache(this.offers);

  List<Customer> customers = const [];
  List<PriceListEntry> priceLists = const [];
  List<ItemEntry> items = const [];

  Future<void>? _inflight;

  Future<void> ensureLoaded({bool force = false}) {
    if (!force && customers.isNotEmpty) return Future.value();
    return _inflight ??= _load().whenComplete(() => _inflight = null);
  }

  Future<void> _load() async {
    final results = await Future.wait([
      offers.fetchCustomers(),
      offers.fetchPriceLists(),
      offers.fetchItems(),
    ]);
    customers = results[0] as List<Customer>;
    priceLists = results[1] as List<PriceListEntry>;
    items = results[2] as List<ItemEntry>;
    notifyListeners();
  }

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
