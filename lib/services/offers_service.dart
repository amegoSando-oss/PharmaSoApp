import 'dart:typed_data';

import '../core/api_client.dart';
import '../core/json_utils.dart';
import '../models/customer.dart';
import '../models/effective_price.dart';
import '../models/item.dart';
import '../models/price_list.dart';
import '../models/price_offer_request.dart';
import '../models/warehouse.dart';
import '../models/warehouse_item_stock.dart';
import 'cached_fetch.dart';

class OfferLineInput {
  final int itemId;
  final num quantity;
  final num proposedPrice;
  // Matches StorePriceOfferRequest/AddPriceOfferLineRequest: the only FOC
  // field either endpoint accepts on a line is foc_percent (0-100) — an
  // informational flag for the approver, never a quantity/UOM (those
  // aren't validated fields on price_offer_request_lines' create path and
  // are silently dropped by PriceOfferLineData::fromArray() if sent).
  final num? focPercent;

  OfferLineInput({
    required this.itemId,
    required this.quantity,
    required this.proposedPrice,
    this.focPercent,
  });

  Map<String, dynamic> toJson() => {
        'item_id': itemId,
        'quantity': quantity,
        'proposed_price': proposedPrice,
        if (focPercent != null && focPercent! > 0) 'foc_percent': focPercent,
      };
}

/// One line declined outright — the closest thing to "cancel this
/// quotation" the backend exposes (there's no whole-quotation cancel
/// endpoint): the given quantity moves from remaining to declined and can
/// never be released into an order afterward. Matches what
/// QuotationService::declineLines() expects per entry in `lines[]`.
class QuotationLineDecline {
  final int lineId;
  final num quantity;
  final String? reason;

  QuotationLineDecline({required this.lineId, required this.quantity, this.reason});

  Map<String, dynamic> toJson() => {
        'line_id': lineId,
        'quantity': quantity,
        if (reason != null && reason!.isNotEmpty) 'reason': reason,
      };
}

/// One warehouse's share of a line being released — a line normally has
/// just one of these (released whole from a single warehouse), but can
/// have more than one when a single warehouse doesn't hold enough of the
/// item, matching CreateSalesOrderData::$lineSplits: one SalesOrderLine
/// gets created per split.
class OrderReleaseSplit {
  final int warehouseId;
  final num quantity;

  OrderReleaseSplit({required this.warehouseId, required this.quantity});

  Map<String, dynamic> toJson() => {
        'warehouse_id': warehouseId,
        'quantity': quantity,
      };
}

/// One quotation line released into a sales order, matching what
/// SalesOrderService::create() expects per entry in `lines[]`: which
/// quotation line, and its warehouse split(s) — the sum of [splits]' own
/// quantities may be less than the line's full remaining quantity (a
/// partial release), leaving the rest open for a later release.
class OrderReleaseLine {
  final int lineId;
  final List<OrderReleaseSplit> splits;

  OrderReleaseLine({required this.lineId, required this.splits});

  Map<String, dynamic> toJson() => {
        'line_id': lineId,
        'splits': splits.map((s) => s.toJson()).toList(),
      };
}

class OffersService {
  final ApiClient apiClient;

  OffersService(this.apiClient);

  Future<List<Customer>> fetchCustomers() async {
    final payload = await apiClient.get('/customers', params: {'per_page': 200});
    final data = (payload['data'] as List?) ?? const [];
    return data.map((c) => Customer.fromJson(c as Map<String, dynamic>)).toList();
  }

  Future<List<WarehouseEntry>> fetchWarehouses() async {
    final payload = await apiClient.get('/warehouses', params: {'per_page': 200});
    final data = (payload['data'] as List?) ?? const [];
    return data.map((w) => WarehouseEntry.fromJson(w as Map<String, dynamic>)).toList();
  }

  Future<List<PriceListEntry>> fetchPriceLists() async {
    final payload = await apiClient.get('/price-lists', params: {'per_page': 200});
    final data = (payload['data'] as List?) ?? const [];
    return data.map((p) => PriceListEntry.fromJson(p as Map<String, dynamic>)).toList();
  }

