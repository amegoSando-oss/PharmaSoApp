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

class OfferLineInput {
  final int itemId;
  final num quantity;
  final num proposedPrice;
  final num? focQuantity;
  final String? focUom;

  OfferLineInput({
    required this.itemId,
    required this.quantity,
    required this.proposedPrice,
    this.focQuantity,
    this.focUom,
  });

  Map<String, dynamic> toJson() => {
        'item_id': itemId,
        'quantity': quantity,
        'proposed_price': proposedPrice,
        if (focQuantity != null && focQuantity! > 0) 'foc_quantity': focQuantity,
        if (focUom != null && focUom!.isNotEmpty) 'foc_uom': focUom,
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

  Future<List<ItemEntry>> fetchItems({String? search}) async {
    final payload = await apiClient.get('/items', params: {
      'per_page': 50,
      if (search != null && search.isNotEmpty) 'search': search,
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

  /// One item at a time, matching RequestComposer.js's loadLineStock — the
  /// endpoint accepts item_ids as an array, but the composer only ever
  /// needs stock for whichever single item was just picked on a line.
  Future<List<WarehouseItemStock>> fetchWarehouseStockForItem(int itemId) async {
    final payload = await apiClient.get('/warehouse-item-stocks/for-items?item_ids[]=$itemId');
    final data = (payload['data'] as List?) ?? const [];
    return data.map((s) => WarehouseItemStock.fromJson(s as Map<String, dynamic>)).toList();
  }

  Future<List<PriceOfferRequestSummary>> listRequests({int page = 1}) async {
    final payload = await apiClient.get('/price-offer-requests', params: {'page': page, 'per_page': 50});
    final data = (payload['data'] as List?) ?? const [];
    return data.map((r) => PriceOfferRequestSummary.fromJson(r as Map<String, dynamic>)).toList();
  }

  Future<PriceOfferRequestDetail> getRequest(int id) async {
    final payload = await apiClient.get('/price-offer-requests/$id');
    return PriceOfferRequestDetail.fromEnvelope(payload as Map<String, dynamic>);
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

  Future<void> createOrder(int quotationId, {required int warehouseId}) async {
    await apiClient.post('/quotations/$quotationId/order', prefix: 'order-create', body: {
      'warehouse_id': warehouseId,
    });
  }
}
