import '../core/api_client.dart';
import '../models/sales_order.dart';

class SalesOrdersService {
  final ApiClient apiClient;

  SalesOrdersService(this.apiClient);

  Future<List<SalesOrder>> listOrders({int page = 1}) async {
    final payload = await apiClient.get('/sales-orders', params: {'page': page, 'per_page': 50});
    final data = (payload['data'] as List?) ?? const [];
    return data.map((o) => SalesOrder.fromJson(o as Map<String, dynamic>)).toList();
  }

  Future<SalesOrder> getOrder(int id) async {
    final payload = await apiClient.get('/sales-orders/$id');
    return SalesOrder.fromJson((payload as Map<String, dynamic>)['data'] as Map<String, dynamic>);
  }

  Future<void> releaseHold(int orderId, {String? reason}) async {
    await apiClient.post('/sales-orders/$orderId/release-hold', prefix: 'order-release', body: {
      if (reason != null && reason.isNotEmpty) 'reason': reason,
    });
  }
}