  /// Scoped to [salesmanId] when given (the offer composer always knows the
  /// customer's active salesman by the time an item is being picked) — the
  /// server then only returns items authorized via that rep's category
  /// mapping (mirrors RequestComposer.js's `api.items({ salesman_id })`),
  /// so the picker never offers an item the server would reject on submit.
  /// [perPage] defaults to a small page for the search-as-you-type item
  /// picker — ReferenceCache asks for a much larger page instead, since it's
  /// after this rep's *entire* catalog, not one page of search results.
  Future<List<ItemEntry>> fetchItems({String? search, int? salesmanId, int perPage = 50}) async {
    final payload = await apiClient.get('/items', params: {
      'per_page': perPage,
      if (search != null && search.isNotEmpty) 'search': search,
      'salesman_id': ?salesmanId,
    });
    final data = (payload['data'] as List?) ?? const [];
    return data.map((i) => ItemEntry.fromJson(i as Map<String, dynamic>)).toList();
  }

  Future<List<EffectivePrice>> fetchEffectivePrices(int priceListId, {int? itemId}) async {
    final payload = await apiClient.get('/price-lists/$priceListId/effective-prices', params: {
      'item_id': ?itemId,
    });
    final data = (payload['data'] as List?) ?? const [];
    return data.map((p) => EffectivePrice.fromJson(p as Map<String, dynamic>)).toList();
  }

  /// One item's effective price on [priceListId], cached per item so this
  /// same lookup can be resolved offline without a network round trip — see
  /// CreateOfferScreen's `_refreshGuidance` and DataSyncService's
  /// `effectivePrices` step. Deliberately per-item rather than one bulk
  /// "every item on this list" call: the backend's no-`item_id` mode caps its
  /// raw row count *before* deduping to one row per item
  /// (EffectivePriceLookup::forPriceList), so a bulk pull can silently miss
  /// items whose active price row didn't happen to rank inside that cap —
  /// filtering on `item_id` up front (same as the live per-item lookup
  /// already does) sidesteps that entirely, at the cost of one request per
  /// item during sync (same trade-off `fetchWarehouseStockForItem` already
  /// makes for the same reason).
  Future<List<EffectivePrice>> fetchEffectivePriceCached(int priceListId, int itemId) {
    return CachedFetch.list(
      key: 'effective_price:$priceListId:$itemId',
      request: () async => (await apiClient.get('/price-lists/$priceListId/effective-prices', params: {
            'item_id': itemId,
          })) as Map<String, dynamic>,
      fromJson: EffectivePrice.fromJson,
    );
  }

  /// One item at a time, matching RequestComposer.js's loadLineStock — the
  /// endpoint accepts item_ids as an array, but the composer only ever
  /// needs stock for whichever single item was just picked on a line.
  Future<List<WarehouseItemStock>> fetchWarehouseStockForItem(int itemId) async {
    final payload = await apiClient.get('/warehouse-item-stocks/for-items?item_ids[]=$itemId');
    final data = (payload['data'] as List?) ?? const [];
    return data.map((s) => WarehouseItemStock.fromJson(s as Map<String, dynamic>)).toList();
  }

  // 500 rather than the old 50: with no pagination UI anywhere on this
  // screen, this single call needs to represent this rep's *entire* list so
  // both the screen and the offline cache it write-through's to have
  // everything, not just the most recent page.
  Future<List<PriceOfferRequestSummary>> listRequests({int page = 1, int perPage = 500}) {
    return CachedFetch.list(
      key: 'price_offer_requests_list',
      request: () async =>
          (await apiClient.get('/price-offer-requests', params: {'page': page, 'per_page': perPage})) as Map<String, dynamic>,
      fromJson: PriceOfferRequestSummary.fromJson,
    );
  }

  Future<PriceOfferRequestDetail> getRequest(int id) {
    return CachedFetch.detail(
      key: 'price_offer_request_detail:$id',
      request: () async => (await apiClient.get('/price-offer-requests/$id')) as Map<String, dynamic>,
      fromPayload: PriceOfferRequestDetail.fromEnvelope,
    );
  }

  Future<int> createRequest({
    required int customerId,
    required int salesmanId,
    required int priceListId,
    required List<OfferLineInput> lines,
  }) async {
    final payload = await apiClient.post('/price-offer-requests', prefix: 'request-create', body: {
      'customer_id': customerId,
      'salesman_id': salesmanId,
      'price_list_id': priceListId,
      'lines': lines.map((l) => l.toJson()).toList(),
    });
    return asInt((payload['data'] as Map<String, dynamic>)['id']);
  }

  Future<void> submitRequest(int id) async {
    await apiClient.post('/price-offer-requests/$id/submit', prefix: 'request-submit');
  }

  Future<void> addLine(int requestId, OfferLineInput line) async {
    await apiClient.post('/price-offer-requests/$requestId/lines', prefix: 'line-create', body: line.toJson());
  }

