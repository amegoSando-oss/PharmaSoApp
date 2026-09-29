import '../core/api_client.dart';
import '../models/sales_order.dart';
import 'cached_fetch.dart';

class SalesOrdersService {
  final ApiClient apiClient;

  SalesOrdersService(this.apiClient);

  // 500 rather than the old 50: no pagination UI exists for this list, so
  // this single call needs to represent this rep's entire order history for
  // both the screen and the offline cache it write-throughs to. Not cached
  // when scoped to a single quotation (quotationId != null) — that's a
  // narrower, on-demand lookup, not "this rep's whole list".
  Future<List<SalesOrder>> listOrders({int page = 1, int perPage = 500, int? quotationId}) async {
    final params = {
      'page': page,
      'per_page': perPage,
      if (quotationId != null) 'quotation_id': quotationId,
    };
    if (quotationId != null) {
      final payload = await apiClient.get('/sales-orders', params: params);
      final data = ((payload as Map<String, dynamic>)['data'] as List?) ?? const [];
      return data.map((o) => SalesOrder.fromJson(o as Map<String, dynamic>)).toList();
    }
    return CachedFetch.list(
      key: 'sales_orders_list',
      request: () async => (await apiClient.get('/sales-orders', params: params)) as Map<String, dynamic>,
      fromJson: SalesOrder.fromJson,
    );
  }

  Future<SalesOrder> getOrder(int id) {
    return CachedFetch.detail(
      key: 'sales_order_detail:$id',
      request: () async => (await apiClient.get('/sales-orders/$id')) as Map<String, dynamic>,
      fromPayload: (payload) => SalesOrder.fromJson(payload['data'] as Map<String, dynamic>),
    );
  }

  Future<void> releaseHold(int orderId, {String? reason}) async {
    await apiClient.post('/sales-orders/$orderId/release-hold', prefix: 'order-release', body: {
      if (reason != null && reason.isNotEmpty) 'reason': reason,
    });
  }
}
