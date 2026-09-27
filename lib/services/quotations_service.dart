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

  /// There's no single-quotation GET endpoint (see Quotation's own doc
  /// comment) — searching by its own number is the only way to fetch one
  /// quotation with its full line detail from a screen that only holds a
  /// [QuotationSummary].
  Future<Quotation?> findByNumber(String quotationNumber) async {
    final payload = await apiClient.get('/quotations', params: {'search': quotationNumber, 'per_page': 5});
    final data = (payload['data'] as List?) ?? const [];
    for (final row in data) {
      final quotation = Quotation.fromJson(row as Map<String, dynamic>);
      if (quotation.quotationNumber == quotationNumber) return quotation;
    }
    return null;
  }
}