  Future<void> updateLine(
    int requestId,
    int lineId, {
    num? quantity,
    num? proposedPrice,
    String? reason,
  }) async {
    await apiClient.patch('/price-offer-requests/$requestId/lines/$lineId', prefix: 'line-update', body: {
      'quantity': ?quantity,
      'proposed_price': ?proposedPrice,
      if (reason != null && reason.isNotEmpty) 'reason': reason,
    });
  }

  Future<void> removeLine(int requestId, int lineId) async {
    await apiClient.delete('/price-offer-requests/$requestId/lines/$lineId', prefix: 'line-remove');
  }

  Future<void> approveRequest(int id, {String? comments}) async {
    await apiClient.post('/price-offer-requests/$id/approve', prefix: 'request-approve', body: {
      if (comments != null && comments.isNotEmpty) 'comments': comments,
    });
  }

  Future<void> rejectRequest(int id, {String? rejectionReason}) async {
    await apiClient.post('/price-offer-requests/$id/reject', prefix: 'request-reject', body: {
      if (rejectionReason != null && rejectionReason.isNotEmpty) 'rejection_reason': rejectionReason,
    });
  }

  Future<void> returnRequest(int id, {String? comments}) async {
    await apiClient.post('/price-offer-requests/$id/return', prefix: 'request-return', body: {
      if (comments != null && comments.isNotEmpty) 'comments': comments,
    });
  }

  Future<void> skipRequest(int id, {String? comments}) async {
    await apiClient.post('/price-offer-requests/$id/skip', prefix: 'request-skip', body: {
      if (comments != null && comments.isNotEmpty) 'comments': comments,
    });
  }

  Future<void> generateQuotation(int requestId) async {
    await apiClient.post('/price-offer-requests/$requestId/quotation', prefix: 'quotation-generate');
  }

  Future<void> sendQuotation(int quotationId) async {
    await apiClient.post('/quotations/$quotationId/send', prefix: 'quotation-send');
  }

  Future<Uint8List> quotationPdfBytes(int quotationId) {
    return apiClient.getBytes('/quotations/$quotationId/download');
  }

  /// Declines a chosen quantity on one or more still-open lines — gated
  /// server-side by QuotationSetting.line_decline_enabled, and only allowed
  /// while the quotation is ACCEPTED/PARTIALLY_CONVERTED (same statuses a
  /// release requires). There is no dedicated "cancel quotation" endpoint;
  /// declining every open line at its full remaining quantity is the
  /// closest equivalent available.
  Future<void> declineLines(int quotationId, List<QuotationLineDecline> lines) async {
    await apiClient.post('/quotations/$quotationId/decline-lines', prefix: 'quotation-decline', body: {
      'lines': lines.map((l) => l.toJson()).toList(),
    });
  }

  /// Whether the quotation-settings admin has enabled partial release —
  /// public/read-only, any authenticated user can check it (mirrors
  /// QuotationsView.js's `loadQuotationSettings`). Decides whether the
  /// release UI lets the quantity be edited per line or must release each
  /// releasable line at its full remaining quantity.
  Future<bool> fetchPartialReleaseEnabled() async {
    final payload = await apiClient.get('/quotation-settings');
    final data = (payload['data'] as Map?) ?? const {};
    return data['partial_release_enabled'] == true;
  }

  /// Records what the customer told the rep by phone/in person — posts
  /// through the same token-verified public endpoint the customer's own
  /// web confirmation link submits to (QuotationController::respond()).
  /// [token] is the quotation's confirmation_token, only present on a
  /// quotation fetched while authenticated (see Quotation.confirmationToken).
  Future<void> recordQuotationResponse(
    int quotationId, {
    required String token,
    required String response,
    String? customerName,
    String? comments,
  }) async {
    await apiClient.post('/quotations/$quotationId/respond', prefix: 'quotation-respond', body: {
      'token': token,
      'response': response,
      if (customerName != null && customerName.isNotEmpty) 'customer_name': customerName,
      if (comments != null && comments.isNotEmpty) 'comments': comments,
    });
  }

  /// Releases some or all of a quotation's still-open lines into a new (or
  /// existing, if already partially converted) sales order — see
  /// SalesOrderService::create(). [lines] must be non-empty.
  Future<void> createOrder(int quotationId, {required List<OrderReleaseLine> lines}) async {
    await apiClient.post('/quotations/$quotationId/order', prefix: 'order-create', body: {
      'lines': lines.map((l) => l.toJson()).toList(),
    });
  }
}
