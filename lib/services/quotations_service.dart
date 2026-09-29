import '../core/api_client.dart';
import '../models/quotation.dart';
import 'cached_fetch.dart';

class QuotationsService {
  final ApiClient apiClient;

  QuotationsService(this.apiClient);

  // 500 rather than the old 50: no pagination UI exists for this list, so
  // this single call needs to represent this rep's entire quotation history
  // for both the screen and the offline cache it write-throughs to.
  Future<List<Quotation>> listQuotations({int page = 1, int perPage = 500}) {
    return CachedFetch.list(
      key: 'quotations_list',
      request: () async => (await apiClient.get('/quotations', params: {'page': page, 'per_page': perPage})) as Map<String, dynamic>,
      fromJson: Quotation.fromJson,
    );
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
