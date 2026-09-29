import 'package:flutter/foundation.dart';

import 'data_cache.dart';
import 'offers_service.dart';
import 'offline_sync_service.dart';
import 'quotations_service.dart';
import 'reference_cache.dart';
import 'sales_orders_service.dart';
import 'warehouse_stock_cache.dart';

enum SyncStepState { pending, running, done, failed }

/// One stage of a full pull-side sync — see [DataSyncService.syncAll].
/// Mutable in place (not replaced) so [DataSyncService] only ever needs to
/// call [ChangeNotifier.notifyListeners] after flipping a step's state,
/// rather than rebuilding the whole `steps` list every time.
class SyncStep {
  final String key;
  SyncStepState state = SyncStepState.pending;
  String? error;

  SyncStep(this.key);
}

/// Pull-side counterpart to [OfflineSyncService] (which only pushes offline-
/// created price offer requests up): refreshes every local read cache this
/// rep depends on — reference data, effective prices, and their own price
/// offer requests/quotations/sales orders — from the backend. Each step is
/// independent and best-effort, mirroring OfflineSyncService's per-batch
/// isolation: one step failing (e.g. a single endpoint erroring) never stops
/// the rest from running, so a partial connection still refreshes whatever
/// it can.
class DataSyncService extends ChangeNotifier {
  final OffersService offers;
  final QuotationsService quotations;
  final SalesOrdersService salesOrders;
  final ReferenceCache reference;
  final OfflineSyncService offlineSync;

  DataSyncService(this.offers, this.quotations, this.salesOrders, this.reference, this.offlineSync);

  bool busy = false;
  DateTime? lastFullSyncAt;

  final List<SyncStep> steps = [
    SyncStep('referenceData'),
    SyncStep('offlineReadiness'),
    SyncStep('effectivePrices'),
    SyncStep('warehouseStock'),
    SyncStep('priceOfferRequests'),
    SyncStep('quotations'),
    SyncStep('salesOrders'),
  ];

  bool get lastRunHadFailure => steps.any((s) => s.state == SyncStepState.failed);

  SyncStep _step(String key) => steps.firstWhere((s) => s.key == key);

  Future<void> syncAll() async {
    if (busy) return;
    busy = true;
    for (final step in steps) {
      step.state = SyncStepState.pending;
      step.error = null;
    }
    notifyListeners();

    await _run(_step('referenceData'), () => reference.ensureLoaded(force: true));
    await _run(_step('offlineReadiness'), () async {
      // Every customer's active salesman needs a stash of reserved offline
      // request numbers *before* this device goes offline (createOffline()
      // throws otherwise — see OfflineSyncService's doc comment) — until
      // now the only way to get one was picking that customer in Create
      // Offer while online, so a rep who went offline before ever doing
      // that for a given customer got stuck. A full sync is exactly the
      // moment to top all of them up at once instead of one at a time.
      // Best-effort per salesman: one bad/unauthorized salesman_id
      // shouldn't stop every other salesman's reservation from going
      // through — but if every single one failed, report that honestly
      // instead of a false "done".
      final salesmanIds = reference.customers.map((c) => c.activeSalesman?.id).whereType<int>().toSet();
      var failures = 0;
      for (final salesmanId in salesmanIds) {
        try {
          await offlineSync.ensureReservation(salesmanId);
        } catch (_) {
          failures++;
        }
      }
      if (salesmanIds.isNotEmpty && failures == salesmanIds.length) {
        throw StateError('Could not reserve offline request numbers for any salesman.');
      }
    });
    await _run(_step('effectivePrices'), () async {
      for (final priceList in reference.priceLists) {
        await offers.fetchEffectivePricesBulk(priceList.id);
      }
    });
    await _run(_step('warehouseStock'), () async {
      // One request per item — this endpoint only accepts item-scoped
      // lookups (see OffersService.fetchWarehouseStockForItem's doc
      // comment) — so this is the only way to have every catalog item's
      // stock ready offline, not just whichever ones this rep happened to
      // open in Create Offer before going offline. Best-effort per item:
      // one bad lookup shouldn't sink the whole step — but if every single
      // one failed (e.g. this device is actually offline right now), report
      // that honestly instead of a false "done".
      var failures = 0;
      for (final item in reference.items) {
        try {
          final stock = await offers.fetchWarehouseStockForItem(item.id);
          await WarehouseStockCache.instance.save(item.id, stock);
        } catch (_) {
          failures++;
        }
      }
      if (reference.items.isNotEmpty && failures == reference.items.length) {
        throw StateError('Could not reach the server for any item.');
      }
    });
    await _run(_step('priceOfferRequests'), () async {
      final rows = await offers.listRequests();
      for (final row in rows) {
        await offers.getRequest(row.id);
      }
      await DataCache.instance.deleteWherePrefixNotIn(
        'price_offer_request_detail:',
        rows.map((r) => 'price_offer_request_detail:${r.id}').toSet(),
      );
    });
    await _run(_step('quotations'), () => quotations.listQuotations());
    await _run(_step('salesOrders'), () async {
      final rows = await salesOrders.listOrders();
      for (final row in rows) {
        await salesOrders.getOrder(row.id);
      }
      await DataCache.instance.deleteWherePrefixNotIn(
        'sales_order_detail:',
        rows.map((r) => 'sales_order_detail:${r.id}').toSet(),
      );
    });

    lastFullSyncAt = DateTime.now();
    busy = false;
    notifyListeners();
  }

  Future<void> _run(SyncStep step, Future<void> Function() action) async {
    step.state = SyncStepState.running;
    notifyListeners();
    try {
      await action();
      step.state = SyncStepState.done;
    } catch (e) {
      step.state = SyncStepState.failed;
      step.error = e.toString();
    }
    notifyListeners();
  }
}
