import '../core/api_client.dart';
import '../models/quotation.dart';

class QuotationsService {
  final ApiClient apiClient;

  QuotationsService(this.apiClient);

  Future<List<Quotation>> listQuotations({int page = 1}) async {
    final payload = await apiClient.get('/quotations', params: {'page': page, 'per_page': 50});
    final data = (payload['data'] as List?) ?? const [];
    return data.map((q) => Quotation.fromJson(q as Map<String, dynamic>)).toList();
  }
}
